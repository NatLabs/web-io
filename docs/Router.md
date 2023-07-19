# Router

## Type `Request`
``` motoko no-repl
type Request = Request.Request
```


## Type `Response`
``` motoko no-repl
type Response = Response.Response
```


## Type `Candid`
``` motoko no-repl
type Candid = T.Candid
```


## Type `ResponseBuilder`
``` motoko no-repl
type ResponseBuilder = RB.ResponseBuilder
```


## Type `HttpRequest`
``` motoko no-repl
type HttpRequest = T.HttpRequest
```


## Type `HttpResponse`
``` motoko no-repl
type HttpResponse = T.HttpResponse
```


## Type `RouterResult`
``` motoko no-repl
type RouterResult = Result.Result<(), HttpResponse>
```


## Type `AsyncRouterHandler`
``` motoko no-repl
type AsyncRouterHandler = (Request, ResponseBuilder) -> async* ()
```


## Type `SyncRouterHandler`
``` motoko no-repl
type SyncRouterHandler = (Request, ResponseBuilder) -> ()
```


## Type `SharedMessage`
``` motoko no-repl
type SharedMessage = T.SharedMessage
```


## Type `StreamingCallback`
``` motoko no-repl
type StreamingCallback = T.StreamingCallback
```


## Type `StreamingToken`
``` motoko no-repl
type StreamingToken = T.StreamingToken
```


## Type `StreamingResponse`
``` motoko no-repl
type StreamingResponse = T.StreamingResponse
```


## Value `PATH_PARAMS_ID`
``` motoko no-repl
let PATH_PARAMS_ID
```


## Value `FALLBACK_ID`
``` motoko no-repl
let FALLBACK_ID
```


## Type `RouterError`
``` motoko no-repl
type RouterError = {#RouteNotFound : HttpRequest}
```


## Class `Router`

``` motoko no-repl
class Router()
```


### Value `routes`
``` motoko no-repl
let routes : RouteMap
```



### Function `mount`
``` motoko no-repl
func mount(endpoint : Text, other : Router)
```

Merges the routes of another router into this one
Similar to express's router.use()


### Function `error`
``` motoko no-repl
func error(handler : SyncRouterHandler)
```

Handler for when a request is not found


### Function `process_request`
``` motoko no-repl
func process_request(http_req : T.HttpRequest, message : ?SharedMessage) : T.HttpResponse
```

Processes a request for the `http_request` function


### Function `process_request_update`
``` motoko no-repl
func process_request_update(http_req : T.HttpRequest, message : ?SharedMessage) : T.HttpResponse
```

Processes a request for the `http_request_update` function


### Function `get`
``` motoko no-repl
func get(endpoint : Text, callback : SyncRouterHandler)
```



### Function `put`
``` motoko no-repl
func put(endpoint : Text, callback : SyncRouterHandler)
```



### Function `delete`
``` motoko no-repl
func delete(endpoint : Text, callback : SyncRouterHandler)
```



### Function `post`
``` motoko no-repl
func post(endpoint : Text, callback : SyncRouterHandler)
```



### Function `patch`
``` motoko no-repl
func patch(endpoint : Text, callback : SyncRouterHandler)
```

