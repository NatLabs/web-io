# Response

## Type `ResponseOptions`
``` motoko no-repl
type ResponseOptions = { update : Bool; streaming_strategy : ?T.StreamingStrategy; headers : ?Headers.Headers }
```


## `class Response`


### Value `status_code`
``` motoko no-repl
let status_code
```



### Value `update`
``` motoko no-repl
let update
```



### Value `headers`
``` motoko no-repl
let headers
```



### Value `streaming_strategy`
``` motoko no-repl
let streaming_strategy
```



### Function `blob`
``` motoko no-repl
func blob() : Blob
```



### Function `text`
``` motoko no-repl
func text() : ?Text
```



### Function `strict_text`
``` motoko no-repl
func strict_text() : Text
```



### Function `json`
``` motoko no-repl
func json() : ?Blob
```



### Function `strict_json`
``` motoko no-repl
func strict_json() : Blob
```



### Function `bytes`
``` motoko no-repl
func bytes() : [Nat8]
```



### Function `buffer`
``` motoko no-repl
func buffer() : Buffer.Buffer<Nat8>
```



### Function `size`
``` motoko no-repl
func size() : Nat
```


## Function `fromCanisterHttp`
``` motoko no-repl
func fromCanisterHttp(res : T.CanisterHttpResponse) : Response
```


## Function `fromHttpResponse`
``` motoko no-repl
func fromHttpResponse(res : T.HttpResponse) : Response
```


## Function `toHttpResponse`
``` motoko no-repl
func toHttpResponse(res : Response) : T.HttpResponse
```

