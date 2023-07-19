# UrlEncoding

## Type `UrlEncoding`
``` motoko no-repl
type UrlEncoding = TrieMap.TrieMap<Text, Text>
```

A map for storing URL Encoded data as key-value pairs

## Function `parse`
``` motoko no-repl
func parse(encodedText : Text) : ?UrlEncoding
```

Parses a URL Encoded string into a map
Returns `null` if the Text is not valid

## Function `fromText`
``` motoko no-repl
func fromText(t : Text) : UrlEncoding
```

Parses a URL Encoded `Text` into a map
Traps if the `Text` is not valid
Consider using `parse` instead

## Function `toText`
``` motoko no-repl
func toText(map : UrlEncoding) : Text
```

Converts a map into a URL Encoded string

## Function `deserialize`
``` motoko no-repl
func deserialize(blob : Blob, keys : [Text]) : UrlEncoding
```


## Function `serialize`
``` motoko no-repl
func serialize(map : UrlEncoding) : Blob
```

