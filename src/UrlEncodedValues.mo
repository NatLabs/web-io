import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import MultiValuedMap "mo:MultiValuedMap";

import File "File";

module {
    public class UrlEncodedValues(encodedText : Text) {
        public let {
            put;
            remove;
            delete;
            entries;
            // arrays will be saved as texts with their keys being:
            // users[0], users[1]...
        } = TrieMap.TrieMap<Text, Text>();

    };

    public func fromEncodedText(encodedText : Text) : UrlEncodedValues {

    };

    public func fromMotoko(blob : Blob, keys : [Text]) : UrlEncodedValues {

    };

    public func toText() : Text {

    };

    public func toMotoko() : Blob {

    };
};
