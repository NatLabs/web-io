import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";
import Router "../../src/Router";

import Users "users";

actor {
    
    let user_details = TrieMap.fromEntries<Text, Users.UserDetails>(Users.init_data, Text.equal, Text.hash);

    let router = Router.Router();

    // These functions should be defined outside the http_request function to avoid redefining them on every request.

    router.get("/users", Users.getAllUsers);
    router.get("/users/:username", Users.getUserDetailsByUsername);
    router.post("/users/:username", Users.createNewUser);

    public shared query (msg) func http_request(httpReq : Router.HttpRequest) : async Router.HttpResponse {
        let x = router.process_request(httpReq, msg);
        { x with update = ?true};
    };

    public shared (msg) func http_request_update(httpReq : Router.HttpRequest) : async Router.HttpResponse {
        Debug.print("http_request_update: " # debug_show (httpReq.body, httpReq.method));
        await* router.process_async_update_request(httpReq, msg);
    };
};
