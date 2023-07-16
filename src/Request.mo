import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

import serde_json "mo:serde/JSON";
import { Method } "mo:http/Http";

import Form "Form";
import Headers "Headers";
import URL "URL";
import UrlEncoding "UrlEncoding";
import T "Types";

module {

    type RequestOptions = {
        headers : ?Headers.Headers;
        body : ?Blob;
        shared_msg : ?T.SharedMessage;
    };

    /// The Request class represents an HTTP request and provides helpful methods
    /// Read-only information about an HTTP request
    /// Use the `RequestBuilder` to create a `Request` object

    public type RequestInitData = {
        method : Text;
        url : URL.URL;
        body : Blob; // #form | #bytes;
        headers : Headers.Headers;
        caller : ?Principal.Principal;
        params : ?TrieMap.TrieMap<Text, Text>;
    };

    public class Request(init : RequestInitData) {
        /// A URL object created from the url sent in the request
        public let url = init.url;

        /// Reference to the query parameter map in the URL object.
        public let query_map = url.query_map;

        /// Function to serialize the query parameters in the URL object to a candid blob.
        public let query_candid = url.query_candid;

        /// Function for converting the query parameters in the URL object to a Text.
        public let query_text = url.query_text;

        /// The HTTP method of the request
        public let method = init.method;

        var _body = init.body;

        /// The headers of the request as a Headers object
        public let headers = init.headers;

        /// The caller of the request, if available. If the caller is not available, the **anonymous** principal is used.
        public let caller = Option.get(init.caller, Principal.fromText("2vxsx-fae"));

        /// The path parameters extrancted from the url.
        /// The path parameters are the parts of the url that are prefixed with a colon when setting a route in the Router.
        /// For example, in the url `/users/:id`, the path parameter is `id`.
        public let params = Option.get(init.params, TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash));

        /// Returns the request body as a Blob
        public func blob() : Blob = _body;

        /// Returns the request body as a Text
        public func text() : ?Text = Text.decodeUtf8(_body);

        /// Returns the request body as a Text, or traps if the body cannot be decoded as text
        public func strict_text() : Text = switch (Text.decodeUtf8(_body)) {
            case (?text) { text };
            case (null) { Debug.trap("Could not decode body as text") };
        };

        /// Returns the request body as a JSON blob, that can be decoded to primitive motoko types using the `from_candid()` global function
        public func json() : ?Blob = Option.map(text(), serde_json.fromText);

        /// Returns the request body as a JSON blob, or traps if the body cannot be decoded as JSON
        public func strict_json() : Blob = switch (text()) {
            case (?text) { serde_json.fromText(text) };
            case (null) { Debug.trap("Could not decode body as text") };
        };

        var cached_form : ?Form.Form = null;

        /// Returns the request body as a Form object
        public func form() : Form.Form {
            switch (cached_form) {
                case (?cached_form) return cached_form;
                case (null) {};
            };

            let parsed_form = switch (Form.parse_with_headers(_body, headers)) {
                case (?form) form;
                case (null) Form.Form();
            };

            cached_form := ?parsed_form;
            parsed_form;
        };
    };

    /// Create a `Request` object from a `HttpRequest` record
    public func fromHttpRequest(httpReq : T.HttpRequest) : Request {
        let {
            method;
            body;
            url = path;
            headers = header_entries;
        } = httpReq;

        let headers = Headers.Headers();

        var host = "";

        for ((field, value) in header_entries.vals()) {
            if (field == "host") {
                host := value;
            };
            headers.put(field, value);
        };

        let url = host # path;

        let request = Request({
            method;
            url = URL.URL(url);
            body;
            headers;
            caller = null;
            params = null;
        });

        request;
    };

};
