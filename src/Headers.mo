/// This Headers class represents the key-value pairs in an HTTP header.
/// The keys should be in canonical form as defined by the HTTP standard.
///
/// The format is says the first character should be uppercase and all
/// the first characters after a hyphen, '-', should also be uppercase.
/// (eg. "Content-Type")

import Iter "mo:base/Iter";
import Text "mo:base/Text";

import MultiValuedMap "mo:MultiValuedMap";

import T "Types";

module {
    type HeaderField = T.HeaderField;

    public class Headers() {
        let map = MultiValuedMap.MultiValuedMap<Text, Text>(Text.equal, Text.hash);

        /// Associates a single value with the key and overwrites and previous values
        public func put(key : Text, value : Text) {
            let headerKey = formatKey(key);
            map.put(key, headerKey);
        };

        /// Appends a value to the values associated with the given field
        public func add(key : Text, value : Text) {
            let headerKey = formatKey(key);
            map.add(key, headerKey);
        };

        /// Removes all the values associated with the given key
        public func remove(key : Text) : [Text] {
            let headerKey = formatKey(key);
            map.remove(headerKey);
        };

        /// Retrieves the first value in the header field
        public func get(key : Text) : ?Text {
            let headerKey = formatKey(key);
            map.getFirst(headerKey);
        };

        /// Retrieves all the values associated with the header field
        public func getAll(key : Text) : [Text] {
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
        if (Text.contains(field_key, #char ' ')) {
            return field_key;
        };

        // capitalizeWords(field_key, #char '-');
        field_key;
    };

    /// Create a `Headers` instance by calling this constructor and passing an array of key-value tuple pairs
    public func fromArray(headerEntries : [HeaderField]) : Headers {
        let header = Headers();

        for ((field, value) in headerEntries.vals()) {
            header.add(field, value);
        };

        header;
    };
};
