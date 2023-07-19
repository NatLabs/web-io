# Utils

## Module `BufferModule`

``` motoko no-repl
module BufferModule
```


### Function `iterSlice`
``` motoko no-repl
func iterSlice<A>(buffer : Buffer.Buffer<A>, start : Nat, end : Nat) : Iter.Iter<A>
```


## Module `ListModule`

``` motoko no-repl
module ListModule
```


### Function `isPrefixOf`
``` motoko no-repl
func isPrefixOf<A>(prefix : List<A>, list : List<A>, eq : (A, A) -> Bool) : Bool
```

