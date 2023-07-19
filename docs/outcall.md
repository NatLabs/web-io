# outcall
A module for making Http outbound requests.

## Value `KB`
``` motoko no-repl
let KB
```


## Value `MB`
``` motoko no-repl
let MB
```


## Class `Outcall`

``` motoko no-repl
class Outcall(url : Text)
```


### Function `add_query`
``` motoko no-repl
func add_query(key : Text, value : Text) : Outcall
```



### Function `auth`
``` motoko no-repl
func auth(username : Text, password : Text) : Outcall
```



### Function `bearer_token`
``` motoko no-repl
func bearer_token(token : Text) : Outcall
```



### Function `blob`
``` motoko no-repl
func blob(blob : Blob) : Outcall
```



### Function `caller`
``` motoko no-repl
func caller(principal : Principal) : Outcall
```



### Function `cookie`
``` motoko no-repl
func cookie(key : Text, value : Text) : Outcall
```



### Function `cycles`
``` motoko no-repl
func cycles(cycles : Nat) : Outcall
```



### Function `file`
``` motoko no-repl
func file(key : Text, file : File) : Outcall
```



### Function `files`
``` motoko no-repl
func files(files : [(Text, File)]) : Outcall
```



### Function `form_field`
``` motoko no-repl
func form_field(key : Text, value : Text) : Outcall
```



### Function `form_fields`
``` motoko no-repl
func form_fields(fields : [(Text, Text)]) : Outcall
```



### Function `header`
``` motoko no-repl
func header(key : Text, value : Text) : Outcall
```



### Function `headers`
``` motoko no-repl
func headers(fields : [T.HeaderField]) : Outcall
```



### Function `html`
``` motoko no-repl
func html(html : Text) : Outcall
```



### Function `json`
``` motoko no-repl
func json(blob : Blob, fields : [Text]) : Outcall
```



### Function `max_bytes`
``` motoko no-repl
func max_bytes(max_bytes : Nat64) : Outcall
```



### Function `method`
``` motoko no-repl
func method(method : Text) : Outcall
```



### Function `queries`
``` motoko no-repl
func queries(queries : [(Text, Text)]) : Outcall
```



### Function `text`
``` motoko no-repl
func text(text : Text) : Outcall
```



### Function `transform`
``` motoko no-repl
func transform(context : ?T.TransformContext) : Outcall
```



### Function `max_redirects`
``` motoko no-repl
func max_redirects(max : Nat) : Outcall
```

Sets the maximum amount of redirects that can be followed.


### Function `follow_redirects`
``` motoko no-repl
func follow_redirects(follow : Bool) : Outcall
```

Give permission to the request to follow redirects.


### Function `send_request`
``` motoko no-repl
func send_request() : async* T.OutcallResponse
```

Send out the HTTP request and return the response.

## Function `get`
``` motoko no-repl
func get(url : Text) : Outcall
```

Returns a request builder for a get request.

## Function `post`
``` motoko no-repl
func post(url : Text) : Outcall
```

Returns a request builder for a post request.

## Function `head`
``` motoko no-repl
func head(url : Text) : Outcall
```

Returns a request builder for a put request.
