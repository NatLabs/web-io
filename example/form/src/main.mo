import Debug "mo:base/Debug";
import Nat16 "mo:base/Nat16";
import Option "mo:base/Option";
import Text "mo:base/Text";

import Mo "mo:moh";

import Router "../../../src/Router"; // replace with 'import Router "mo:web/Router";''

import Utils "utils";

actor {

    let router = Router.Router();

    router.get(
        "/",
        func(req : Router.Request, res : Router.ResponseBuilder) {
            Utils.debugRequestParser(req);
            
            let optName = do ? { req.query_params.get("name")! };
            let name = Option.get(optName, "");

            res.body.setHtml(Utils.htmlPage(name));
        },
    );

    router.post(
        "/",
        func(req : Router.Request, res : Router.ResponseBuilder){
            Utils.debugRequestParser(req);

            let optName = do ? { req.query_params.get("name")! };
            let name = Option.get(optName, "");

            res.body.setText(" Thanks " # name # " for submitting the form!");
        },
    );

    public shared query (msg) func http_request(rawReq : Router.HttpRequest) : async  Router.HttpResponse {
        router.process_request(rawReq, msg);
    };

    public shared (msg) func http_request_update(rawReq : Router.HttpRequest) : async Router.HttpResponse {
        router.process_update_request(rawReq, msg);
    };

};
