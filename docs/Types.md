# Types

## Type `HeaderField`
``` motoko no-repl
type HeaderField = (Text, Text)
```


## Type `HttpRequest`
``` motoko no-repl
type HttpRequest = { url : Text; method : Text; body : Blob; headers : [HeaderField] }
```


## Type `StreamingCallbackToken`
``` motoko no-repl
type StreamingCallbackToken = { key : Text; sha256 : ?Blob; index : Nat; content_encoding : Text }
```


## Type `StreamingStrategy`
``` motoko no-repl
type StreamingStrategy = {#Callback : { token : StreamingCallbackToken; callback : shared () -> async () }}
```


## Type `HttpResponse`
``` motoko no-repl
type HttpResponse = { status_code : Nat16; body : Blob; headers : [HeaderField]; update : Bool; streaming_strategy : ?StreamingStrategy }
```


## Type `URL`
``` motoko no-repl
type URL = { original : Text; protocol : Text; port : Nat16; host : { original : Text; array : [Text] }; path : { original : Text; array : [Text] }; queryObj : { original : Text; get : (Text) -> ?Text; trieMap : TrieMap.TrieMap<Text, Text>; keys : [Text] }; anchor : Text }
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

