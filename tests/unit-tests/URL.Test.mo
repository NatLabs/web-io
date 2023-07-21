// @testmode wasi
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import { suite; test } "mo:test";

import URL "../../src/URL";

suite(
    "URL",
    func() {
        test(
            "Get request",
            func() {

                let url = URL.URL("https://www.google.com:8123/apps/counter/?tag=2526172523#myAnchor");

                assert url.protocol == "https";
                assert url.host == "www.google.com";
                assert url.port == 8123;
                assert url.path == "/apps/counter";
                assert url.segments == ["apps", "counter"];

                assert url.query_map.get("tag") == ?"2526172523";
                assert url.anchor == "myAnchor";

                assert url.text() == "https://www.google.com:8123/apps/counter?tag=2526172523#myAnchor";
            },
        );

        test(
            "Deserialize request query",
            func() {

                let url = URL.URL("https://www.google.com:8123/apps/counter/?tag=2526172523#myAnchor");
                url.query_map.put("name", "John");
                url.query_map.put("age", "42");

                type Details = {
                    name : Text;
                    age : Nat;
                    tag : Nat;
                    number : ?Text;
                };

                let ?user_details : ?Details = from_candid (url.query_candid()) else {
                    assert false;
                    return;
                };

                assert user_details.name == "John";
                assert user_details.age == 42;
                assert user_details.tag == 2526172523;
                assert user_details.number == null;

            },
        );
    },
);
