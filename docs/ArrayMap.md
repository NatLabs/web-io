# ArrayMap

## `class ArrayMap<K, V>`


### Value `size`
``` motoko no-repl
let size
```



### Value `keys`
``` motoko no-repl
let keys
```



### Function `put`
``` motoko no-repl
func put(key : K, value : V)
```

Associates the key with the given value in the map.
Overwrites any existing values previously associated with the key


### Function `putAll`
``` motoko no-repl
func putAll(key : K, values : [V]) : ()
```

Associates the key with the given values in the map.
These new values overwrite any previous values.


### Function `add`
``` motoko no-repl
func add(key : K, value : V)
```

Adds a value to the end of the list associated with the key


### Function `addFront`
``` motoko no-repl
func addFront(key : K, value : V)
```

Adds the value to the beginning of the list for the associated key


### Function `addAll`
``` motoko no-repl
func addAll(key : K, values : [V])
```

Appends all the given `values` to the existing values associated with the given key


### Function `getFront`
``` motoko no-repl
func getFront(key : K) : ?V
```

Retrieves the first value associated with the key


### Function `getBack`
``` motoko no-repl
func getBack(key : K) : ?V
```

Retrieves the last value associated with the key


### Function `getAt`
``` motoko no-repl
func getAt(key : K, index : Nat) : V
```

Retrieves the value at the given index associated with the key


### Function `get`
``` motoko no-repl
func get(key : K) : ?[V]
```

Retrieves all the values associated with the given key


### Function `vals`
``` motoko no-repl
func vals() : Iter.Iter<[V]>
```



### Function `contains`
``` motoko no-repl
func contains(key : K) : Bool
```



### Function `sizeOf`
``` motoko no-repl
func sizeOf(key : K) : Nat
```

Returns the number of values associated with the given key


### Function `entries`
``` motoko no-repl
func entries() : Iter.Iter<(K, [V])>
```

Returns all the entries in the map as a tuple of
key and values array


### Function `flattenedEntries`
``` motoko no-repl
func flattenedEntries() : Iter.Iter<(K, V)>
```

Returns all the entries in the map but instead of
an iterator with a key and a values array (`(K, [V])`), it returns
every value in the map in a tuple with its associated key (`(K, V)`).


### Function `singleValueEntries`
``` motoko no-repl
func singleValueEntries() : Iter.Iter<(K, V)>
```

Returns an iterator with key-value tuple pairs with every key in
the map and its first value


### Function `remove`
``` motoko no-repl
func remove(key : K) : ?[V]
```

Removes all the values associated with the specified key
and returns them

If the key is not found, the function returns null


### Function `clear`
``` motoko no-repl
func clear()
```

Removes all the key-value pairs in the map

## Function `fromEntries`
``` motoko no-repl
func fromEntries<K, V>(entries : [(K, [V])], isKeyEq : (K, K) -> Bool, keyHash : K -> Hash.Hash) : ArrayMap<K, V>
```


## Function `arrayToBuffer`
``` motoko no-repl
func arrayToBuffer<T>(arr : [T]) : Buffer.Buffer<T>
```

