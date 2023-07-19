# RequestBuilder
A request builder for making HTTP requests.

## Type `MutableInternalState`
``` motoko no-repl
type MutableInternalState = { var url : URL.URL; var method : Text; var headers : Headers.Headers; var caller : Principal; var transform : ?T.TransformContext; var body : Blob; var max_redirects : Nat; var form : Form.Form; var cycles : Nat; var max_response_bytes : Nat64 }
```


## Type `InternalState`
``` motoko no-repl
type InternalState = { url : URL.URL; method : Text; headers : Headers.Headers; caller : Principal; transform : ?T.TransformContext; body : Blob; max_redirects : Nat; form : Form.Form; cycles : Nat; max_response_bytes : Nat64 }
```


## Type `RequestBuilderChainingInterface`
``` motoko no-repl
type RequestBuilderChainingInterface<Builder> = { add_query : (Text, Text) -> Builder; auth : (Text, Text) -> Builder; bearer_token : Text -> Builder; blob : Blob -> Builder; caller : Principal -> Builder; cookie : (Text, Text) -> Builder; cycles : Nat -> Builder; file : (Text, File) -> Builder; files : [(Text, File)] -> Builder; form_field : (Text, Text) -> Builder; form_fields : [(Text, Text)] -> Builder; header : (Text, Text) -> Builder; headers : [T.HeaderField] -> Builder; html : Text -> Builder; json : (Blob, [Text]) -> Builder; max_bytes : Nat64 -> Builder; max_redirects : Nat -> Builder; method : Text -> Builder; queries : [(Text, Text)] -> Builder; text : Text -> Builder; transform : ?T.TransformContext -> Builder }
```


## Type `RequestBuilderInterface`
``` motoko no-repl
type RequestBuilderInterface<RequestBuilderClass> = RequestBuilderChainingInterface<RequestBuilderClass> and { build : () -> Request.Request; build_canister_http : () -> T.CanisterHttpRequest; build_http : () -> T.HttpRequest }
```


## Class `RequestBuilder`

``` motoko no-repl
class RequestBuilder(url_text : Text)
```

A request builder for making HTTP requests.

The request builder is used to construct a request, which can then be
sent using the `send_request()` method.

### Function `get_state`
``` motoko no-repl
func get_state() : InternalState
```

Returns the current state of the request builder.


### Function `_get_mut_state`
``` motoko no-repl
func _get_mut_state() : MutableInternalState
```



### Function `add_query`
``` motoko no-repl
func add_query(key : Text, val : Text) : RequestBuilder
```

Adds a query parameter to the request.


### Function `queries`
``` motoko no-repl
func queries(entries : [(Text, Text)]) : RequestBuilder
```

Adds multiple query parameters to the request.


### Function `method`
``` motoko no-repl
func method(text : Text) : RequestBuilder
```

Sets the request method.


### Function `header`
``` motoko no-repl
func header(key : Text, val : Text) : RequestBuilder
```

Adds a header field to the request.


### Function `headers`
``` motoko no-repl
func headers(entries : [T.HeaderField]) : RequestBuilder
```

Adds multiple header fields to the request.


### Function `max_bytes`
``` motoko no-repl
func max_bytes(n : Nat64) : RequestBuilder
```

Sets the maximum bytes that can be returned in the response.


### Function `cycles`
``` motoko no-repl
func cycles(n : Nat) : RequestBuilder
```

Sets the maximum amount of cycles that can be spent on the request.


### Function `caller`
``` motoko no-repl
func caller(p : Principal) : RequestBuilder
```

Sets the caller that initiated the request.


### Function `blob`
``` motoko no-repl
func blob(blob : Blob) : RequestBuilder
```

Sets the request body to the given blob.


### Function `text`
``` motoko no-repl
func text(text : Text) : RequestBuilder
```

Sets the request body to the given text.


### Function `json`
``` motoko no-repl
func json(candid : Blob, keys : [Text]) : RequestBuilder
```

Sets the request body to the given JSON blob.


### Function `html`
``` motoko no-repl
func html(html : Text) : RequestBuilder
```

Sets the request body to the given HTML text.


### Function `form_field`
``` motoko no-repl
func form_field(key : Text, val : Text) : RequestBuilder
```

Adds a form field to the request.


### Function `form_fields`
``` motoko no-repl
func form_fields(entries : [(Text, Text)]) : RequestBuilder
```

Adds multiple form fields to the request.


### Function `file`
``` motoko no-repl
func file(key : Text, File : File.File) : RequestBuilder
```

Adds a file to the request.


### Function `files`
``` motoko no-repl
func files(entries : [(Text, File.File)]) : RequestBuilder
```

Adds multiple files to the request.


### Function `transform`
``` motoko no-repl
func transform(tc : ?T.TransformContext) : RequestBuilder
```



### Function `auth`
``` motoko no-repl
func auth(username : Text, password : Text) : RequestBuilder
```

Sets the 'Authorization' header field using Basic Auth.


### Function `bearer_token`
``` motoko no-repl
func bearer_token(token : Text) : RequestBuilder
```

Sets the 'Authorization' header field with the given Bearer token.


### Function `cookie`
``` motoko no-repl
func cookie(name : Text, value : Text) : RequestBuilder
```

Sets the 'Cookie' header field with the given name and value.


### Function `build`
``` motoko no-repl
func build() : Request.Request
```

Returns a Request object with helper functions for accessing the response data.


### Function `build_http`
``` motoko no-repl
func build_http() : T.HttpRequest
```

Builds a `HttpRequest` record that is returned in the `http_request` and `http_request_update` functions.


### Function `build_canister_http`
``` motoko no-repl
func build_canister_http() : T.CanisterHttpRequest
```

Builds a `CanisterHttpRequest` record that is returned after making an outcall.
