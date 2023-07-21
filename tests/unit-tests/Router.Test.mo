import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

import { suite; test } "mo:test";
import Mo "mo:moh";

import {Router; Headers} "../../src";

let user = Principal.fromText("aaaaa-aa");

suite(
    "Router",
    func() {
        test(
            "adds a route",
            func() {
                let router = Router.Router();
                router.get(
                    "/app/test",
                    func(
                        req : Router.Request,
                        res : Router.ResponseBuilder,
                    ) {

                        assert req.method == "GET";
                        assert req.caller == Mo.Principal.anon();
                        assert req.url.text() == "/app/test";
                        assert Headers.toArray(req.headers) == [];
                        assert req.blob() == Blob.fromArray([]);

                        ignore res.text("test");
                    },
                );

                let httpReq = {
                    method = "GET";
                    url = "/app/test";
                    headers = [];
                    body = Blob.fromArray([]);
                };

                let httpRes = router.process_request(httpReq, null);

                assert httpRes.status_code == 200;
                assert httpRes.body == Text.encodeUtf8("test");
                assert httpRes.upgrade == ?false;
            },
        );

        test(
            "adds a route with query parameters",
            func() {
                let router = Router.Router();
                router.get(
                    "/users/:username",
                    func(
                        req : Router.Request,
                        res : Router.ResponseBuilder,
                    ) {
                        ignore do ? {
                            let username = req.params.get("username")!;
                            res.text(username);
                        };
                    },
                );

                let httpReq = {
                    method = "GET";
                    url = "/users/random_user1";
                    headers = [];
                    body = Blob.fromArray([]);
                };

                let httpRes = router.process_request(httpReq, null);

                assert httpRes.status_code == 200;
                assert httpRes.body == Text.encodeUtf8("random_user1");
                assert httpRes.upgrade == ?false;
            },
        );
        test(
            "process Post upgrade request",
            func() {
                let router = Router.Router();
                router.post(
                    "/users/:username",
                    func(
                        req : Router.Request,
                        res : Router.ResponseBuilder,
                    ) {

                        let username = switch (req.params.get("username")) {
                            case (?username) username;
                            case (null) "anon";
                        };

                        Debug.print(username);

                        ignore res.text(username);
                    },
                );

                let httpReq = {
                    method = "POST";
                    url = "/users/random_user1";
                    headers = [];
                    body = Blob.fromArray([]);
                };

                let httpRes = router.process_request(httpReq, null);
                let httpUpdateRes = router.process_request_update(httpReq, null);
                Debug.print(debug_show (httpRes.upgrade, httpRes.body, httpRes.status_code));
                Debug.print(debug_show (httpUpdateRes.upgrade, httpUpdateRes.body, httpUpdateRes.status_code));

                assert httpRes.upgrade == ?true;
                assert httpRes.body == Text.encodeUtf8("");

                assert httpUpdateRes.status_code == 200;
                assert httpUpdateRes.body == Text.encodeUtf8("random_user1");
            },
        );
    },
);
