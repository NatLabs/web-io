# Request

## Type `RequestInitData`
``` motoko no-repl
type RequestInitData = { method : Text; url : URL.URL; body : Blob; headers : Headers.Headers; caller : ?Principal.Principal; params : ?TrieMap.TrieMap<Text, Text> }
```

The Request class represents an HTTP request and provides helpful methods
Read-only information about an HTTP request
Use the `RequestBuilder` to create a `Request` object

## Class `Request`

``` motoko no-repl
class Request(init : RequestInitData)
```


### Value `url`
``` motoko no-repl
let url
```

A URL object created from the url sent in the request


### Value `query_map`
``` motoko no-repl
let query_map
```

Reference to the query parameter map in the URL object.


### Value `query_candid`
``` motoko no-repl
let query_candid
```

Function to serialize the query parameters in the URL object to a candid blob.


### Value `query_text`
``` motoko no-repl
let query_text
```

Function for converting the query parameters in the URL object to a Text.


### Value `method`
``` motoko no-repl
let method
```

The HTTP method of the request


### Value `headers`
``` motoko no-repl
let headers
```

The headers of the request as a Headers object


### Value `caller`
``` motoko no-repl
let caller
```

The caller of the request, if available. If the caller is not available, the **anonymous** principal is used.


### Value `params`
``` motoko no-repl
let params
```

The path parameters extrancted from the url.
The path parameters are the parts of the url that are prefixed with a colon when setting a route in the Router.
For example, in the url `/users/:id`, the path parameter is `id`.


### Function `blob`
``` motoko no-repl
func blob() : Blob
```

Returns the request body as a Blob


### Function `text`
``` motoko no-repl
func text() : ?Text
```

Returns the request body as a Text


### Function `strict_text`
``` motoko no-repl
func strict_text() : Text
```

Returns the request body as a Text, or traps if the body cannot be decoded as text


### Function `json`
``` motoko no-repl
func json() : ?Blob
```

Returns the request body as a JSON blob, that can be decoded to primitive motoko types using the `from_candid()` global function


### Function `strict_json`
``` motoko no-repl
func strict_json() : Blob
```

Returns the request body as a JSON blob, or traps if the body cannot be decoded as JSON


### Function `form`
``` motoko no-repl
func form() : Form.Form
```

Returns the request body as a Form object

## Function `fromHttpRequest`
``` motoko no-repl
func fromHttpRequest(httpReq : T.HttpRequest) : Request
```

Create a `Request` object from a `HttpRequest` record
