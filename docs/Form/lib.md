# Form/lib

## Type `Form`
``` motoko no-repl
type Form = { files : TrieMap<Text, File>; fields : TrieMap<Text, Text> }
```


## Function `Form`
``` motoko no-repl
func Form() : Form
```


## Function `parse_multipart`
``` motoko no-repl
func parse_multipart(data : Blob, boundary : ?Text) : ?Form
```


## Function `parse_with_headers`
``` motoko no-repl
func parse_with_headers(data : Blob, headers : Headers.Headers) : ?Form
```


## Type `FormDataType`
``` motoko no-repl
type FormDataType = {#urlencoding; #multipart : { boundary : ?Text }}
```


## Function `parse`
``` motoko no-repl
func parse(data : Blob, form_type : FormDataType) : ?Form
```


## Function `encode`
``` motoko no-repl
func encode(form : Form, headers : ?Headers.Headers) : Blob
```

