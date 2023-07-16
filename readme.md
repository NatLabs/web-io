# Web I/O

This library provides a high-level API for making HTTP requests and interacting with the web from a Motoko canister.

 > This is still a work in progress. The API is not stable and is subject to change.
 
 This is an example of how the `web-io` library could be used once it is fully implemented.
 ## Usage
### Import the library
```motoko
import { outcall; Router; Response; } "mo:web-io";
```
### Modules
#### outcall
```motoko
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

Check out the [send_http_post_backend.mo](./example/send_http_post_backend.mo) file for a more complete example. It features a re-write of [dfinity's send_http_post example]([./example/send_http_post.mo](https://github.com/dfinity/examples/blob/master/motoko/send_http_post/src/send_http_post_backend/main.mo)) using the `web-io` library.

#### Router
```motoko
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

Check out the [http_counter.mo](./example/http_counter.mo) file for an example of how to use the `Router` module. This example is a re-write of [dfinity's http_counter example](https://github.com/dfinity/examples/blob/master/motoko/http_counter/src/main.mo) using the `web-io` library.

## Planned Features
- [x] Add support for parsing JSON and URL encoded data into Motoko types
- [x] Add a module for creating outgoing HTTP requests via cascading methods.
- [ ] Add support for `multipart/form-data` requests
- [ ] Support all classes and functionality in the [http-parser.mo library](https://github.com/NatLabs/http-parser.mo) (Cannot Currently parse multipart form data)
- [ ] Add middleware support to the `Router` module
- [ ] Add support for storing internal app state data in the `Router` module

## Limitations
#### outcall
- A successful response from an outcall request need to be passed into the `Response.fromCanisterHttp` function to convert into a `Response` object because it's a shared type that cannot be returned from an async function.
#### Router
- Users cannot set their own [StreamingStrategy](./docs/Types.md#type-streamingstrategy) Token because the [StreamingCallback](./docs/Types.md#type-streamingcallback) is an async function that cannot return generic types. Instead, there is a [StreamingToken](./docs/Types.md#type-streamingtoken) type that is defined with useful fields for the user to use.
- 

## References
- [Content Disposition RFC](https://www.ietf.org/rfc/rfc2183.txt)