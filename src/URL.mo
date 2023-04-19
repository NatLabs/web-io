import Array "mo:base/Array";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Nat16 "mo:base/Nat16";
import Text "mo:base/Text";

import Mo "mo:moh";
import Itertools "mo:itertools/Iter";

module {

    public class URL(url : Text) {

        public let text = url;

        var xs = url;

        public let protocol = if (Text.startsWith(xs, #text("http://"))) {
            xs := Mo.Text.stripStart(xs, #text("http://"));
            "http";
        } else {
            xs := Mo.Text.stripStart(xs, #text("https://"));
            "https";
        };

        var authority = "";

        if (not Text.startsWith(xs, #text("/"))) {
            let chars = xs.chars();

            authority := Text.fromIter(
                Itertools.takeWhile(chars, func(c : Char) : Bool { c != '/' }),
            );
            xs := "/" # Text.fromIter(chars);
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

        public let query_text = switch (qs.size()) {
            case (0) { "" };
            case (1) { "" };
            case (2) { xs := qs[0]; qs[1] };
            case (_) {
                let invalid_query = Mo.Text.stripStart( xs, #text(qs[0]) );
                Debug.trap("URL parsing error: Invalid query string (" # invalid_query # ")");
            };
        };

        public let path = xs;
        public let segments = Iter.toArray(Text.split(path, #char('/')));
    };
};
