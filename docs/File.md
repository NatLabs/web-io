# File
Module for representing files

## Type `FileData`
``` motoko no-repl
type FileData = { filename : Text; content_type : Text; mtime : ?Time.Time }
```

Required arguements for initializing a `File`

## `class File`


### Value `filename`
``` motoko no-repl
let filename
```

The name and extention of the file.


### Value `content_type`
``` motoko no-repl
let content_type
```

The MIME type of the file


### Value `mtime`
``` motoko no-repl
let mtime
```

The UTC timestamp of when the file was last modified


### Value `buffer`
``` motoko no-repl
let buffer
```



### Function `size`
``` motoko no-repl
func size() : Nat
```

The number of bytes of the file


### Function `content`
``` motoko no-repl
func content() : Blob
```

Get's the file's data as a Blob


### Function `append`
``` motoko no-repl
func append(blob : Blob)
```

Append a `Blob` of data to the `File`


### Function `slice`
``` motoko no-repl
func slice(start : Nat, end : Nat) : Blob
```

Returns a slice of the File's data
specified by the `start` and `end` indices
The File class holds the data and metadata of a single file. 
The File class provides the minimum interface required for a file. 
Additional functions are added to the module for manipulating chunked data.

## Function `fromBytes`
``` motoko no-repl
func fromBytes(fileData : FileData, bytes : Iter<Nat8>) : File
```

Creates a file from an byte iterator

## Function `fromChunks`
``` motoko no-repl
func fromChunks(fileData : FileData, chunks : [Blob]) : File
```

Creates a file from an array of consecutive blob slices of the file's dataa

## Function `getChunk`
``` motoko no-repl
func getChunk(file : File, chunkSize : Nat, chunkIndex : Nat) : Blob
```

Retrieves a slice of the File's data with the start and end
calculated from the `chunkSize` and `chunkIndex`

## Function `chunks`
``` motoko no-repl
func chunks(file : File, chunkSize : Nat) : [Blob]
```

Returns an Array of Blob slices which are less than or equal to the
given `chunkSize` and contain consecutive slices of the File's data.

## Function `toText`
``` motoko no-repl
func toText(file : File) : ?Text
```

Attemps to convert the File's data to `Text`

It returns `null` if the File is not `utf8` encoded
