import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Blob "mo:base/Blob";

import serdeJson "mo:serde/Json";

import T "Types";

module {
    public class Response() {
        public var status_code : Nat16 = 200;
        public var update = false;
        public var streaming_strategy = null;

        public let headers = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
        var _body = Text.encodeUtf8("");

        public func setBody(body : Blob) {
            _body := body;
        };

        public let body = {
            json = func() : Blob {
                serdeJson.fromText(_body);
            };

            blob = func() : Blob = _body;

            text = func() : Text {
                Text.decodeUtf8(_body);
            };

        };

    };
};
