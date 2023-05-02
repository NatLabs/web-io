import Debug "mo:base/Debug";
import Nat16 "mo:base/Nat16";
import Option "mo:base/Option";
import Text "mo:base/Text";

import Mo "mo:moh";
import serde_json = "mo:serde/JSON";

import outcall "../../src/outcall"; // replace with 'import Router "mo:web/Router";''
import Router "../../src/Router"; // replace with 'import Router "mo:web/Router";''
import Form "../../src/Form"; // replace with 'import Form "mo:web/Form";''
import Response "../../src/Response"; // replace with 'import Form "mo:web/Form";''
import Utils "utils";

actor {

    // let text = "------WebKitFormBoundaryejTR1UTRGy57HI86\nContent-Disposition: form-data; name=\"firstname\"; filename=\"file.txt\"\nContent-Type: text/plain\n\n?Ausi\n------WebKitFormBoundaryejTR1UTRGy57HI86\nContent-Disposition: form-data; name=\"firstname\"\n\n?Ausi\n------WebKitFormBoundaryejTR1UTRGy57HI86\nContent-Disposition: form-data; name=\"lastname\"\n\nThis is a sample text value.\nThis is the second line.\n------WebKitFormBoundaryejTR1UTRGy57HI86--";
    // let form = Form.parse(text, ?"----WebKitFormBoundaryejTR1UTRGy57HI86");
    
    let router = Router.Router();

    router.get(
        "/",
        func(req : Router.Request, res : Router.ResponseBuilder) {
            Utils.debugRequestParser(req);
            
            let optName = do ? { req.query_map.get("name")! };
            let name = Option.get(optName, "");

            ignore res.html(Utils.htmlPage(name));
        },
    );

    router.post(
        "/",
        func(req : Router.Request, res : Router.ResponseBuilder){
            Utils.debugRequestParser(req);
            let optName = do ? { req.query_map.get("name")! };
            let name = Option.get(optName, "");

            ignore res.text(" Thanks " # name # " for submitting the form!");
        },
    );

    type JokeObj = {
        setup : Text;
        delivery : Text;
    };

    public func get_joke() : async ?JokeObj {
        let raw_res = await outcall
            .get("https://v2.jokeapi.dev/joke/Programming")
            .add_query("type", "twopart")
            .cycles(200_000_000)
            .send_request();

        let res = Response.fromCanisterHttp(raw_res);

        let json_blob = res.strict_json();
        from_candid(json_blob);
    };

    public shared query (msg) func http_request(rawReq : Router.HttpRequest) : async  Router.HttpResponse {
        router.process_request(rawReq, msg);
    };

    public shared (msg) func http_request_update(rawReq : Router.HttpRequest) : async Router.HttpResponse {
        router.process_request_update(rawReq, msg);
    };

};
