/// A request builder for making HTTP requests.

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Nat16 "mo:base/Nat16";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Cycles "mo:base/ExperimentalCycles";

import serde_json "mo:serde/JSON";
import { Method; Status } "mo:http/Http";
import Base64 "mo:encoding/Base64";
import fuzzText "mo:fuzz/Text";
import fuzz "mo:fuzz";

import URL "URL";
import Request "Request";
import Response "Response";
import Form "Form";
import File "File";
import Headers "Headers";
import T "Types";

module {

    /// A request builder for making HTTP requests.
    ///
    /// The request builder is used to construct a request, which can then be
    /// sent using the `send_request()` method.
    public class RequestBuilder(url_text: Text) = self {
        var _url = URL.URL(url_text);
        var _method = "";
        var _headers = Headers.Headers();
        var _caller = Principal.fromText("2vxsx-fae");
        var _transform : ?T.TransformContext = null;
        var _body : Blob = "";
        var _follow_redirects = false;
        var _max_redirects = 5;
        var _form = Form.Form();
        var _cycles = 1_000_000_000;

        let seed = Int.abs(Time.now());
        let random_generator = fuzz.createGenerator(seed);
        let randomText = fuzzText.FuzzText(random_generator);

        let KB : Nat64 = 1024;
        var _max_response_bytes = KB * 10;

        // Set default headers
        _headers.add("Host", _url.host # ":" # debug_show(_url.port));

        /// Adds a query parameter to the request.
        public func add_query(key: Text, val : Text) : RequestBuilder {
            _url.query_map.put(key, val);
            self
        };

        /// Adds multiple query parameters to the request.
        public func queries(entries : [(Text, Text)]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                _url.query_map.put(key, val);
            };

            self
        };

        /// Sets the request method.
        public func method(text : Text) : RequestBuilder {
            _method := text;
            self;
        };

        /// Adds a header field to the request.
        public func header(key : Text, val : Text) : RequestBuilder {
            _headers.add(key, val);
            self;
        };

        /// Adds multiple header fields to the request.
        public func headers(entries : [T.HeaderField]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                _headers.add(key, val);
            };

            self;
        };

        /// Sets the maximum bytes that can be returned in the response.
        public func max_bytes(n : Nat64) : RequestBuilder {
            _max_response_bytes := n;
            self;
        };

        /// Sets the maximum amount of cycles that can be spent on the request.
        public func cycles(n: Nat) : RequestBuilder {
            _cycles := n;
            self;
        };

        /// Sets the caller that initiated the request.
        public func caller(p : Principal) : RequestBuilder {
            _caller := p;
            self;
        };

        /// Sets the request body to the given blob.
        public func blob(blob : Blob) : RequestBuilder {
            _headers.put("Content-Type", "application/octet-stream");
            _body := blob;
            self;
        };

        /// Sets the request body to the given text.
        public func text(text : Text) : RequestBuilder {
            _headers.put("Content-Type", "text/plain");
            _body := Text.encodeUtf8(text);
            self;
        };

        /// Sets the request body to the given JSON blob.
        public func json(candid : Blob, keys : [Text]) : RequestBuilder {
            _headers.put("Content-Type", "application/json");
            _body := Text.encodeUtf8(serde_json.toText(candid, keys));
            self;
        };

        /// Sets the request body to the given HTML text.
        public func html(html : Text) : RequestBuilder {
            _headers.put("Content-Type", "text/html");
            _body := Text.encodeUtf8(html);
            self;
        };

        /// Adds a form field to the request.
        public func form_field(key : Text, val : Text) : RequestBuilder {
            _form.fields.put(key, val);
            self;
        };

        /// Adds multiple form fields to the request.
        public func form_fields(entries : [(Text, Text)]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                _form.fields.put(key, val);
            };

            self;
        };

        /// Adds a file to the request.
        public func file(key : Text, File : File.File) : RequestBuilder {
            _form.files.put(key, File);
            self;
        };

        /// Adds multiple files to the request.
        public func files(entries : [(Text, File.File)]) : RequestBuilder {
            for ((key, file) in entries.vals()) {
                _form.files.put(key, file);
            };

            self;
        };

        public func transform(tc : ?T.TransformContext) : RequestBuilder {
            _transform := tc;
            self;
        };

        /// Sets the 'Authorization' header field using Basic Auth.
        public func auth(username : Text, password : Text) : RequestBuilder {
            let text = username # ":" # password;
            let blob = Text.encodeUtf8(text);
            let encoded = Base64.StdEncoding.encode(Blob.toArray(blob));

            switch (Text.decodeUtf8(Blob.fromArray(encoded))) {
                case (?text) _headers.put("Authorization", "Basic " # text);
                case null Debug.trap("Failed to decode base64 in outcall auth");
            };

            self;
        };

        /// Sets the 'Authorization' header field with the given Bearer token.
        public func bearer_token(token : Text) : RequestBuilder {
            _headers.put("Authorization", "Bearer " # token);
            self;
        };

        /// Sets the 'Cookie' header field with the given name and value.
        public func cookie(name : Text, value : Text) : RequestBuilder {
            _headers.put("Cookie", name # "=" # value);
            self;
        };

        /// Give permission to the request to follow redirects.
        public func follow_redirects(follow : Bool) : RequestBuilder {
            _follow_redirects := follow;
            self;
        };

        /// Sets the maximum amount of redirects that can be followed.
        public func max_redirects(max: Nat) : RequestBuilder {
            _max_redirects := max;
            self;
        };

        func resolve_body() : Blob {
            let form_has_entries = _form.fields.size() > 0 or _form.files.size() > 0;
            let body_is_filled = _body.size() > 0;

            if (body_is_filled and form_has_entries) {
                Debug.trap("Cannot custom payload and form data at the same time");
            };
            
            if ((body_is_filled or form_has_entries) and _method == Method.Get or _method == Method.Head){
                Debug.trap("Cannot have body with GET or HEAD methods");
            };

            if (form_has_entries) {
                return Form.encode(_form, ?_headers);
            };

            _body
        };

        /// Returns a Request object with helper functions for accessing the response data.
        public func build() : Request.Request {
            Request.Request({
                method = _method;
                url = _url;
                headers = _headers;
                body = resolve_body();
                caller = ?_caller;
                params = null;
            })
        };

        /// Builds a `HttpRequest` record that is returned in the `http_request` and `http_request_update` functions.
        public func build_http() : T.HttpRequest {
            {
                url = _url.text();
                method = _method;
                body = resolve_body();
                headers = Headers.toArray(_headers);
            };
        };

        /// Builds a `CanisterHttpRequest` record that is returned after making an outcall.
        public func build_canister_http() : T.CanisterHttpRequest = {
            url = _url.text();
            max_response_bytes = ?_max_response_bytes;
            body = ?Blob.toArray(resolve_body());
            transform = _transform;
            headers = Iter.toArray(
                Iter.map<T.HeaderField, T.HttpHeader>(
                    _headers.entries(),
                    func((key, val) : T.HeaderField) : T.HttpHeader = {
                        name = key;
                        value = val;
                    },
                )
            );
            method = if (_method == Method.Get) { #get } 
                else if (_method == Method.Post) { #post } 
                else if (_method == Method.Head) { #head } 
                else Debug.trap("Unsupported method '" # _method # "' for canister http request");
        };

        type Response = Response.Response;

        let REDIRECT_STATUS_CODES : [Nat16] = [
            Status.MovedPermanently,
            Status.Found,
            Status.SeeOther,
            Status.TemporaryRedirect,
            Status.PermanentRedirect,
        ];

        func redirect_request(
            internet_computer : T.ManagementCanister,
            req : T.CanisterHttpRequest,
            first_res : T.CanisterHttpResponse,
        ) : async* [T.RedirectedResponse] {

            let buffer = Buffer.Buffer<T.RedirectedResponse>(2);

            var res = first_res;
            var i = 0;

            label _loop loop {
                if (i >= _max_redirects) break _loop;

                let status = Nat16.fromNat(first_res.status);

                let is_not_redirect = Option.isNull(
                    Array.find<Nat16>(
                        REDIRECT_STATUS_CODES,
                        func(code : Nat16) : Bool = code == status,
                    )
                );

                if (is_not_redirect) break _loop;

                let opt_header = Array.find<T.HttpHeader>(
                    res.headers,
                    func({ name } : T.HttpHeader) : Bool = name == "Location",
                );

                let ?location = opt_header else break _loop;
                let url = location.value;

                res := await internet_computer.http_request({ req with url });

                buffer.add({
                    url;
                    response = res;
                });

                i += 1;
            };

            Buffer.toArray(buffer);
        };

        func _send_request() : async* T.OutcallResponse {
            let internet_computer : T.ManagementCanister = actor ("aaaaa-aa");
            
            let req = build_canister_http();

            Cycles.add(Nat.min(_cycles, Cycles.balance()));
            let res = await internet_computer.http_request(req);

            let redirects = if (_follow_redirects) {
                await* redirect_request(internet_computer, req, res);
            } else {
                [];
            };

            { res with redirects };
        };

        /// Send out the HTTP request and return the response.
        public func send_request() : async* T.OutcallResponse {
            
            if (_method == Method.Post){
                // set idempotency key for this request
                let idempotency_key = random_id();
                _headers.add("Idempotency-Key", idempotency_key);
            };

            await* _send_request();
        };

        func random_id() : Text {
            randomText.randomAlphanumeric(10);
        };

        public func retry() : async* T.OutcallResponse {
            if (_headers.get("Idempotency-Key") == null){
                Debug.trap("This request has not been sent yet. Try calling 'send_request()' first");
            };
            await* _send_request();
        };
    };
};
