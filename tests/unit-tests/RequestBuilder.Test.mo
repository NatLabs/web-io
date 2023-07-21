// @testmode wasi

import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import { suite; test } "mo:test";

import RequestBuilder "../../src/RequestBuilder";
import Response "../../src/Response";

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
        );

        test(
            "Serialize to JSON", 
            func() {

                type Details = {
                    name : Text;
                    age : Nat;
                    tags : [Text];
                    email : ?Text;
                };

                let DetailsKeys = ["name", "age", "tags", "email"];

                let details_example = {
                    name = "John";
                    age = 42;
                    tags = ["foo", "bar"];
                    email = null;
                };

                let res = RequestBuilder
                    .RequestBuilder("example.com/users/random_user")
                    .method("POST")
                    .json(to_candid(details_example), DetailsKeys)
                    .build();

                let response_body : ?Details = from_candid(res.strict_json());

                assert response_body == ?details_example;

            }
        )
    },
);
