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

import Request "../Request";
import Response "../Response";
import UrlEncodedValues "../UrlEncodedValues";

import RB "../ResponseBuilder";
import T "../Types";

module {
    type TrieSet<K> = TrieSet.Set<K>;
    type Buffer<V> = Buffer.Buffer<V>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<Ok, Err> = Result.Result<Ok, Err>;
    public type Request = Request.Request;
    public type Response = Response.Response;

    public type ResponseBuilder = RB.ResponseBuilder;
    public type HttpRequest = T.HttpRequest;
    public type HttpResponse = T.HttpResponse;

    public type RouterResult = Result.Result<(), HttpResponse>;
    public type AsyncRouterHandler = (Request, ResponseBuilder) -> async* ();
    public type SyncRouterHandler = (Request, ResponseBuilder) -> ();

    public type SharedMessage = T.SharedMessage;

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
        handler : TrieMap<Text, RouterHandler>;
        path_params : TrieMap<Text, Text>;
    };

    func new_route() : RouteMap = {
        nested_routes = TrieMap.TrieMap(Text.equal, Text.hash);
        handler = TrieMap.TrieMap(Text.equal, Text.hash);
        path_params = TrieMap.TrieMap(Text.equal, Text.hash);
    };

    public class Router() = self {
        public let routes : RouteMap = new_route();
        var has_async_route = false;
        let errorLog : Buffer<RouterError> = Buffer.Buffer(8);

        // LET middleware = triemap

        func add_handler(methods : [Text], endpoint : Text, handler : RouterHandler) {
            if (Text.contains(endpoint, #text "//")) {
                // todo: use parser combinators to handle the other
                // cases of invalid endpoints

                Debug.trap("Endpoint cannot have empty path segments");
            };

            let route = create_route(endpoint, methods);
            populate_route(route, methods, handler);
        };

        func populate_route(
            route : RouteMap,
            methods : [Text],
            handler : RouterHandler,
        ) {
            for (method in methods.vals()) {
                if (Option.isSome(route.handler.get(method))) {
                    Debug.trap("Duplicate route: " # method # " "/* # endpoint */);
                };

                switch (handler) {
                    case (#Async(_)) has_async_route := true;
                    case (_) {};
                };

                route.handler.put(method, handler);
            };
        };

        // Creates a route map from the given path and returns the route details.
        // If the path exists, it will return the details of the existing route.
        func create_route(path: Text, methods: [Text]): RouteMap {

            func create_route_helper(
                route : RouteMap,
                paths : Iter.Iter<Text>,
                methods: [Text],
                params_set : TrieSet<Text>,
            ) : RouteMap {
                
                let ?pathname = paths.next() else return route;

                if (pathname == "") {
                    Debug.trap("Empty pathname");
                } else if (pathname.size() == 1 and pathname == ":") {
                    Debug.trap("Path cannot be a single colon");
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
                        next_route.path_params.put(method, pathname);
                    };

                    route.nested_routes.put(PATH_PARAMS_ID, next_route);
                    end_route

                } else {
                    let next_route = Option.get(route.nested_routes.get(pathname), new_route());
                    let end_route = create_route_helper(next_route, paths, methods, set);
                    route.nested_routes.put(pathname, next_route);
                    end_route
                };
            };

            let paths = Text.tokens(path, #char '/');
            let set = TrieSet.empty<Text>();

            create_route_helper(self.routes, paths, methods, set);
            
        };

        type RouteDetails = {
            route : RouteMap;
            params : TrieMap<Text, Text>;
        };

        func get_route_details(endpoint : Text, method : ?Text) : ?RouteDetails {
            let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

            let paths = Text.tokens(endpoint, #char '/');

            func get_route_from_path(route : RouteMap, paths : Iter.Iter<Text>, method : ?Text) : ?RouteMap {
                let path = switch (paths.next()) {
                    case (?path) path;
                    case (null) return ?route;
                };

                Debug.print("looking for route [ " # endpoint # " ]: " # path);

                for (route in route.nested_routes.keys()) {
                    Debug.print("checking route: " # route);
                };

                ignore do ? {
                    let next_route = route.nested_routes.get(path)!;
                    return get_route_from_path(next_route, paths, method);
                };

                let ?next_route = route.nested_routes.get(":") else return null;

                ignore do ? {
                    let path_param = next_route.path_params.get(method!)!;
                    Debug.print("found path param: " # path_param);

                    params.put(
                        Mo.Text.subText(path_param, 1, path_param.size()),
                        path,
                    );
                };

                return get_route_from_path(next_route, paths, method);
            };

            switch (get_route_from_path(routes, paths, method)) {
                case (?route)(?{ route; params });
                case (_) null;
            };
        };

        // Merges the routes of another router into this one
        // Similar to express's router.use()
        public func mount(endpoint : Text, other : Router) {
            var absolute_path = endpoint;

            func mount_helper(route : RouteMap, other : RouteMap) {

                for ((method, handler) in other.handler.entries()) {
                    let prev = route.handler.replace(method, handler);

                    if (Option.isSome(prev)){
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

        func get_handler_details(http_req : T.HttpRequest) : ?(Request, RouterHandler) {
            let req = Request.fromHttpRequest(http_req);
            let { url } = req;

            let ?{ route; params } = get_route_details(http_req.url, ?http_req.method) else return null;

            for ((key, value) in params.entries()) {
                req.params.put(key, value);
            };

            let ?handler = route.handler.get(http_req.method) else return null;

            ?(req, handler);
        };

        func not_found() : T.HttpResponse {
            let res = RB.ResponseBuilder();
            res.status_code := Status.NotFound;
            return RB.toHttpResponse(res);
        };

        func handle_sync_request(http_req : T.HttpRequest) : T.HttpResponse {
            let ?(req, handler) = get_handler_details(http_req) else return not_found();

            let res = RB.ResponseBuilder();

            switch (handler) {
                case (#Async(_)) Debug.trap("Async handler called in sync context");
                case (#Sync(handler)) handler(req, res);
            };

            RB.toHttpResponse(res);
        };

        func handle_async_request(http_req : T.HttpRequest) : async* T.HttpResponse {
            let ?(req, handler) = get_handler_details(http_req) else return not_found();

            let res = RB.ResponseBuilder();

            switch (handler) {
                case (#Async(handler)) await* handler(req, res);
                case (#Sync(handler)) handler(req, res);
            };

            RB.toHttpResponse(res);
        };

        public func process_request(http_req : T.HttpRequest, message : SharedMessage) : T.HttpResponse {
            if (
                http_req.method == Method.Get
            ) {
                handle_sync_request(http_req);
            } else {
                Debug.print("re-routing async request: " # http_req.method # ", " # http_req.url);
                let res = RB.ResponseBuilder();
                res.update := true;
                RB.toHttpResponse(res);
            };
        };

        public func process_update_request(http_req : T.HttpRequest, message : SharedMessage) : T.HttpResponse {
            if (has_async_route) Debug.trap("Router has async routes, but called sync handler (process_update_request()). \nTry using process_async_update_request() instead.");
            handle_sync_request(http_req);
        };

        // Could be used for inter-canister query calls
        public func process_async_request(http_req : T.HttpRequest, message : SharedMessage) : async* T.HttpResponse {
            if (
                http_req.method == Method.Get
            ) {
                await* handle_async_request(http_req);
            } else {
                Debug.print("re-routing async request: " # http_req.method # ", " # http_req.url);
                let res = RB.ResponseBuilder();
                res.update := true;
                RB.toHttpResponse(res);
            };
        };

        public func process_async_update_request(http_req : T.HttpRequest, message : SharedMessage) : async* T.HttpResponse {
            await* handle_async_request(http_req);
        };

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

        // Functions for setting up async update route handlers

        public func post_async(endpoint : Text, callback : AsyncRouterHandler) {
            add_handler([Method.Post], endpoint, #Async(callback));
        };

        public func delete_async(endpoint : Text, callback : AsyncRouterHandler) {
            add_handler([Method.Delete], endpoint, #Async(callback));
        };

        public func patch_async(endpoint : Text, callback : AsyncRouterHandler) {
            add_handler([Method.Patch], endpoint, #Async(callback));
        };

        public func put_async(endpoint : Text, callback : AsyncRouterHandler) {
            add_handler([Method.Put], endpoint, #Async(callback));
        };

    };
};
