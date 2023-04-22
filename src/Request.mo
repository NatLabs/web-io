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

    public class Request(_method : Text, _url : Text, options : ?RequestOptions) {
        public let url = URL.URL(_url);
        public let method = _method;

        var _body = Option.get<Blob>(do ? { options!.body! }, "");

        public let headers = Option.get(do ? { options!.headers! }, Headers.Headers());

        /// The caller of the request, if available. If the caller is not available, the **anonymous** principal is used.
        public let caller = Option.get(do ? { options!.shared_msg!.caller }, Principal.fromText("2vxsx-fae"));

        /// The path parameters extrancted from the url.
        /// The path parameters are the parts of the url that are prefixed with a colon when setting a route in the Router.
        /// For example, in the url `/users/:id`, the path parameter is `id`.
        public let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);

        /// Reference to the query parameter map in the URL object.
        public let query_map = url.query_map;

        // body helper functions
        public func blob() : Blob = _body;
        public func text() : ?Text = Text.decodeUtf8(_body);
        public func strict_text() : Text = switch (Text.decodeUtf8(_body)) {
            case (?text) { text };
            case (null) { Debug.trap("Could not decode body as text") };
        };
        public func json() : ?Blob = Option.map(text(), serde_json.fromText);
        public func strict_json() : Blob = switch (text()) {
            case (?text) { serde_json.fromText(text) };
            case (null) { Debug.trap("Could not decode body as text") };
        };

        var cached_form : ?Form.Form = null;

        public func form() : Form.Form {
            switch (cached_form) {
                case (?cached_form) return cached_form;
                case (null) {};
            };

            let parsed_form = switch(Form.parse_with_headers(_body, headers)) {
                case (?form)  form;
                case (null) Form.Form();
            };
            
            cached_form := ?parsed_form;
            parsed_form;
        };
    };

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

        let request = Request(
            method,
            url,
            ?{
                body = ?body;
                headers = ?headers;
                shared_msg = null;
            },
        );

        request;
    };

    public func Get(url : Text) : Request = Request(Method.Get, url, null);
    public func Delete(url : Text) : Request = Request(Method.Delete, url, null);

    let default_options : RequestOptions = {
        headers = null;
        body = null;
        shared_msg = null;
    };

    public func Post(url : Text, body : Blob) : Request = Request(Method.Post, url, ?{ default_options with body = ?body });
    public func Put(url : Text, body : Blob) : Request = Request(Method.Put, url, ?{ default_options with body = ?body });
    public func Patch(url : Text, body : Blob) : Request = Request(Method.Patch, url, ?{ default_options with body = ?body });
};
