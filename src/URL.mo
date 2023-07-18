import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Nat16 "mo:base/Nat16";
import Text "mo:base/Text";

import Mo "mo:moh";
import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";

import UrlEncoding "UrlEncoding";

module {

    /// A URL class for parsing and manipulating URLs.
    public class URL(url : Text) {

        var xs = url;
        var includes_protocol = false;

        /// The protocol of the URL, e.g. "http" or "https".
        public let protocol = if (Text.startsWith(xs, #text("http://"))) {
            xs := Mo.Text.stripStart(xs, #text("http://"));
            includes_protocol := true;
            "http";
        } else if (Text.startsWith(xs, #text("https://"))) {
            xs := Mo.Text.stripStart(xs, #text("https://"));
            includes_protocol := true;
            "https";
        }else{
            "https"
        };

        var authority = "";

        if (not Text.startsWith(xs, #text("/"))) {
            let chars = Itertools.peekable(xs.chars());

            authority := Text.fromIter(
                PeekableIter.takeWhile(chars, func(c : Char) : Bool { c != '/' }),
            );
            xs := Text.fromIter(chars);
        };

        let auth = Iter.toArray(Text.split(authority, #char(':')));

        let default_port : Nat16 = if (protocol == "http") { 80 } else { 443 };

        public let (host, port) : (Text, Nat16) = switch (auth.size()) {
            case (0) { ("", default_port) };
            case (1) { (auth[0], default_port) };
            case (2) { (auth[0], Mo.Nat16.fromText(auth[1])) };
            case (_) {
                Debug.trap("URL parsing error: Invalid authority (" # authority # ")");
            };
        };

        let anch = Iter.toArray(Text.split(xs, #char('#')));

        /// The anchor of the URL.
        public let anchor = switch (anch.size()) {
            case (0) { "" };
            case (1) { "" };
            case (2) { xs := anch[0]; anch[1] };
            case (_) {
                let invalid_anchor = Text.stripStart( xs, #text(anch[0]) );
                Debug.trap("URL parsing error: Invalid anchor (" # anch[2] # ")");
            };
        };

        let qs = Iter.toArray(Text.split(xs, #char('?')));

        let _query_text = switch (qs.size()) {
            case (0) { "" };
            case (1) { "" };
            case (2) { xs := qs[0]; qs[1] };
            case (_) {
                let invalid_query = Mo.Text.stripStart( xs, #text(qs[0]) );
                Debug.trap("URL parsing error: Invalid query string (" # invalid_query # ")");
            };
        };

        /// Returns the TrieMap where the query parameters are stored.
        public let query_map = switch(UrlEncoding.parse(_query_text)){
            case (?map) map;
            case (null) Debug.trap("URL parsing error: Invalid query string (" # _query_text # ")");
        };

        /// Returns the serialized candid blob of the query parameters.
        public func query_candid() : Blob = UrlEncoding.serialize(query_map);

        /// Returns the query parameters as a Text.
        public func query_text() : Text = UrlEncoding.toText(query_map);

        /// Returns the segments of the path of the URL.
        public let segments = Iter.toArray(Text.tokens(xs, #char('/')));

        /// Returns the path of the URL. 
        public let path =  "/" # Text.join("/", segments.vals());

        let _protocol = if (includes_protocol) { protocol # "://" } else { "" };
        let _anchor = if (anchor != "") { "#" # anchor } else { "" };
        
        /// Returns the URL as a Text excluding the query parameters.
        public func text() : Text {

            let _query_text = query_text();

            if (_query_text == "") {
                return _protocol # authority # path # _anchor;
            };

            _protocol # authority # path # "?" # _query_text  # _anchor;
        }
    };
};
