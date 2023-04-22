import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Nat16 "mo:base/Nat16";

import serde_json "mo:serde/JSON";

import Headers "Headers";
import T "Types";

module {

    public type ResponseOptions = {
        update : Bool;
        streaming_strategy : ?T.StreamingStrategy;
        headers : ?Headers.Headers;
    };

    public class Response(_status_code : Nat16, __body: Blob, options : ?ResponseOptions) {
        public let status_code = _status_code;
        public let update = Option.get(do ? { options!.update }, false);
        public let headers = Option.get(do ? { options!.headers! }, Headers.Headers());
        public let streaming_strategy = do ? { options!.streaming_strategy!};

        var _body = __body;

        public func blob() : Blob = _body;
        public func text() : ?Text = Text.decodeUtf8(_body);
        public func strict_text() : Text = switch (Text.decodeUtf8(_body)) {
            case (?t) { t };
            case (null) { Debug.trap("Failed to decode response body as text") };
        };

        public func json() : ?Blob {
            Option.map(text(), serde_json.fromText);
        };
        public func strict_json() : Blob {
            switch (Option.map(text(), serde_json.fromText)) {
                case (?b) { b };
                case (null) { Debug.trap("Failed to decode response body as JSON") };
            };
        };
        public func bytes() : [Nat8] = Blob.toArray(_body);
        public func buffer() : Buffer.Buffer<Nat8> = Buffer.fromArray(bytes());
        public func size() : Nat = _body.size();
    };

    public func fromCanisterHttp(res : T.CanisterHttpResponse) : Response {
        let headers = Headers.Headers();

        for (header in res.headers.vals()) {
            headers.add(header.name, header.value);
        };

        let options = {
            update = false;
            streaming_strategy = null;
            headers = ?headers;
        };

        Response(Nat16.fromNat(res.status), Blob.fromArray(res.body), ?options);
    };

    public func fromHttpResponse(res : T.HttpResponse) : Response {
        let headers = Headers.Headers();

        for ((key, val) in res.headers.vals()) {
            headers.add(key, val);
        };

        let options = {
            update = if (res.update == ?true) true else false;
            streaming_strategy = res.streaming_strategy;
            headers = ?headers;
        };

        Response(res.status_code, res.body, ?options);
    };

    public func toHttpResponse(res : Response) : T.HttpResponse {
        {
            status_code = res.status_code;
            headers = Iter.toArray(res.headers.entries());
            body = res.blob();
            update = ?res.update;
            streaming_strategy = res.streaming_strategy;
        };
    };
};
