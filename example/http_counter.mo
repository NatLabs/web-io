import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Prim "mo:⛔";
import Prelude "mo:base/Prelude";

import { Router } "../src"; // import { Router } "mo:web-api";

// This is a simple counter canister from the dfinity examples, rewritten using the web-api library.
// original - https://github.com/dfinity/examples/blob/master/motoko/http_counter/src/main.mo

actor HttpCounter {
    stable var counter : Nat = 0;

    let router = Router.Router();

    func is_gzip(req: Router.Request) : Bool {
        switch(req.headers.get("accept-encoding")){
            case (?encoding) Text.contains(encoding, #text "gzip");
            case (_) false;
        };
    };

    router.get(
        "*",
        func (req: Router.Request, res: Router.ResponseBuilder) {
            if (is_gzip(req)) {
                ignore res.text("Counter is " # debug_show(counter) # "\npath: " # req.url.path # "\n");
            }else {
                ignore res
                    .header("content-type", "text/plain")
                    .header("content-encoding", "gzip")
                    .blob("\1f\8b\08\00\98\02\1b\62\00\03\2b\2c\4d\2d\aa\e4\02\00\d6\80\2b\05\06\00\00\00");
            }
        }
    );

    router.post(
        "*",
        func (req: Router.Request, res: Router.ResponseBuilder) {
            counter += 1;

            ignore res.status(201);

            if (is_gzip(req)){
                ignore res
                    .header("content-type", "text/plain")
                    .header("content-encoding", "gzip")
                    .blob("\1f\8b\08\00\37\02\1b\62\00\03\2b\2d\48\49\2c\49\e5\02\00\a8\da\91\6c\07\00\00\00");
            }else {
                ignore res
                    .text("Counter updated to " # Nat.toText(counter) # "\n");
            };
        }
    );

    let response = ["Counter", " is ", Nat.toText(counter), " streaming\n"];

    public query func http_streaming(token : Router.StreamingToken) : async Router.StreamingResponse {

        let (text, next_token) = switch (token) {
            case (#Nat(1)) (response[1], ?#Nat(2));
            case (#Nat(2)) (response[2], ?#Nat(3));
            case (#Nat(3)) (response[3], null);
            case (_) Prelude.unreachable();
        };

        { body = Text.encodeUtf8(text); token = next_token};
    };

    router.get(
        "/stream", 
        func (req: Router.Request, res: Router.ResponseBuilder) {
            ignore res
                .text(response[0])
                .streaming(http_streaming, ?#Nat(1)); // pass the streaming function and the initial token
        }
    );

    router.error(
        func (req: Router.Request, res: Router.ResponseBuilder) {
            ignore res
                .status(400)
                .text("Invalid request");
        }
    );

    public query (msg) func http_request(req : Router.HttpRequest) : async Router.HttpResponse {
        router.process_request(req, ?msg);
    };

    public shared (msg) func http_request_update(req : Router.HttpRequest) : async Router.HttpResponse {
        router.process_request_update(req, ?msg);
    };

};
