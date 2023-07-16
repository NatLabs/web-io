import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import serde_urlencoded "mo:serde/UrlEncoded";
import Mo "mo:moh";

import File "File";

/// This module contains helper functions for data in the URL Encoding format (e.g `key1=value1&key2=value2`)
module {
    /// A map for storing URL Encoded data as key-value pairs
    public type UrlEncoding = TrieMap.TrieMap<Text, Text>;

    func split(encoded_string : Text) : Iter.Iter<?(Text, Text)> {
        Iter.map<Text, ?(Text, Text)>(
            Text.tokens(encoded_string, #text("&")),
            func(encoded_pair : Text) : ?(Text, Text) {
                let pair : [Text] = Iter.toArray(Text.split(encoded_pair, #char '='));

                if (pair.size() != 2) {
                    return null;
                };

                let key = switch (Mo.Text.decodeURL(pair[0])){
                    case (?decoded) decoded;
                    case (_) pair[0];
                };
                
                let value = switch (Mo.Text.decodeURL(pair[1])){
                    case (?decoded) decoded;
                    case (_) pair[1];
                };

                ?(key, value);
            },
        );
    };

    /// Parses a URL Encoded string into a map
    /// Returns `null` if the Text is not valid
    public func parse(encodedText : Text) : ?UrlEncoding {
        let map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
        
        for (opt_entry in split(encodedText)) {
            let ?(key, value) = opt_entry else return null;
            map.put(key, value);
        };

        ?map;
    };

    /// Parses a URL Encoded `Text` into a map
    /// Traps if the `Text` is not valid
    /// Consider using `parse` instead
    public func fromText(t: Text) : UrlEncoding {
        switch(parse(t)){
            case (?map) map;
            case (_) Debug.trap("Failed to parse URL Encoded string");
        };
    };

    /// Converts a map into a URL Encoded string
    public func toText(map: UrlEncoding) : Text {
        Text.join(
            "&",
            Iter.map<(Text, Text), Text>(
                map.entries(),
                func ((key, val)) {
                    Mo.Text.encodeURL(key) # "=" # Mo.Text.encodeURL(val);
                },
            ),
        )
    };

    public func deserialize(blob : Blob, keys : [Text]) : UrlEncoding {
        let text = serde_urlencoded.toText(blob, keys);
        fromText(text); 
    };
    
    public func serialize(map: UrlEncoding): Blob {
        let text = toText(map);
        serde_urlencoded.fromText(text);
    };
};
