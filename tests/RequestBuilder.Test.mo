// cant use 'wasi' testmode because the RequestBuilder module has async functions
// Using the interpreter instead

import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import { suite; test } "mo:test";

import RequestBuilder "../src/RequestBuilder";

suite(
    "Testing RequestBuilder",
    func() {
        test("Get request", func(){ 
            let res = RequestBuilder
                .RequestBuilder("example.com/users/random_user")
                .method("GET")
                .add_query("name", "John")
                .add_query("age", "42")
                .header("Accept", "application/json")
                .header("X-Request-Id", "12345")
                .build();

            assert res.method == "GET";
            
            assert res.url.host == "example.com";
            assert res.url.path == "/users/random_user";

            assert res.query_map.get("name") == ?"John";
            assert res.query_map.get("age") == ?"42";
          
        });

        test(
            "Post request",
            func(){
                let res = RequestBuilder
                    .RequestBuilder("example.com/users/random_user")
                    .method("POST")
                    .add_query("name", "John")
                    .add_query("age", "42")
                    .header("Accept", "application/json")
                    .header("X-Request-Id", "12345")
                    .build();

                assert res.method == "POST";
                
                assert res.url.host == "example.com";
                assert res.url.path == "/users/random_user";

                assert res.query_map.get("name") == ?"John";
                assert res.query_map.get("age") == ?"42";
            }
        )
    },
);
