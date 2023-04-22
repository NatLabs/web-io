# Headers
This Headers class represents the key-value pairs in an HTTP header.

The keys should be in canonical form as defined by the HTTP standard.

The format is says the first character should be uppercase and all
the first characters after a hyphen, '-', should also be uppercase.
(eg. "Content-Type")

## `class Headers`


### Function `size`
``` motoko no-repl
func size() : Nat
```



### Function `put`
``` motoko no-repl
func put(key : Text, value : Text)
```

Ensures that there is only one value associated with the key


### Function `add`
``` motoko no-repl
func add(key : Text, value : Text)
```

Appends a value to the values associated with the given field


### Function `remove`
``` motoko no-repl
func remove(key : Text) : ?[Text]
```

Removes all the values associated with the given key


### Function `contains`
``` motoko no-repl
func contains(key : Text) : Bool
```



### Function `get`
``` motoko no-repl
func get(key : Text) : ?Text
```

Retrieves the most recent value associated with the header field


### Function `getAll`
``` motoko no-repl
func getAll(key : Text) : ?[Text]
```

Retrieves all the values associated with the header field


### Function `keys`
``` motoko no-repl
func keys() : Iter.Iter<Text>
```

Returns an iterator of all the fields-keys in the header


### Function `entries`
``` motoko no-repl
func entries() : Iter.Iter<(Text, Text)>
```

Returns an iterator of all the entries in the header with
multi-valued fields seperated by commas.
(eg. `("Accept", "text/plain, text/html")`)


### Function `toArray`
``` motoko no-repl
func toArray() : [(Text, Text)]
```

Returns an array of all the entries in the header with
multi-valued fields seperated by commas.
(eg. `("Accept", "text/plain, text/html")`)

## Function `formatKey`
``` motoko no-repl
func formatKey(field_key : Text) : Text
```

Format header field-key to the canonical format. (eg. "Content-Disposition")

Returns the original text is it contains a space or any invalid characters

## Function `fromArray`
``` motoko no-repl
func fromArray(headerEntries : [HeaderField]) : Headers
```

Create a `Headers` instance by calling this constructor and passing an array of key-value tuple pairs

## Function `toArray`
``` motoko no-repl
func toArray(headers : Headers) : [HeaderField]
```

