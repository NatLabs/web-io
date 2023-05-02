# outcall
A module for making Http outbound requests.

## Type `RequestBuilder`
``` motoko no-repl
type RequestBuilder = RequestBuilder.RequestBuilder
```


## Value `KB`
``` motoko no-repl
let KB
```


## Value `MB`
``` motoko no-repl
let MB
```


## Function `get`
``` motoko no-repl
func get(url : Text) : RequestBuilder
```

Returns a request builder for a get request.

## Function `post`
``` motoko no-repl
func post(url : Text) : RequestBuilder
```

Returns a request builder for a post request.

## Function `head`
``` motoko no-repl
func head(url : Text) : RequestBuilder
```

Returns a request builder for a put request.
