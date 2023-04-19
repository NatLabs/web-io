import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

import Router "../../src/Router";

module Users {

    public type UserDetails = {
        name : Text;
        id : Nat;
        posts : Nat;
        unique_visitors : Nat;
    };

    public let user_detail_keys = ["name", "id", "posts", "unique_visitors"];

    public let init_data = [
        ("alice", { name = "Alice"; id = 1; posts = 10; unique_visitors = 100; }),
        ("bob", { name = "Bob"; id = 2; posts = 20; unique_visitors = 200; }),
        ("carol", { name = "Carol"; id = 3; posts = 30; unique_visitors = 300; }),
    ];
    
    public func getAllUsers(
        req : Router.Request,
        res : Router.Response,
    ) {
        let users : [UserDetails] = Iter.toArray(user_details.vals());
        res.body.setJson(to_candid (users), user_detail_keys);
    };

    public func getUserDetailsByUsername(
        req : Router.Request,
        res : Router.Response,
    ) {
        ignore do ? {
            let username = req.params.get("username")!;
            let user = user_details.get(username)!;
            res.body.setJson(to_candid (user), user_detail_keys);
        };
    };

    public func createNewUser(
        req : Router.Request,
        res : Router.Response,
    ) : async () {

        ignore do ? {
            let username = req.params.get("username")!;

            let blob = req.body.json()!;
            let details : ?UserDetails = from_candid (blob);

            user_details.put(username, details!);

            res.body.setText("User [" # username # "] has been added/updated.");
        };
    };
};
