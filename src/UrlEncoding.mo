import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import serde_urlencoded "mo:serde/UrlEncoded";

import File "File";

module {
    public type UrlEncoding = TrieMap.TrieMap<Text, Text>;

    func split(encoded_string : Text) : Iter.Iter<?(Text, Text)> {
        Iter.map<Text, ?(Text, Text)>(
            Text.tokens(encoded_string, #text("&")),
            func(encoded_pair : Text) : ?(Text, Text) {
                let pair : [Text] = Iter.toArray(Text.split(encoded_pair, #char '='));

                if (pair.size() != 2) {
                    return null;
                };

                ?(pair[0], pair[1]);
            },
        );
    };

    public func fromText(encodedText : Text) : ?UrlEncoding {
        let map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
        
        for (opt_entry in split(encodedText)) {
            let ?(key, value) = opt_entry else return null;
            map.put(key, value);
        };

        ?map;
    };

    public func toText(map: UrlEncoding) : Text {
        Text.join(
            "&",
            Iter.map<(Text, Text), Text>(
                map.entries(),
                func ((key, val)) {
                    key # "=" # val;
                },
            ),
        )
    };

    public func serialize(blob : Blob, keys : [Text]) : ?UrlEncoding {
        let text = serde_urlencoded.toText(blob, keys);
        fromText(text); 
    };
    
    public func deserialize(map: UrlEncoding): Blob {
        let text = toText(map);
        serde_urlencoded.fromText(text);
    };

};