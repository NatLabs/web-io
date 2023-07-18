/// This Headers class represents the key-value pairs in an HTTP header.
///
/// The keys should be in canonical form as defined by the HTTP standard.
///
/// The format is says the first character should be uppercase and all
/// the first characters after a hyphen, '-', should also be uppercase.
/// (eg. "Content-Type")

import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import Mo "mo:moh";

import ArrayMap "ArrayMap";
import T "Types";

module {
    type HeaderField = T.HeaderField;

    public class Headers() {
        let map = ArrayMap.ArrayMap<Text, Text>(Text.equal, Text.hash);

        public func size() : Nat = map.size();

        /// Ensures that there is only one value associated with the key
        public func put(key : Text, value : Text) {
            let headerKey = formatKey(key);
            map.put(headerKey, value);
        };

        /// Appends a value to the values associated with the given field
        public func add(key : Text, value : Text) {
            let headerKey = formatKey(key);
            map.add(headerKey, value);
        };

        /// Removes all the values associated with the given key
        public func remove(key : Text) : ?[Text] {
            let headerKey = formatKey(key);
            map.remove(headerKey);
        };

        public func contains(key : Text) : Bool {
            let headerKey = formatKey(key);
            map.contains(key);
        };

        /// Retrieves the most recent value associated with the header field
        public func get(key : Text) : ?Text {
            let headerKey = formatKey(key);
            map.getBack(headerKey);
        };

        /// Retrieves all the values associated with the header field
        public func getAll(key : Text) : ?[Text] {
            let headerKey = formatKey(key);
            map.get(headerKey);
        };

        /// Returns an iterator of all the fields-keys in the header
        public func keys() : Iter.Iter<Text> {
            map.keys();
        };

        /// Returns an iterator of all the entries in the header with
        /// multi-valued fields seperated by commas.
        /// (eg. `("Accept", "text/plain, text/html")`)
        public func entries() : Iter.Iter<(Text, Text)> {
            Iter.map<(Text, [Text]), (Text, Text)>(
                map.entries(),
                func((key, values) : (Text, [Text])) : (Text, Text) {
                    (key, Text.join(", ", values.vals()));
                },
            );
        };

        /// Returns an array of all the entries in the header with
        /// multi-valued fields seperated by commas.
        /// (eg. `("Accept", "text/plain, text/html")`)
        public func toArray() : [(Text, Text)] {
            Iter.toArray(entries());
        };
    };

    /// Format header field-key to the canonical format. (eg. "Content-Disposition")
    ///
    /// Returns the original text is it contains a space or any invalid characters
    public func formatKey(field_key : Text) : Text {
        let dashed = Text.replace(field_key, #char ' ', "-");
        let words = Text.tokens(dashed, #char '-');

        let capitalized = Iter.map<Text, Text>(
            words,
            func(word : Text) : Text {
                Mo.Text.capitalize(word);
            },
        );

        Text.join("-", capitalized);
    };

    /// Create a `Headers` instance by calling this constructor and passing an array of key-value tuple pairs
    public func fromArray(headerEntries : [HeaderField]) : Headers {
        let header = Headers();

        for ((field, value) in headerEntries.vals()) {
            header.add(field, value);
        };

        header;
    };

    public func toArray(headers : Headers) : [HeaderField] {
        let entries = headers.entries();
        Array.tabulate(
            headers.size(),
            func(_ : Nat) : HeaderField = switch (entries.next()) {
                case (?entry) { entry };
                case null { Debug.trap("Headers.toArray: unexpected null") };
            },
        );
    };
};
