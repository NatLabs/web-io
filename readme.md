# Web I/O

This library provides a high-level API for making HTTP requests and interacting with the web from a Motoko canister.

 > This is still a work in progress. The API is not stable and is subject to change.
 
 This is an example of how the `web-io` library could be used once it is fully implemented.
## outcall
```motoko
    import outcall "mo:web-io/outcall";
    import Response "mo:web-io/Response";

    type JokeObj = {
        setup : Text;
        delivery : Text;
    };

    public func getJoke() : async ?JokeObj {
        let raw_res = await outcall
            .get("https://v2.jokeapi.dev/joke/Programming")
            .add_query("type", "twopart")
            .cycles(200_000_000)
            .send_request();

        let res = Response.fromCanisterHttp(raw_res);

        let json_blob = res.strict_json();
        return from_candid(json_blob);
    };
```
## Router
```motoko
    import Router "mo:web-io/Router";

    let router = Router.Router();

    router.get(
        "/users/:username",
        func(
            req : Router.Request,
            res : Router.ResponseBuilder,
        ) {
            let username = switch (req.params.get("username")) {
                case (?username) username;
                case (null) "anon";
            };

            res.text(username # "'s profile page");
        },
    );

    router.post(
        "/users/signup",
        func(
            req : Router.Request,
            res : Router.Response,
        ) {
            
            type Credentials = {
                username : Text;
                hash : Text;
            };

            let blob = req.strict_json();
            
            let data : Credentials = switch(from_candid(blob)){
                case (?data) data;
                case (null) {
                    res.status(400).text("Bad Request: Improperly formatted JSON");
                    return;
                };
            };

            store_user(data.username, data.hash);

            res.text(username # " signed up successfully");
        },
    );

    public query func http_request(httpReq: Router.HttpRequest) : async Router.HttpResponse {
        router.process_request(httpReq);
    };

    public func http_request_update(http_res: Router.HttpRequest) : async Router.HttpResponse {
        router.process_request_update(http_res);
    };
```

## References
- [Content Disposition RFC](https://www.ietf.org/rfc/rfc2183.txt)