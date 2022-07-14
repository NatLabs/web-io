import TrieMap "mo:base/TrieMap";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import Blob "mo:base/Blob";

import Http "mo:http/Http";
import JSON "mo:serde/JSON";

import Response "../Response";
import Types "Types";

module {

    public type StreamingStrategy = Types.StreamingStrategy;
    public type StreamingCallbackToken = Types.StreamingCallbackToken;

    public type HttpResponse = Types.HttpResponse;

    type VarResponseBuildType = {
        var status_code : Nat16;
        var body : Blob;
        headers : TrieMap.TrieMap<Text, Text>;
        var update : Bool;
        var streaming_strategy : ?StreamingStrategy;
    };

    public type ResponseBuilder = {
        status : (Nat16) -> ResponseBuilder;
        text : (Text) -> ResponseBuilder;
        update : (Bool) -> ResponseBuilder;
        build : () -> HttpResponse;
    };

    public func ResponseBuilder() : ResponseBuilder {
        let res = Response.Response();

        func functor() : ResponseBuilder {
            object {
                public func status(n : Nat16) : ResponseBuilder {
                    res.status_code := n;
                    functor();
                };

                public func update(b : Bool) : ResponseBuilder {
                    res.update := b;
                    functor();
                };

                public func header(field : Text, value : Text) : ResponseBuilder {
                    res.headers.put(field, value);
                    functor();
                };

                public func headers(entries : [(Text, Text)]) : ResponseBuilder {
                    for ((field, value) in entries.vals()) {
                        res.headers.put(field, value);
                    };

                    functor();
                };

                public func json(blob : Blob, recordKeys : [Text]) : ResponseBuilder {
                    res.headers.put("Content-Type", "application/json");
                    let jsonText = JSON.toText(blob, recordKeys);
                    res.body := Text.encodeUtf8(jsonText);

                    functor();
                };

                public func text(t : Text) : ResponseBuilder {
                    res.body := Text.encodeUtf8(t);
                    functor();
                };

                public func body(b : Blob) : ResponseBuilder {
                    res.body := b;
                    functor();
                };

                public func redirect(url : Text) : ResponseBuilder {
                    res.headers.put("Location", url);
                    functor();
                };

                public func build() : HttpResponse {
                    {
                        status_code = res.status_code;
                        body = res.body;
                        headers = Iter.toArray(res.headers.entries());
                        update = if (res.update) { ?true } else { null };
                        streaming_strategy = res.streaming_strategy;
                    };
                };

            };
        };

        functor();
    };

};
