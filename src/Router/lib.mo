import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";

import Mo "mo:moh";

import Request "../Request";
import RB "ResponseBuilder";
import T "Types";

module {
    type TrieSet<K> = TrieSet.Set<K>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Result<Ok, Err> = Result.Result<Ok, Err>;
    public type Request = Request.Request;

    public type ResponseBuilder = RB.ResponseBuilder;
    public type HttpResponse = T.HttpResponse;

    let ResponseBuilder = RB.ResponseBuilder;
    public type AsyncCallbackFn = (Request, ResponseBuilder) -> async T.HttpResponse;

    type RouteMap = {
        nested_routes : TrieMap<Text, RouteMap>;
        handler : TrieMap<Text, AsyncCallbackFn>;
        var query_param : ?Text;
    };

    public class Router() {
        func newRoute() : RouteMap = {
            nested_routes = TrieMap.TrieMap(Text.equal, Text.hash);
            handler = TrieMap.TrieMap(Text.equal, Text.hash);
            var query_param = null;
        };

        let routes : RouteMap = newRoute();

        // LET middleware = triemap

        func addRoute(methods : [Text], endpoint : Text, callback : AsyncCallbackFn) {
            if (Text.contains(endpoint, #text "//")) {
                // todo: use parser combinators to handle the other
                // cases of invalid endpoints

                Debug.trap("Endpoint cannot have empty path segments");
            };

            let paths = Text.tokens(endpoint, #char '/');
            let set = TrieSet.empty<Text>();
            insertRoute(routes, methods, endpoint, paths, set, callback);
        };

        func insertRoute(
            route : RouteMap,
            methods : [Text],
            endpoint : Text,
            paths : Iter.Iter<Text>,
            queryParamsSet : TrieSet<Text>,
            callback : AsyncCallbackFn,
        ) {
            let path = switch (paths.next()) {
                case (?path) path;
                case (null) {
                    for (method in methods.vals()) {
                        switch (route.handler.get(method)) {
                            case (?_) Debug.trap(
                                "Duplicate route: " # method # " " # endpoint,
                            );
                            case (_) route.handler.put(method, callback);
                        };
                    };

                    return;
                };
            };

            if (path == "") {
                Debug.trap("Empty path");
            } else if (path.size() == 1 and path == ":") {
                Debug.trap("Path cannot be a single colon");
            };

            var set = queryParamsSet;

            if (Text.startsWith(path, #text ":")) {
                switch (route.query_param) {
                    case (?_) Debug.trap(
                        "Cannot have multiple query parameters defined for the same route ",
                    );
                    case (_) route.query_param := ?path;
                };

                set := TrieSet.put(queryParamsSet, path, Text.hash(path), Text.equal);

                if (set == queryParamsSet) {
                    Debug.trap("Duplicate query parameter: " # path);
                };
            };

            let next_route = Option.get(
                route.nested_routes.get(path),
                newRoute(),
            );

            insertRoute(next_route, methods, endpoint, paths, set, callback);
            route.nested_routes.put(path, next_route);
        };

        type RouteDetails = {
            route : RouteMap;
            params : TrieMap<Text, Text>;
        };

        func getRoute(endpoint : Text) : ?RouteDetails {
            let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

            let paths = Text.tokens(endpoint, #char '/');

            func getRouteFromPath(route : RouteMap, paths : Iter.Iter<Text>) : ?RouteMap {
                let path = switch (paths.next()) {
                    case (?path) path;
                    case (null) return ?route;
                };

                Debug.print("looking for route [ " # endpoint # " ]: " # path);

                switch (route.nested_routes.get(path)) {
                    case (?next_route) {
                        return getRouteFromPath(next_route, paths);
                    };
                    case (_) {};
                };

                let qp = switch (route.query_param) {
                    case (?query_param) {
                        params.put(
                            // strip the leading colon
                            Mo.Text.subText(query_param, 1, query_param.size()),
                            path,
                        );

                        query_param;
                    };
                    case (_) return null;
                };

                switch (route.nested_routes.get(qp)) {
                    case (?next_route) {
                        return getRouteFromPath(next_route, paths);
                    };
                    case (_) {};
                };

                return null;
            };

            switch (getRouteFromPath(routes, paths)) {
                case (?route) {
                    ?{
                        route = route;
                        params = params;
                    };
                };
                case (_) null;
            };
        };

        // // Merges the routes of another router into this one
        // public func merge(endpoint : Text, router : Router) {
        //     if (router.handler.size() == 0 and router.nested_routes.size() == 0) {
        //         return;
        //     };

        //     let route = getRoute(endpoint);

        //     for ((path, route) in router.nested_routes) {
        //         route.nested_routes.put(path, route);
        //     };

        //     for ((method, handler) in router.handler) {
        //         route.handler.put(method, handler);
        //     };
        // };

        func _processRequest(httpReq : T.HttpRequest) : async T.HttpResponse {
            let req = Request.fromHttpRequest(httpReq);
            let { url } = req;

            let optRoute = getRoute(url);
            let notFoundResponse = ResponseBuilder().status(404 : Nat16).build();

            let { route; params } = switch (optRoute) {
                case (?result) result;
                case (null) notFoundResponse;
            };

            for ((key, value) in params.entries()) {
                req.params.put(key, value);
            };

            switch (route.handler.get(httpReq.method)) {
                case (?handler) await handler(req, ResponseBuilder());
                case (_) notFoundResponse;
            };
        };

        public func processRequest(httpReq : T.HttpRequest) : async T.HttpResponse {
            if (httpReq.method == "GET") {
                await _processRequest(httpReq);
            } else {
                ResponseBuilder().update(true).build();
            };
        };

        public func processUpdateRequest(httpReq : T.HttpRequest) : async T.HttpResponse {
            await _processRequest(httpReq);
        };

        public func get(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(["GET"], endpoint, callback);
        };

        public func put(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(["PUT"], endpoint, callback);
        };

        public func delete(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(["DELETE"], endpoint, callback);
        };

        public func post(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(["POST"], endpoint, callback);
        };

        public func patch(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(["PATCH"], endpoint, callback);
        };

        public func all(endpoint : Text, callback : AsyncCallbackFn) {
            addRoute(
                ["GET", "PUT", "DELETE", "POST", "PATCH"],
                endpoint,
                callback,
            );
        };
    };
};
