# http tools
 WIP

 > This is a work in progress. The API is not stable and may change at any time.
 
 This is an example of how the `web-api` can be used once it is fully implemented.
## outcall
```motoko
    import Request "mo:web-api/Request";
    import outcall "mo:web-api/outcall";

    type Stats = {
        users : Nat;
        posts : Nat;
    };

    public func getStats(): async ?Stats {
        let req = Request.get("https://example.com/api/stats");

        let res = await outcall.fetch(req);
        let blob = res.body.json();

        from_candid(blob);
    };
```
## Router
```motoko
    import Router "mo:web-api/Router";

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

            res.text(username # "'s profile page").build();
        },
    );

    router.post(
        "/users/signup",
        func(
            req : Router.Request,
            res : Router.ResponseBuilder,
        ) : async Router.HttpResponse {
            
            type Credentials = {
                username : Text;
                password : Text;
            };

            let blob = req.body.json();
            
            let data : Credentials = switch(from_candid(blob)){
                case (?data) data;
                case (null) {
                    return res.status(400).text("Bad Request").build();
                };
            };

            // access data.username and data.password
            validatePassword(data.password);

            res.text(username # " signed in successfully").build();
        },
    );

    public query func http_request(httpReq: Router.HttpRequest) : async Router.HttpResponse {
        await router.processRequest(httpReq);
    };

    public func http_request_update(httpReq: Router.HttpRequest) : async Router.HttpResponse {
        await router.processUpdateRequest(httpReq);
    };
```