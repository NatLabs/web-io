/// The `Response` class is a read-only representation of a http response with utility methods for accessing the response data.
/// Response objects should be instantiated using the `ResponseBuilder` or the `Response.fromCanisterHttp` and `Response.fromHttpResponse` methods.

import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Nat16 "mo:base/Nat16";

import { JSON } "mo:serde";

import Headers "Headers";
import T "Types";

module {

    public type ResponseOptions = {
        upgrade : Bool;
        streaming_strategy : ?T.StreamingStrategy;
        headers : ?Headers.Headers;
    };

    public type ResponseInitData = {
        status_code : Nat16;
        body : Blob;
        upgrade : Bool;
        streaming_strategy : ?T.StreamingStrategy;
        headers : ?Headers.Headers;
    };

    public class Response(init: ResponseInitData) {
        public let status_code = init.status_code;
        public let upgrade = Option.get(do ? { init.upgrade }, false);
        public let headers = Option.get(do ? { init.headers! }, Headers.Headers());
        public let streaming_strategy = do ? { init.streaming_strategy!};

        var _body = init.body;

        public func blob() : Blob = _body;
        public func text() : ?Text = Text.decodeUtf8(_body);
        public func strict_text() : Text = switch (Text.decodeUtf8(_body)) {
            case (?t) { t };
            case (null) { Debug.trap("Failed to decode response body as text") };
        };

        public func json() : ?Blob {
            let ?t = text() else return null;
            ?JSON.fromText(t, null);
        };

        public func strict_json() : Blob {
            switch (text(), ) {
                case (?t) { JSON.fromText(t, null) };
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
     
        let initData : ResponseInitData = {
            status_code = Nat16.fromNat(res.status);
            body = Blob.fromArray(res.body);
            upgrade = false;
            streaming_strategy = null;
            headers = ?headers;
        };

        Response(initData);
    };

    public func fromHttpResponse(res : T.HttpResponse) : Response {
        let headers = Headers.Headers();

        for ((key, val) in res.headers.vals()) {
            headers.add(key, val);
        };

        let initData : ResponseInitData = {
            status_code = res.status_code;
            body = res.body;
            upgrade = false;
            streaming_strategy = null;
            headers = ?headers;
        };

        Response(initData);
    };

    public func toHttpResponse(res : Response) : T.HttpResponse {
        {
            status_code = res.status_code;
            headers = Iter.toArray(res.headers.entries());
            body = res.blob();
            upgrade = ?res.upgrade;
            streaming_strategy = res.streaming_strategy;
        };
    };
};
