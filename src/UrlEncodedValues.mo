import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import MultiValuedMap "mo:MultiValuedMap";
import serde_urlencoded "mo:serde/UrlEncoded";

import File "File";

module {
    public class UrlEncodedValues() {
        let map = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        public let {
            put;
            remove;
            delete;
            entries;
            get;
            // arrays will be saved as texts with their keys being:
            // users[0], users[1]...
        } = map;

        public func deserialize() : Blob {
            let text = toText();
            serde_urlencoded.fromText(text);
        };

        public func toText(): Text{
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
    };

    // Decodes an encoded URL string and returns a `MultiValueMap` with the stored data
    func parseURLEncodedPairs(encoded_string : Text) : Iter.Iter<(Text, Text)> {
        Iter.map<Text, (Text, Text)>(
            Text.tokens(encoded_string, #text("&")),
            func(encoded_pair : Text) : (Text, Text) {
                let pair : [Text] = Iter.toArray(Text.split(encoded_pair, #char '='));

                if (pair.size() != 2) {
                    Debug.print("Invalid pair: " # encoded_pair);
                };

                (pair[0], pair[1]);
            },
        );
    };

    public func fromText(encodedText : Text) : UrlEncodedValues {
        let encoded_values_obj = UrlEncodedValues();
        if (encodedText.size() > 0){
            let blob = serde_urlencoded.fromText(encodedText);

            for ((key, value) in parseURLEncodedPairs(encodedText)) {
                encoded_values_obj.put(key, value);
            };
        };

        encoded_values_obj;
    };

    public func serialize(blob : Blob, keys : [Text]) : UrlEncodedValues {
        let text = serde_urlencoded.toText(blob, keys);
        fromText(text); 
    };

    // public func toText() : Text {

    // };

    // public func toMotoko() : Blob {

    // };
};
