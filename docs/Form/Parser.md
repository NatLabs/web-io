# Form/Parser

## Type `MultiPartFormEntry`
``` motoko no-repl
type MultiPartFormEntry = {#Field : { name : Text; value : Text }; #File : { name : Text; filename : Text; content_type : Text; content : Buffer<Nat8> }}
```


## Function `parse`
``` motoko no-repl
func parse(blob : Blob, opt_boundary : ?Text) : ?List<MultiPartFormEntry>
```


## Function `take_line_text`
``` motoko no-repl
func take_line_text(bytes : PeekableIter<Nat8>) : Text
```


## Function `skip_newline`
``` motoko no-repl
func skip_newline(bytes : PeekableIter<Nat8>)
```


## Function `parse_composition_data`
``` motoko no-repl
func parse_composition_data(bytes : PeekableIter<Nat8>) : (Text, ?Text)
```


## Function `parse_content_type`
``` motoko no-repl
func parse_content_type(bytes : PeekableIter<Nat8>) : Text
```


## Function `read_line`
``` motoko no-repl
func read_line(bytes : PeekableIter<Nat8>, buffer : Buffer<Nat8>)
```


## Function `parse_data`
``` motoko no-repl
func parse_data(bytes : PeekableIter<Nat8>, boundary : Buffer<Nat8>) : Buffer<Nat8>
```


## Function `parse_value`
``` motoko no-repl
func parse_value(bytes : PeekableIter<Nat8>) : Text
```


## Function `parse_file`
``` motoko no-repl
func parse_file(bytes : PeekableIter<Nat8>) : Buffer<Nat8>
```


## Function `parse_form_entry`
``` motoko no-repl
func parse_form_entry(bytes : PeekableIter<Nat8>) : MultiPartFormEntry
```

