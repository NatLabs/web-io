import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import { suite; test } "mo:test/async";

import { outcall; Response } "../../src";

actor {
    public func test1 () : async () {
        let canonical_res = await* outcall.get("example.com/users/random_user")
            .add_query("name", "John")
            .add_query("age", "42")
            .header("Accept", "application/json")
            .header("X-Request-Id", "12345")
            .send_request();

        let res = Response.fromCanisterHttp(canonical_res);

        // assert res.method == "GET";

        // assert res.url.host == "example.com";
        // assert res.url.path == "/users/random_user";

        // assert res.query_map.get("name") == ?"John";
        // assert res.query_map.get("age") == ?"42";

        type Details = {
            name : Text;
            age : Nat;
            number : ?Text;
        };

        // let ?user_details : ?Details = from_candid (res.query_candid()) else {
        //     assert false;
        //     return;
        // };

        // assert user_details.name == "John";
        // assert user_details.age == 42;
        // assert user_details.number == null;

        // assert res.headers.get("Accept") == ?"application/json";
        // assert res.headers.get("X-Request-Id") == ?"12345";
    }
};


suite(
    "Testing outcall",
    func() : async () {
        await test(
            "Get request",
            func() : async ()  {

                let canonical_res = await* outcall.get("example.com/users/random_user")
                    .add_query("name", "John")
                    .add_query("age", "42")
                    .header("Accept", "application/json")
                    .header("X-Request-Id", "12345")
                    .send_request();

                let res = Response.fromCanisterHttp(canonical_res);

                // assert res.method == "GET";

                // assert res.url.host == "example.com";
                // assert res.url.path == "/users/random_user";

                // assert res.query_map.get("name") == ?"John";
                // assert res.query_map.get("age") == ?"42";

                type Details = {
                    name : Text;
                    age : Nat;
                    number : ?Text;
                };

                // let ?user_details : ?Details = from_candid (res.query_candid()) else {
                //     assert false;
                //     return;
                // };

                // assert user_details.name == "John";
                // assert user_details.age == 42;
                // assert user_details.number == null;

                // assert res.headers.get("Accept") == ?"application/json";
                // assert res.headers.get("X-Request-Id") == ?"12345";
                Debug.p
                return ();
            },
        );
    },
);
