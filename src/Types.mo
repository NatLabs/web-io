import Buffer "mo:base/Buffer";
import TrieMap "mo:base/TrieMap";
import Candid "mo:serde/Candid";

module {

    public type Candid = Candid.Candid;

    // incoming http request data types
    public type HeaderField = (Text, Text);

    public type HttpRequest = {
        url : Text;
        method : Text;
        body : Blob;
        headers : [HeaderField];
    };

    public type StreamingToken = Candid;

    public type StreamingResponse = {
        token : ?StreamingToken;
        body : Blob;
    };

    public type StreamingCallback = shared query (StreamingToken) -> async StreamingResponse;

    public type StreamingStrategy = {
        #Callback : {
            token : StreamingToken;
            callback : StreamingCallback;
        };
    };

    public type HttpResponse = {
        status_code : Nat16;
        body : Blob;
        headers : [HeaderField];
        upgrade : ?Bool;
        streaming_strategy : ?StreamingStrategy;
    };

    // Data types used by this module

    public type URL = {
        text : Text;
        protocol : Text;
        port : Nat16;
        host : Text;
        path : Text;
        segments : [Text];
        query_map : TrieMap.TrieMap<Text, Text>;
        query_text: () -> Text;
        query_candid : () -> Blob;
        anchor : Text;
    };

    public type Form = {
        get : (Text) -> ?[Text];
        trieMap : TrieMap.TrieMap<Text, [Text]>;
        keys : [Text];

        fileKeys : [Text];
        files : (Text) -> ?[File];
    };

    public type Headers = {
        original : [(Text, Text)];
        get : (Text) -> ?[Text];
        trieMap : TrieMap.TrieMap<Text, [Text]>;
        keys : [Text];
    };

    public type File = {
        name : Text;
        filename : Text;

        mimeType : Text;
        mimeSubType : Text;

        start : Nat;
        end : Nat;
        bytes : Buffer.Buffer<Nat8>;
    };

    public type Body = {
        original : Blob;
        size : Nat;
        form : Form;
        text : () -> Text;
        // serialize : () -> ?Blob;
        file : () -> ?Buffer.Buffer<Nat8>;
        bytes : (start : Nat, end : Nat) -> Buffer.Buffer<Nat8>;
    };

    public type FormObjType = {
        get : (Text) -> ?[Text];
        trieMap : TrieMap.TrieMap<Text, [Text]>;
        keys : [Text];

        fileKeys : [Text];
        files : (Text) -> ?[File];
    };

    public type ParsedHttpRequest = {
        method : Text;
        url : URL;
        headers : Headers;
        body : ?Body;
    };

    public type SharedMessage = { caller : Principal };

    /// Canister HTTP outcall request and response types
    public type HttpHeader = {
        name : Text;
        value : Text;
    };

    public type HttpMethod = {
        #get;
        #post;
        #head;
    };

    public type TransformContext = {
        function : shared query TransformArgs -> async CanisterHttpResponse;
        context : Blob;
    };

    public type CanisterHttpRequest = {
        url : Text;
        max_response_bytes : ?Nat64;
        headers : [HttpHeader];
        body : ?[Nat8];
        method : HttpMethod;
        transform : ?TransformContext;
    };

    public type CanisterHttpResponse = {
        status : Nat;
        headers : [HttpHeader];
        body : [Nat8];
        
    };

    public type RedirectedResponse = {
        url : Text;
        response : CanisterHttpResponse;
    };

    public type OutcallResponse = CanisterHttpResponse and {
        redirects : [RedirectedResponse];
    };

    public type TransformArgs = {
        response : CanisterHttpResponse;
        context : Blob;
    };

    public type ManagementCanister = actor {
        http_request : CanisterHttpRequest -> async CanisterHttpResponse;
    };

};
