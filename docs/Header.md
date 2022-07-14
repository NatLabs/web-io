# Header

## `class Header`


### Function `enteries`
``` motoko no-repl
func enteries() : Iter.Iter<(Text, Text)>
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
This Header class represents the key-value pairs in an HTTP header.
The keys should be in canonical form as defined by the HTTP standard.

The format is says the first character should be uppercase and all
the first characters after a hyphen, '-', should also be uppercase.
(eg. "Content-Type")

## Function `fromArray`
``` motoko no-repl
func fromArray(headerEntries : [HeaderField]) : Header
```

Create a `Header` instance by calling this constructor and passing an array of key-value tuple pairs
