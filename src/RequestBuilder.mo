// @testmode wasi
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

import { JSON } "mo:serde";
import { Method; Status } "mo:http/Http";
import Base64 "mo:encoding/Base64";


import URL "URL";
import Request "Request";
import Response "Response";
import Form "Form";
import File "File";
import Headers "Headers";
import T "Types";

module {

    type File = File.File;

    public type MutableInternalState = {
        var url : URL.URL;
        var method : Text;
        var headers : Headers.Headers;
        var caller : Principal;
        var transform : ?T.TransformContext;
        var body : Blob;
        var max_redirects : Nat;
        var form : Form.Form;
        var cycles : Nat;
        var max_response_bytes : Nat64;
    };

    public type InternalState = {
        url: URL.URL;
        method: Text;
        headers: Headers.Headers;
        caller: Principal;
        transform: ?T.TransformContext;
        body: Blob;
        max_redirects: Nat;
        form: Form.Form;
        cycles: Nat;
        max_response_bytes: Nat64;
    };

    public type RequestBuilderChainingInterface<Builder> = {
        add_query : (Text, Text) -> Builder;
        auth : (Text, Text) -> Builder;
        bearer_token : Text -> Builder;
        blob : Blob -> Builder;
        caller : Principal -> Builder;
        cookie : (Text, Text) -> Builder;
        cycles : Nat -> Builder;
        file : (Text, File) -> Builder;
        files : [(Text, File)] -> Builder;
        form_field : (Text, Text) -> Builder;
        form_fields : [(Text, Text)] -> Builder;
        header : (Text, Text) -> Builder;
        headers : [T.HeaderField] -> Builder;
        html : Text -> Builder;
        json : (Blob, [Text]) -> Builder;
        max_bytes : Nat64 -> Builder;
        max_redirects : Nat -> Builder;
        method : Text -> Builder;
        queries : [(Text, Text)] -> Builder;
        text : Text -> Builder;
        transform : ?T.TransformContext -> Builder;
    };
    
    public type RequestBuilderInterface<RequestBuilderClass> = RequestBuilderChainingInterface<RequestBuilderClass> and  {
        build : () -> Request.Request;
        build_canister_http : () -> T.CanisterHttpRequest;
        build_http : () -> T.HttpRequest;
    };

    /// A request builder for making HTTP requests.
    ///
    /// The request builder is used to construct a request, which can then be
    /// sent using the `send_request()` method.
    public class RequestBuilder(url_text: Text) = self {
        
        let KB : Nat64 = 1024;

        let state : MutableInternalState = {
            var url = URL.URL(url_text);
            var method = "";
            var headers = Headers.Headers();
            var caller = Principal.fromText("2vxsx-fae");
            var transform : ?T.TransformContext = null;
            var body : Blob = "";
            var max_redirects = 5;
            var form = Form.Form();
            var cycles = 1_000_000_000;
            var max_response_bytes = KB * 10;
        };

        /// Returns the current state of the request builder.
        public func get_state(): InternalState = { 
            url = state.url;
            method = state.method;
            headers = state.headers;
            caller = state.caller;
            transform = state.transform;
            body = state.body;
            max_redirects = state.max_redirects;
            form = state.form;
            cycles = state.cycles;
            max_response_bytes = state.max_response_bytes;
        };

        public func _get_mut_state() : MutableInternalState = state;

        // Set default headers
        state.headers.add("Host", state.url.host # ":" # debug_show(state.url.port));

        /// Adds a query parameter to the request.
        public func add_query(key: Text, val : Text) : RequestBuilder {
            state.url.query_map.put(key, val);
            self
        };

        /// Adds multiple query parameters to the request.
        public func queries(entries : [(Text, Text)]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                state.url.query_map.put(key, val);
            };

            self
        };

        /// Sets the request method.
        public func method(text : Text) : RequestBuilder {
            state.method := text;
            self;
        };

        /// Adds a header field to the request.
        public func header(key : Text, val : Text) : RequestBuilder {
            state.headers.add(key, val);
            self;
        };

        /// Adds multiple header fields to the request.
        public func headers(entries : [T.HeaderField]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                state.headers.add(key, val);
            };

            self;
        };

        /// Sets the maximum bytes that can be returned in the response.
        public func max_bytes(n : Nat64) : RequestBuilder {
            state.max_response_bytes := n;
            self;
        };

        /// Sets the maximum amount of cycles that can be spent on the request.
        public func cycles(n: Nat) : RequestBuilder {
            state.cycles := n;
            self;
        };

        /// Sets the caller that initiated the request.
        public func caller(p : Principal) : RequestBuilder {
            state.caller := p;
            self;
        };

        /// Sets the request body to the given blob.
        public func blob(blob : Blob) : RequestBuilder {
            state.headers.put("Content-Type", "application/octet-stream");
            state.body := blob;
            self;
        };

        /// Sets the request body to the given text.
        public func text(text : Text) : RequestBuilder {
            state.headers.put("Content-Type", "text/plain");
            state.body := Text.encodeUtf8(text);
            self;
        };

        /// Sets the request body to the given JSON blob.
        public func json(candid : Blob, keys : [Text]) : RequestBuilder {
            state.headers.put("Content-Type", "application/json");
            state.body := Text.encodeUtf8(JSON.toText(candid, keys, null));
            self;
        };

        /// Sets the request body to the given HTML text.
        public func html(html : Text) : RequestBuilder {
            state.headers.put("Content-Type", "text/html");
            state.body := Text.encodeUtf8(html);
            self;
        };

        /// Adds a form field to the request.
        public func form_field(key : Text, val : Text) : RequestBuilder {
            state.form.fields.put(key, val);
            self;
        };

        /// Adds multiple form fields to the request.
        public func form_fields(entries : [(Text, Text)]) : RequestBuilder {
            for ((key, val) in entries.vals()) {
                state.form.fields.put(key, val);
            };

            self;
        };

        /// Adds a file to the request.
        public func file(key : Text, File : File.File) : RequestBuilder {
            state.form.files.put(key, File);
            self;
        };

        /// Adds multiple files to the request.
        public func files(entries : [(Text, File.File)]) : RequestBuilder {
            for ((key, file) in entries.vals()) {
                state.form.files.put(key, file);
            };

            self;
        };

        public func transform(tc : ?T.TransformContext) : RequestBuilder {
            state.transform := tc;
            self;
        };

        /// Sets the 'Authorization' header field using Basic Auth.
        public func auth(username : Text, password : Text) : RequestBuilder {
            let text = username # ":" # password;
            let blob = Text.encodeUtf8(text);
            let encoded = Base64.StdEncoding.encode(Blob.toArray(blob));

            switch (Text.decodeUtf8(Blob.fromArray(encoded))) {
                case (?text) state.headers.put("Authorization", "Basic " # text);
                case null Debug.trap("Failed to decode base64 in outcall auth");
            };

            self;
        };

        /// Sets the 'Authorization' header field with the given Bearer token.
        public func bearer_token(token : Text) : RequestBuilder {
            state.headers.put("Authorization", "Bearer " # token);
            self;
        };

        /// Sets the 'Cookie' header field with the given name and value.
        public func cookie(name : Text, value : Text) : RequestBuilder {
            state.headers.put("Cookie", name # "=" # value);
            self;
        };

        func resolve_body() : Blob {
            let form_has_entries = state.form.fields.size() > 0 or state.form.files.size() > 0;
            let body_is_filled = state.body.size() > 0;

            if (body_is_filled and form_has_entries) {
                Debug.trap("Cannot custom payload and form data at the same time");
            };
            
            if ((body_is_filled or form_has_entries) and state.method == Method.Get or state.method == Method.Head){
                Debug.trap("Cannot have body with GET or HEAD methods");
            };

            if (form_has_entries) {
                return Form.encode(state.form, ?state.headers);
            };

            state.body
        };

        /// Returns a Request object with helper functions for accessing the response data.
        public func build() : Request.Request {
            Request.Request({
                method = state.method;
                url = state.url;
                headers = state.headers;
                body = resolve_body();
                caller = ?state.caller;
                params = null;
            })
        };

        /// Builds a `HttpRequest` record that is returned in the `http_request` and `http_request_update` functions.
        public func build_http() : T.HttpRequest {
            {
                url = state.url.text();
                method = state.method;
                body = resolve_body();
                headers = Headers.toArray(state.headers);
            };
        };

        /// Builds a `CanisterHttpRequest` record that is returned after making an outcall.
        public func build_canister_http() : T.CanisterHttpRequest = {
            url = state.url.text();
            max_response_bytes = ?state.max_response_bytes;
            body = ?Blob.toArray(resolve_body());
            transform = state.transform;
            headers = Iter.toArray(
                Iter.map<T.HeaderField, T.HttpHeader>(
                    state.headers.entries(),
                    func((key, val) : T.HeaderField) : T.HttpHeader = {
                        name = key;
                        value = val;
                    },
                )
            );
            method = if (state.method == Method.Get) { #get } 
                else if (state.method == Method.Post) { #post } 
                else if (state.method == Method.Head) { #head } 
                else Debug.trap("Unsupported method '" # state.method # "' for canister http request");
        };
    };
};
