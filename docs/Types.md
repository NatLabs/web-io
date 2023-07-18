# Types

## Type `HeaderField`
``` motoko no-repl
type HeaderField = (Text, Text)
```


## Type `HttpRequest`
``` motoko no-repl
type HttpRequest = { url : Text; method : Text; body : Blob; headers : [HeaderField] }
```


## Type `StreamingToken`
``` motoko no-repl
type StreamingToken = { key : Text; index : Nat }
```


## Type `StreamingResponse`
``` motoko no-repl
type StreamingResponse = { token : ?StreamingToken; body : Blob }
```


## Type `StreamingCallback`
``` motoko no-repl
type StreamingCallback = shared query (StreamingToken) -> async StreamingResponse
```


## Type `StreamingStrategy`
``` motoko no-repl
type StreamingStrategy = {#Callback : { token : StreamingToken; callback : StreamingCallback }}
```


## Type `HttpResponse`
``` motoko no-repl
type HttpResponse = { status_code : Nat16; body : Blob; headers : [HeaderField]; update : ?Bool; streaming_strategy : ?StreamingStrategy }
```


## Type `URL`
``` motoko no-repl
type URL = { text : Text; protocol : Text; port : Nat16; host : Text; path : Text; segments : [Text]; query_map : TrieMap.TrieMap<Text, Text>; query_text : () -> Text; query_candid : () -> Blob; anchor : Text }
```


## Type `Form`
``` motoko no-repl
type Form = { get : (Text) -> ?[Text]; trieMap : TrieMap.TrieMap<Text, [Text]>; keys : [Text]; fileKeys : [Text]; files : (Text) -> ?[File] }
```


## Type `Headers`
``` motoko no-repl
type Headers = { original : [(Text, Text)]; get : (Text) -> ?[Text]; trieMap : TrieMap.TrieMap<Text, [Text]>; keys : [Text] }
```


## Type `File`
``` motoko no-repl
type File = { name : Text; filename : Text; mimeType : Text; mimeSubType : Text; start : Nat; end : Nat; bytes : Buffer.Buffer<Nat8> }
```


## Type `Body`
``` motoko no-repl
type Body = { original : Blob; size : Nat; form : Form; text : () -> Text; file : () -> ?Buffer.Buffer<Nat8>; bytes : (start : Nat, end : Nat) -> Buffer.Buffer<Nat8> }
```


## Type `FormObjType`
``` motoko no-repl
type FormObjType = { get : (Text) -> ?[Text]; trieMap : TrieMap.TrieMap<Text, [Text]>; keys : [Text]; fileKeys : [Text]; files : (Text) -> ?[File] }
```


## Type `ParsedHttpRequest`
``` motoko no-repl
type ParsedHttpRequest = { method : Text; url : URL; headers : Headers; body : ?Body }
```


## Type `SharedMessage`
``` motoko no-repl
type SharedMessage = { caller : Principal }
```


## Type `HttpHeader`
``` motoko no-repl
type HttpHeader = { name : Text; value : Text }
```

Canister HTTP outcall request and response types

## Type `HttpMethod`
``` motoko no-repl
type HttpMethod = {#get; #post; #head}
```


## Type `TransformContext`
``` motoko no-repl
type TransformContext = { function : shared query TransformArgs -> async CanisterHttpResponse; context : Blob }
```


## Type `CanisterHttpRequest`
``` motoko no-repl
type CanisterHttpRequest = { url : Text; max_response_bytes : ?Nat64; headers : [HttpHeader]; body : ?[Nat8]; method : HttpMethod; transform : ?TransformContext }
```


## Type `CanisterHttpResponse`
``` motoko no-repl
type CanisterHttpResponse = { status : Nat; headers : [HttpHeader]; body : [Nat8] }
```


## Type `RedirectedResponse`
``` motoko no-repl
type RedirectedResponse = { url : Text; response : CanisterHttpResponse }
```


## Type `OutcallResponse`
``` motoko no-repl
type OutcallResponse = CanisterHttpResponse and { redirects : [RedirectedResponse] }
```


## Type `TransformArgs`
``` motoko no-repl
type TransformArgs = { response : CanisterHttpResponse; context : Blob }
```


## Type `ManagementCanister`
``` motoko no-repl
type ManagementCanister = actor { http_request : shared CanisterHttpRequest -> async CanisterHttpResponse }
```

