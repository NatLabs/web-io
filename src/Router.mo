import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";

import Mo "mo:moh";
import { Method; Status } "mo:http/Http";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";

import Request "Request";
import Response "Response";

import RB "ResponseBuilder";
import T "Types";

module {
    type TrieSet<K> = TrieSet.Set<K>;
    type Buffer<V> = Buffer.Buffer<V>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<Ok, Err> = Result.Result<Ok, Err>;
    type PeekableIter<A> = PeekableIter.PeekableIter<A>;

    public type Request = Request.Request;
    public type Response = Response.Response;
    public type Candid = T.Candid;

    public type ResponseBuilder = RB.ResponseBuilder;
    public type HttpRequest = T.HttpRequest;
    public type HttpResponse = T.HttpResponse;

    public type RouterResult = Result.Result<(), HttpResponse>;
    public type AsyncRouterHandler = (Request, ResponseBuilder) -> async* ();
    public type SyncRouterHandler = (Request, ResponseBuilder) -> ();

    public type SharedMessage = T.SharedMessage;

    public type StreamingCallback = T.StreamingCallback;
    public type StreamingToken = T.StreamingToken;
    public type StreamingResponse = T.StreamingResponse;

    type RouterHandler = {
        #Async : AsyncRouterHandler;
        #Sync : SyncRouterHandler;
    };

    public let PATH_PARAMS_ID = ":";
    public let FALLBACK_ID = "*";

    public type RouterError = {
        #RouteNotFound : HttpRequest;
    };

    type RouteMap = {
        nested_routes : TrieMap<Text, RouteMap>;
        handlers : TrieMap<Text, RouterHandler>;
        params : TrieMap<Text, Text>;
    };

    func new_route() : RouteMap = {
        nested_routes = TrieMap.TrieMap(Text.equal, Text.hash);
        handlers = TrieMap.TrieMap(Text.equal, Text.hash);
        params = TrieMap.TrieMap(Text.equal, Text.hash);
    };

    public class Router() = self {
        public let routes : RouteMap = new_route();
        var has_async_route = false;
        let errorLog : Buffer<RouterError> = Buffer.Buffer(8);
        var error_handler : ?SyncRouterHandler = null;
        // LET middleware = triemap

        func format_path(path : Text) : Text {
            if (Text.contains(path, #text "//")) {
                // todo: use parser combinators to handle the other
                // cases of invalid endpoints

                Debug.trap("Endpoint cannot have empty path segments");
            };

            // The root route is under the 'root' key
            // So every route is prefixed with 'root/'
            // The fallback route for the root is at the same level as the root
            if (path == FALLBACK_ID) { path } else {
                "root/" # Text.trim(path, #char '/')
            };
        };

        func add_handler(methods : [Text], endpoint : Text, handler : RouterHandler) {
            let route = create_route(format_path(endpoint), methods);
            populate_route(route, methods, handler);
        };

        func populate_route(
            route : RouteMap,
            methods : [Text],
            handler : RouterHandler,
        ) {
            for (method in methods.vals()) {
                if (Option.isSome(route.handlers.get(method))) {
                    Debug.trap("Duplicate route: " # method # " " /* # endpoint */);
                };

                switch (handler) {
                    case (#Async(_)) has_async_route := true;
                    case (_) {};
                };

                route.handlers.put(method, handler);
            };
        };

        // Creates a route map from the given path and returns the route details.
        // If the path exists, it will return the details of the existing route.
        func create_route(path : Text, methods : [Text]) : RouteMap {

            func create_route_helper(
                route : RouteMap,
                paths : PeekableIter<Text>,
                methods : [Text],
                params_set : TrieSet<Text>,
            ) : RouteMap {

                let ?pathname = paths.next() else return route;

                if (pathname == "") {
                    Debug.trap("Empty pathname");
                } else if (pathname.size() == 1 and pathname == ":") {
                    Debug.trap("Path cannot be a single colon");
                } else if (pathname.size() > 1 and pathname == "*") {
                    Debug.trap("The wildcard path should only be a single asterisk");
                } else if (pathname == "*" and paths.peek() != null){
                    Debug.trap("The wildcard path should be the last path");
                };

                var set = params_set;

                if (Text.startsWith(pathname, #text ":")) {
                    set := TrieSet.put(params_set, pathname, Text.hash(pathname), Text.equal);

                    if (set == params_set) {
                        Debug.trap("Duplicate query parameter: " # pathname);
                    };

                    let next_route = Option.get(route.nested_routes.get(PATH_PARAMS_ID), new_route());

                    let end_route = create_route_helper(next_route, paths, methods, set);

                    if (methods.size() == 0) Debug.trap("Error: Query paramters can only be used if a method is specified");

                    for (method in methods.vals()) {
                        next_route.params.put(method, pathname);
                    };

                    route.nested_routes.put(PATH_PARAMS_ID, next_route);
                    end_route

                } else {
                    let next_route = Option.get(route.nested_routes.get(pathname), new_route());
                    let end_route = create_route_helper(next_route, paths, methods, set);
                    route.nested_routes.put(pathname, next_route);
                    end_route;
                };
            };

            let paths = Itertools.peekable(Text.tokens(path, #char '/'));
            let set = TrieSet.empty<Text>();

            create_route_helper(self.routes, paths, methods, set);

        };

        type RouteDetails = {
            route : RouteMap;
            params : TrieMap<Text, Text>;
        };

        func get_route_details(endpoint : Text, method : ?Text) : ?RouteDetails {
            let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

            let paths = Text.tokens(format_path(endpoint), #char '/');

            func get_route_from_path(
                route : RouteMap, 
                paths : Iter.Iter<Text>, 
                method : ?Text,
                fallback_route: ?RouteMap,
            ) : ?RouteMap {
                let path = switch (paths.next()) {
                    case (?path) path;
                    case (null) return ?route;
                };

                let fallback = switch (route.nested_routes.get(FALLBACK_ID)) {
                    case (?route) ?route;
                    case (_) fallback_route;
                };

                ignore do ? {
                    let next_route = route.nested_routes.get(path)!;
                    return get_route_from_path(next_route, paths, method, fallback);
                };

                let ?next_route = route.nested_routes.get(":") else return fallback;

                ignore do ? {
                    let path_param = next_route.params.get(method!)!;

                    params.put(
                        Mo.Text.subText(path_param, 1, path_param.size()),
                        path,
                    );
                };

                switch(get_route_from_path(next_route, paths, method, fallback)){
                    case (?route) ?route;
                    case (_) fallback;
                };
            };

            
            switch (get_route_from_path(routes, paths, method, null)) {
                case (?route)(?{ route; params });
                case (_) { null }; 
            };
        };

        /// Merges the routes of another router into this one
        /// Similar to express's router.use()
        public func mount(endpoint : Text, other : Router) {
            var absolute_path = endpoint;

            func mount_helper(route : RouteMap, other : RouteMap) {

                for ((method, handler) in other.handlers.entries()) {
                    let prev = route.handlers.replace(method, handler);

                    if (Option.isSome(prev)) {
                        Debug.trap("Cannot mount router at endpoint '" # absolute_path # "'' because it already has a handler for " # method);
                    };
                };

                for ((path, route) in other.nested_routes.entries()) {
                    absolute_path #= "/" # path;
                    let next_route = Option.get(route.nested_routes.get(path), new_route());
                    mount_helper(next_route, route);
                };
            };

            let route = create_route(endpoint, []);
            mount_helper(route, other.routes);
        };

        type HandlerDetails = {
            params : TrieMap.TrieMap<Text, Text>;
            handler : RouterHandler;
        };

        func get_handler_details(req : Request) : ?HandlerDetails {
            let { url } = req;

            let ?{ route; params } = get_route_details(url.path, ?req.method) else return null;

            let ?handler = route.handlers.get(req.method) else return null;

            ?{params; handler};
        };

        /// Handler for when a request is not found
        public func error(handler : SyncRouterHandler) {
            error_handler := ?handler;
        };

        func not_found(req : Request) : T.HttpResponse {
            let res = RB.ResponseBuilder()
                .status(Status.NotFound);

            switch (error_handler) {
                case (?handler) {
                    handler(req, res);
                    res.build_http();
                };
                case (null) {
                    res.build_http();
                };
            };
        };

        func handle_sync_request(http_req : T.HttpRequest) : T.HttpResponse {
            let req = Request.fromHttpRequest(http_req);
            let ?{handler; params} = get_handler_details(req) else return not_found(req);

            for ((key, value) in params.entries()) {
                req.params.put(key, value);
            };

            let res = RB.ResponseBuilder();
            switch (handler) {
                case (#Async(_)) Debug.trap("Async handler called in sync context");
                case (#Sync(handler)) handler(req, res);
            };

            res.build_http();
        };

        // func handle_async_request(http_req : T.HttpRequest) : async* T.HttpResponse {
        //     let req = Request.fromHttpRequest(http_req);
        //     let ?{handler; params} = get_handler_details(req) else return not_found(req);

        //     for ((key, value) in params.entries()) {
        //         req.params.put(key, value);
        //     };

        //     let res = RB.ResponseBuilder();

        //     switch (handler) {
        //         case (#Async(handler)) await* handler(req, res);
        //         case (#Sync(handler)) handler(req, res);
        //     };

        //     res.build_http();
        // };

        /// Processes a request for the `http_request` function
        public func process_request(http_req : T.HttpRequest, message : ?SharedMessage) : T.HttpResponse {
            if (
                http_req.method == Method.Get or http_req.method == Method.Head,
            ) {
                handle_sync_request(http_req);
            } else {
                // Debug.print("re-routing async request: " # http_req.method # ", " # http_req.url);
                RB.ResponseBuilder()
                    .status(Status.NoContent)
                    .upgrade(true)
                    .build_http();
            };
        };

        /// Processes a request for the `http_request_update` function
        public func process_request_update(http_req : T.HttpRequest, message : ?SharedMessage) : T.HttpResponse {
            if (has_async_route) Debug.trap("Router has async routes, but called sync handler (process_request_update()). \nTry using process_async_update_request() instead.");
            handle_sync_request(http_req);
        };

        // Could be used for inter-canister query calls

        // public func process_async_request(http_req : T.HttpRequest, message : ?SharedMessage) : async* T.HttpResponse {
        //     if (
        //         http_req.method == Method.Get or http_req.method == Method.Head,
        //     ) {
        //         await* handle_async_request(http_req);
        //     } else {
        //         Debug.print("re-routing async request: " # http_req.method # ", " # http_req.url);
        //         RB.ResponseBuilder()
        //             .status(Status.NoContent)
        //             .upgrade(true)
        //             .build_http();
        //     };
        // };

        // public func process_async_update_request(http_req : T.HttpRequest, message : ?SharedMessage) : async* T.HttpResponse {
        //     await* handle_async_request(http_req);
        // };

        public func get(endpoint : Text, callback : SyncRouterHandler) {
            add_handler([Method.Get], endpoint, #Sync(callback));
        };

        public func put(endpoint : Text, callback : SyncRouterHandler) {
            add_handler([Method.Put], endpoint, #Sync(callback));
        };

        public func delete(endpoint : Text, callback : SyncRouterHandler) {
            add_handler([Method.Delete], endpoint, #Sync(callback));
        };

        public func post(endpoint : Text, callback : SyncRouterHandler) {
            add_handler([Method.Post], endpoint, #Sync(callback));
        };

        public func patch(endpoint : Text, callback : SyncRouterHandler) {
            add_handler([Method.Patch], endpoint, #Sync(callback));
        };

        // Functions for setting up async upgrade route handlers

        // public func post_async(endpoint : Text, callback : AsyncRouterHandler) {
        //     add_handler([Method.Post], endpoint, #Async(callback));
        // };

        // public func delete_async(endpoint : Text, callback : AsyncRouterHandler) {
        //     add_handler([Method.Delete], endpoint, #Async(callback));
        // };

        // public func patch_async(endpoint : Text, callback : AsyncRouterHandler) {
        //     add_handler([Method.Patch], endpoint, #Async(callback));
        // };

        // public func put_async(endpoint : Text, callback : AsyncRouterHandler) {
        //     add_handler([Method.Put], endpoint, #Async(callback));
        // };

    };
};
