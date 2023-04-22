/// A builder for Http Response objects and records

import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Blob "mo:base/Blob";
import Nat16 "mo:base/Nat16";

import serde_json "mo:serde/JSON";
import Mo "mo:moh";

import Headers "Headers";
import Response "Response";
import T "Types";

module {

    /// A builder for Http Response objects and records
    ///
    /// ### Current Limitations
    /// - Unable to set custom token for the streaming strategy.
    ///   Users have to use the default `StreamingToken` type which consists of a key and a value.
    public class ResponseBuilder() = self {
        var _status_code : Nat16 = 200;
        var _update = false;
        var _body : Blob = "";
        let _headers = Headers.Headers();
        var _streaming_strategy : ?T.StreamingStrategy = null;
        var is_ctype_set = false;

        /// Sets the status code of the response.
        public func status(code : Nat16) : ResponseBuilder {
            _status_code := code;
            self;
        };

        /// Sets the `update` flag of the response.
        /// If true, the response will be resent to the `http_request_update()` function in the canister.
        public func update(val : Bool) : ResponseBuilder {
            _update := val;
            self;
        };

        /// Adds a field to the response headers.
        public func header(key : Text, value : Text) : ResponseBuilder {
            if (Mo.Text.toLowercase(key) == "content-type") {
                is_ctype_set := true;
            };
            _headers.add(key, value);
            self;
        };

        /// Adds multiple fields to the response headers.
        public func headers(entries : [T.HeaderField]) : ResponseBuilder {
            for ((key, val) in entries.vals()) {
                if (Mo.Text.toLowercase(key) == "content-type") {
                    is_ctype_set := true;
                };
                _headers.add(key, val);
            };
            self;
        };

        /// Sets the response body to the given blob.
        public func blob(blob : Blob) : ResponseBuilder {
            if (not is_ctype_set) {
                _headers.put("Content-Type", "application/octet-stream");
            };
            _body := blob;
            self;
        };

        /// Sets the response body to the given text.
        public func text(text : Text) : ResponseBuilder {
            if (not is_ctype_set) {
                _headers.put("Content-Type", "text/plain");
            };
            _body := Text.encodeUtf8(text);
            self;
        };

        /// Sets the response body to the given JSON blob.
        public func json(json : Blob, keys : [Text]) : ResponseBuilder {
            if (not is_ctype_set) {
                _headers.put("Content-Type", "application/json");
            };
            _body := Text.encodeUtf8(serde_json.toText(json, keys));
            self;
        };

        /// Sets the response body to the given HTML text.
        public func html(html : Text) : ResponseBuilder {
            if (not is_ctype_set) { 
                _headers.put("Content-Type", "text/html") 
            };
            _body := Text.encodeUtf8(html);
            self;
        };

        /// Sets the canister's streaming strategy for the response.
        /// The `callback` will be called when the client requests the next chunk of the response.
        /// The `init_token` is an optional token that will be passed to the `callback` on the first call.
        /// If `init_token` is `null`, the `callback` will not be called.
        public func streaming(
            callback : T.StreamingCallback,
            init_token : ?T.StreamingToken,
        ) : ResponseBuilder {

            _streaming_strategy := switch (init_token) {
                case (?token) ?(#Callback { callback; token });
                case (null) null;
            };

            self;
        };

        /// Sets the `url` to redirect the client to.
        public func redirect(url : Text) : ResponseBuilder {
            _headers.put("Location", url);
            self;
        };

        /// Returns a `Response` object.
        public func build() : Response.Response {
            Response.Response(
                _status_code,
                _body,
                ?{
                    headers = ?_headers;
                    update = _update;
                    streaming_strategy = _streaming_strategy;
                },
            );
        };

        /// Returns a `HttpResponse` record.
        public func build_http() : T.HttpResponse {
            {
                status_code = _status_code;
                headers = Headers.toArray(_headers);
                body = _body;
                update = ?_update;
                streaming_strategy = _streaming_strategy;
            };
        };

        public func build_canister_http() : T.CanisterHttpResponse {
            {
                status = Nat16.toNat(_status_code);
                body = Blob.toArray(_body);
                headers = Iter.toArray(
                    Iter.map<T.HeaderField, T.HttpHeader>(
                        _headers.entries(),
                        func((key, val) : T.HeaderField) : T.HttpHeader = {
                            name = key;
                            value = val;
                        },
                    )
                );
            };
        };
    };

};
