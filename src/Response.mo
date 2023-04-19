import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";

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

        public let body = {
            // getter fns for converting body to different types
            blob = func() : Blob = _body;
            text = func() : ?Text = Text.decodeUtf8(_body);
            json = func() : ?Blob {
                Option.map(body.text(), serde_json.fromText);
            };
            bytes = func() : [Nat8] = Blob.toArray(_body);
            buffer = func() : Buffer.Buffer<Nat8> = Buffer.fromArray(body.bytes());
            size = func() : Nat = _body.size();
        };
    };

    public func toHttpResponse(res : Response) : T.HttpResponse {
        {
            status_code = res.status_code;
            headers = Iter.toArray(res.headers.entries());
            body = res.body.blob();
            update = ?res.update;
            streaming_strategy = res.streaming_strategy;
        };
    };
};
