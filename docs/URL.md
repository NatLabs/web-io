# URL

## Class `URL`

``` motoko no-repl
class URL(url : Text)
```

A URL class for parsing and manipulating URLs.

### Value `protocol`
``` motoko no-repl
let protocol
```

The protocol of the URL, e.g. "http" or "https".


### Value `anchor`
``` motoko no-repl
let anchor
```

The anchor of the URL.


### Value `query_map`
``` motoko no-repl
let query_map
```

Returns the TrieMap where the query parameters are stored.


### Function `query_candid`
``` motoko no-repl
func query_candid() : Blob
```

Returns the serialized candid blob of the query parameters.


### Function `query_text`
``` motoko no-repl
func query_text() : Text
```

Returns the query parameters as a Text.


### Value `segments`
``` motoko no-repl
let segments
```

Returns the segments of the path of the URL.


### Value `path`
``` motoko no-repl
let path
```

Returns the path of the URL. 


### Function `text`
``` motoko no-repl
func text() : Text
```

Returns the URL as a Text excluding the query parameters.
