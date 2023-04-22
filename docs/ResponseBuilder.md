# ResponseBuilder
A builder for Http Response objects and records

## `class ResponseBuilder`


### Function `status`
``` motoko no-repl
func status(code : Nat16) : ResponseBuilder
```

Sets the status code of the response.


### Function `update`
``` motoko no-repl
func update(val : Bool) : ResponseBuilder
```

Sets the `update` flag of the response.
If true, the response will be resent to the `http_request_update()` function in the canister.


### Function `header`
``` motoko no-repl
func header(key : Text, value : Text) : ResponseBuilder
```

Adds a field to the response headers.


### Function `headers`
``` motoko no-repl
func headers(entries : [T.HeaderField]) : ResponseBuilder
```

Adds multiple fields to the response headers.


### Function `blob`
``` motoko no-repl
func blob(blob : Blob) : ResponseBuilder
```

Sets the response body to the given blob.


### Function `text`
``` motoko no-repl
func text(text : Text) : ResponseBuilder
```

Sets the response body to the given text.


### Function `json`
``` motoko no-repl
func json(json : Blob, keys : [Text]) : ResponseBuilder
```

Sets the response body to the given JSON blob.


### Function `html`
``` motoko no-repl
func html(html : Text) : ResponseBuilder
```

Sets the response body to the given HTML text.


### Function `streaming`
``` motoko no-repl
func streaming(callback : T.StreamingCallback, init_token : ?T.StreamingToken) : ResponseBuilder
```

Sets the canister's streaming strategy for the response.
The `callback` will be called when the client requests the next chunk of the response.
The `init_token` is an optional token that will be passed to the `callback` on the first call.
If `init_token` is `null`, the `callback` will not be called.


### Function `redirect`
``` motoko no-repl
func redirect(url : Text) : ResponseBuilder
```

Sets the `url` to redirect the client to.


### Function `build`
``` motoko no-repl
func build() : Response.Response
```

Returns a `Response` object.


### Function `build_http`
``` motoko no-repl
func build_http() : T.HttpResponse
```

Returns a `HttpResponse` record.


### Function `build_canister_http`
``` motoko no-repl
func build_canister_http() : T.CanisterHttpResponse
```

A builder for Http Response objects and records

### Current Limitations
- Unable to set custom token for the streaming strategy.
  Users have to use the default `StreamingToken` type which consists of a key and a value.
