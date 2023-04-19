import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Blob "mo:base/Blob";

import serde_json "mo:serde/JSON";

import Headers "Headers";
import Response "Response";
import T "Types";

module {
    public class ResponseBuilder() {
        public var status_code : Nat16 = 200;
        public var update = false;
        public var streaming_strategy : ?T.StreamingStrategy = null;

        public let headers = Headers.Headers();
        var _body = Text.encodeUtf8("");

        public func getBody() : Blob = _body;
    
        public let body = {
            setBlob = func(blob : Blob) {
                headers.put("Content-Type", "application/octet-stream");
                _body := blob;
            };
            setText = func(text : Text) {
                headers.put("Content-Type", "text/plain");
                _body := Text.encodeUtf8(text);
            };
            setJson = func(json : Blob, keys : [Text]) {
                headers.put("Content-Type", "application/json");
                _body := Text.encodeUtf8(serde_json.toText(json, keys));
            };
            setHtml = func(html : Text) {
                headers.put("Content-Type", "text/html");
                _body := Text.encodeUtf8(html);
            };
        };

        public func redirect(url : Text) {
            headers.put("Location", url);
        };
    };

    public func build(builder: ResponseBuilder) : Response.Response {
        Response.Response(
            builder.status_code,
            builder.getBody(),
            ?{
                headers = ?builder.headers;
                update = builder.update;
                streaming_strategy = builder.streaming_strategy;
            }
        )
    };

    public func toHttpResponse(res : ResponseBuilder) : T.HttpResponse {
        {
            status_code = res.status_code;
            headers = Iter.toArray(res.headers.entries());
            body = res.getBody();
            update = ?res.update;
            streaming_strategy = res.streaming_strategy;
        };
    };

};
