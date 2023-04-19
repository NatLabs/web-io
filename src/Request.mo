import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import TrieMap "mo:base/TrieMap";

import serde_json "mo:serde/JSON";
import Itertools "mo:itertools/Iter";
import { Method } "mo:http/Http";

import Form "Form";
import Headers "Headers";
import URL "URL";
import UrlEncodedValues "UrlEncodedValues";
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

        public let params = TrieMap.TrieMap<Text, Text>(Text.equal, Text.hash);
        public let query_params = UrlEncodedValues.fromText(url.query_text);

        public let body = {
            blob = func() : Blob = _body;
            text = func() : ?Text = Text.decodeUtf8(_body);
            strict_text = func() : Text {
                switch (Text.decodeUtf8(_body)) {
                    case (?text) { text };
                    case (null) { Debug.trap("Could not decode body as text") };
                };
            };

            json = func() : ?Blob {
                let optText = Text.decodeUtf8(_body);
                Option.map(optText, serde_json.fromText);
            };

            strict_json = func() : Blob {
                let text = Text.decodeUtf8(_body);
                switch (text) {
                    case (?text) { serde_json.fromText(text) };
                    case (null) { Debug.trap("Could not decode body as text") };
                };
            };
            
            setBlob = func(body : Blob) {
                _body := body;
            };
            setText = func(text : Text) {
                _body := Text.encodeUtf8(text);
            };
            setJson = func(jsonText : Text) {
                let jsonBlob = serde_json.fromText(jsonText);
                _body := jsonBlob;
            };
        };

        let boundary = do ? {
            let content_type = headers.get("content-type")!;
            let iter = Text.split(content_type, #text(";"));
            let second = Itertools.nth(iter, 1)!;
            let boundary = Text.split(second, #text("="));
            Itertools.nth(boundary, 1)!;
        };

        public let { files; values = form_values } = Form.parse(body.strict_text(), boundary);

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
