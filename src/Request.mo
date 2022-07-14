import Blob "mo:base/Blob";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import serde_json "mo:serde/JSON";
import Headers "Headers";

import T "Types";

module {

    public class Request(_method : Text, _url : Text) {
        public let url = _url;
        public let method = _method;
        public let headers = Headers.Headers();
        public var body = Blob.fromArray([]);
        public let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        public func blob() : Blob = body;
        public func text() : ?Text = Text.decodeUtf8(body);
        public func json() : Blob {
            switch (text()) {
                case (?t) serde_json.fromText(t);
                case (_) Blob.fromArray([]);
            };
        };
    };

    public func fromHttpRequest(httpReq : T.HttpRequest) : Request {
        let { url; method; headers; body } = httpReq;

        let request = Request(method, url);
        request.body := body;

        for ((field, value) in headers.vals()) {
            request.headers.add(field, value);
        };

        request;
    };

    public func get(url : Text) : Request = Request("GET", url);
    public func post(url : Text) : Request = Request("POST", url);
    public func put(url : Text) : Request = Request("PUT", url);
    public func delete(url : Text) : Request = Request("DELETE", url);
    public func patch(url : Text) : Request = Request("PATCH", url);
    
};
