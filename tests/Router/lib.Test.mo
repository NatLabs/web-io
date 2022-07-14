import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import ActorSpec "../utils/ActorSpec";

import Router "../../src/Router";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

let success = run([
    describe(
        "Router",
        [
            it(
                "adds a route",
                do {
                    let router = Router.Router();
                    router.get(
                        "/app/test",
                        func(
                            req : Router.Request,
                            res : Router.ResponseBuilder,
                        ) : async Router.HttpResponse {
                            res.text("test").build();
                        },
                    );

                    let httpReq = {
                        method = "GET";
                        url = "/app/test";
                        headers = [];
                        body = Blob.fromArray([]);
                    };

                    let httpRes = await router.processRequest(httpReq);
                    Debug.print(debug_show (httpRes.status_code));

                    assertAllTrue([
                        httpRes.status_code == 200,
                        httpRes.body == Text.encodeUtf8("test"),
                        httpRes.update == false,
                    ]);
                },
            ),

            it(
                "adds a route with query parameters",
                do {
                    let router = Router.Router();
                    router.get(
                        "/users/:username",
                        func(
                            req : Router.Request,
                            res : Router.ResponseBuilder,
                        ) : async Router.HttpResponse {
                            let username = switch (req.params.get("username")) {
                                case (?username) username;
                                case (null) "anon";
                            };

                            res.text(username).build();
                        },
                    );

                    let httpReq = {
                        method = "GET";
                        url = "/users/random_user1";
                        headers = [];
                        body = Blob.fromArray([]);
                    };

                    let httpRes = await router.processRequest(httpReq);

                    assertAllTrue([
                        httpRes.status_code == 200,
                        httpRes.body == Text.encodeUtf8("random_user1"),
                        httpRes.update == false,
                    ]);
                },
            ),

            it(
                "process Post update request",
                do {
                    let router = Router.Router();
                    router.post(
                        "/users/:username",
                        func(
                            req : Router.Request,
                            res : Router.ResponseBuilder,
                        ) : async Router.HttpResponse {
                            let username = switch (req.params.get("username")) {
                                case (?username) username;
                                case (null) "anon";
                            };

                            res.text(username).build();
                        },
                    );

                    let httpReq = {
                        method = "POST";
                        url = "/users/random_user1";
                        headers = [];
                        body = Blob.fromArray([]);
                    };

                    let httpRes = await router.processRequest(httpReq);
                    let httpUpdateRes = await router.processUpdateRequest(httpReq);

                    assertAllTrue([
                        httpRes.update == true,
                        httpRes.body == Text.encodeUtf8(""),

                        httpUpdateRes.status_code == 200,
                        httpUpdateRes.body == Text.encodeUtf8("random_user1"),
                    ]);
                },
            ),
        ],
    ),

    // describe("Post Routes", [
    //     it("")
    // ])
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
