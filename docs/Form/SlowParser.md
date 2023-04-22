# Form/SlowParser

## Type `MultiPartFormEntry`
``` motoko no-repl
type MultiPartFormEntry = {#Field : { name : Text; value : Text }; #File : { name : Text; filename : Text; content_type : Text; content : Iter<Nat8> }}
```


## Function `parse`
``` motoko no-repl
func parse(blob : Blob, opt_boundary : ?Text) : ?List<MultiPartFormEntry>
```


## Function `ignoreSpace`
``` motoko no-repl
func ignoreSpace<A>(parser : P.Parser<Nat8, A>) : P.Parser<Nat8, A>
```


## Function `parseContentDisposition`
``` motoko no-repl
func parseContentDisposition() : Parser<Nat8, (Text, Text)>
```


## Function `parseContentType`
``` motoko no-repl
func parseContentType() : Parser<Nat8, Text>
```


## Function `parseFile`
``` motoko no-repl
func parseFile(boundary : List<Nat8>) : Parser<Nat8, (((Text, Text), Text), Iter<Nat8>)>
```


## Function `fileParser`
``` motoko no-repl
func fileParser(boundary : List<Nat8>) : Parser<Nat8, MultiPartFormEntry>
```


## Function `parseValue`
``` motoko no-repl
func parseValue(boundary : List<Nat8>) : Parser<Nat8, ((Text, Text), Text)>
```


## Function `valueParser`
``` motoko no-repl
func valueParser(boundary : List<Nat8>) : Parser<Nat8, MultiPartFormEntry>
```


## Function `parseFormData`
``` motoko no-repl
func parseFormData(boundary : List<Nat8>) : Parser<Nat8, List<MultiPartFormEntry>>
```


## Function `consIf`
``` motoko no-repl
func consIf<T, A>(parserA : Parser<T, A>, parserAs : Parser<T, List<A>>, cond : (A, List<A>) -> Bool) : Parser<T, List<A>>
```


## Function `parseByteLine`
``` motoko no-repl
func parseByteLine(boundary : List<Nat8>) : Parser<Nat8, List<Nat8>>
```


## Function `parseByteLines`
``` motoko no-repl
func parseByteLines(boundary : List<Nat8>) : Parser<Nat8, Iter<Nat8>>
```


## Function `parseLine`
``` motoko no-repl
func parseLine(boundary : List<Nat8>) : Parser<Nat8, Text>
```


## Function `parseLines`
``` motoko no-repl
func parseLines(boundary : List<Nat8>) : Parser<Nat8, Text>
```


## Value `Byte`
``` motoko no-repl
let Byte
```


## Value `Bytes`
``` motoko no-repl
let Bytes
```

