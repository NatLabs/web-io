import Debug "mo:base/Debug";
import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Router "../../src/Router";


actor {

    let router = Router.Router();
    type UserDetails = {
        name : Text;
        id : Nat;
        posts : Nat;
        unique_visitors : Nat;
    };

    let UserDetailsKeys = ["name", "id", "posts", "unique_visitors"];

    let init_data = [
        ("alice", { name = "Alice"; id = 1; posts = 10; unique_visitors = 100 }),
        ("bob", { name = "Bob"; id = 2; posts = 20; unique_visitors = 200 }),
        ("carol", { name = "Carol"; id = 3; posts = 30; unique_visitors = 300 }),
    ];

    let user_details = TrieMap.fromEntries<Text, UserDetails>(init_data.vals(), Text.equal, Text.hash);

    func getAllUsers(
        req : Router.Request,
        res : Router.ResponseBuilder,
    ) {
        let users : [UserDetails] = Iter.toArray(user_details.vals());
        ignore res.json(to_candid (users), UserDetailsKeys);
    };

    func getUserDetailsByUsername(
        req : Router.Request,
        res : Router.ResponseBuilder,
    ) {
        ignore do ? {
            let username = req.params.get("username")!;
            let user = user_details.get(username)!;
            res.json(to_candid (user), UserDetailsKeys);
        };
    };

    func createNewUser(
        req : Router.Request,
        res : Router.ResponseBuilder,
    ) {

        ignore do ? {
            let username = req.params.get("username")!;

            let blob = req.json()!;
            let details : ?UserDetails = from_candid (blob);

            user_details.put(username, details!);

            ignore res.text("User [" # username # "] has been added/updated.");
        };
    };
    // These functions should be defined outside the http_request function to avoid redefining them on every request.

    router.get("/users", getAllUsers);
    router.get("/users/:username", getUserDetailsByUsername);
    router.post("/users/:username", createNewUser);

    public shared query (msg) func http_request(httpReq : Router.HttpRequest) : async Router.HttpResponse {
        let x = router.process_request(httpReq, ?msg);
    };

    public shared (msg) func http_request_update(httpReq : Router.HttpRequest) : async Router.HttpResponse {
        Debug.print("http_request_update: " # debug_show (httpReq.body, httpReq.method));
        router.process_request_update(httpReq, ?msg);
    };
};
