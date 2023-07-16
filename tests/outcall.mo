// @testmode wasi
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import { suite; test } "mo:test";

import outcall "../src/outcall";

suite(
    "Testing outcall",
    func() {
        test(
            "Get request",
            func() {
                let res = outcall.get("example.com/users/random_user").add_query("name", "John").add_query("age", "42").header("Accept", "application/json").header("X-Request-Id", "12345").build();

                assert res.method == "GET";

                assert res.url.host == "example.com";
                assert res.url.path == "/users/random_user";

                assert res.query_map.get("name") == ?"John";
                assert res.query_map.get("age") == ?"42";

                type Details = {
                    name : Text;
                    age : Nat;
                    number : ?Text;
                };

                let ?user_details : ?Details = from_candid (res.query_candid()) else {
                    assert false;
                    return;
                };

                assert user_details.name == "John";
                assert user_details.age == 42;
                assert user_details.number == null;

                assert res.headers.get("Accept") == ?"application/json";
                assert res.headers.get("X-Request-Id") == ?"12345";

            },
        );
    },
);
