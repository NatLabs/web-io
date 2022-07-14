import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

import Request "../Request";
import Response "../Response";
import ResponseBuilder "../Router/ResponseBuilder";

import T "Types";

module {
    public type Request = Request.Request;
    public type Response = Response.Response;

    let ic : T.IC = actor ("aaaaa-aa");

    public func fetch(req : Request, max_response_bytes : ?Nat64) : async Response {
        let KB = 1024;

        let args : CanisterHttpRequest = {
            url = req.url;
            max_response_bytes = switch (max_response_bytes) {
                case (?bytes) ?bytes;
                case (null) ?(KB * 10);
            };

            headers = Iter.toArray(
                Iter.map(
                    req.headers.entries(),
                    func((name, value) : (Text, Text)) : T.HttpHeader {
                        { name; value };
                    },
                ),
            );

            body = ?Blob.toArray(request.body.blob());
            method = switch (req.method) {
                case ("GET") #get;
                case ("POST") #post;
                case ("HEAD ") #head;
                case (_) Debug.trap("Unsupported method: " # req.method);
            };
            transform = null;
        };

        let httpRes : T.CanisterHttpResponse = await ic.http_request(args);

        let res = Response.Response();
        res.status := httpRes.status_code;
        res.setBody(Blob.fromArray(httpRes.body));

        for ({ name; value } in httpRes.headers.entries()) {
            res.headers.put(name, value);
        };

        return res;
    };
};
