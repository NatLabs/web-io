/// A module for making Http outbound requests.

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

import fuzzText "mo:fuzz/Text";
import fuzz "mo:fuzz";
import { Method; Status } "mo:http/Http";

import File "File";
import Request "Request";
import Response "Response";
import RequestBuilder "RequestBuilder";
import T "Types";

module {
    type File = File.File;
    type RequestBuilder = RequestBuilder.RequestBuilder;

    type RequestBuilderChainingInterface<A> = RequestBuilder.RequestBuilderChainingInterface<A>;

    public type OutcallInterface<OutcallClass> = RequestBuilderChainingInterface<OutcallClass> and {
        follow_redirects : Bool -> OutcallClass;
        max_redirects : Nat -> OutcallClass;
        send_request : () -> async* T.OutcallResponse;
    };

    public let KB = 1024;
    public let MB = 1048576;

    public class Outcall(url : Text) : OutcallInterface<Outcall> = self {
        let request_builder = RequestBuilder.RequestBuilder(url);
        
        let request_builder_state = request_builder._get_mut_state();

        func chain( _ : Any ) : Outcall = self;

        public func add_query(key : Text, value : Text) : Outcall = chain( request_builder.add_query(key, value) );

        public func auth(username : Text, password : Text) : Outcall = chain( request_builder.auth(username, password) );

        public func bearer_token(token : Text) : Outcall = chain( request_builder.bearer_token(token) );

        public func blob(blob : Blob) : Outcall = chain( request_builder.blob(blob) );

        public func caller(principal : Principal) : Outcall = chain( request_builder.caller(principal) );

        public func cookie(key : Text, value : Text) : Outcall = chain( request_builder.cookie(key, value) );

        public func cycles(cycles : Nat) : Outcall = chain( request_builder.cycles(cycles) );

        public func file(key : Text, file : File) : Outcall = chain( request_builder.file(key, file) );

        public func files(files : [(Text, File)]) : Outcall = chain( request_builder.files(files) );

        public func form_field(key : Text, value : Text) : Outcall = chain( request_builder.form_field(key, value) );

        public func form_fields(fields : [(Text, Text)]) : Outcall = chain( request_builder.form_fields(fields) );

        public func header(key : Text, value : Text) : Outcall = chain( request_builder.header(key, value) );

        public func headers(fields : [T.HeaderField]) : Outcall = chain( request_builder.headers(fields) );

        public func html(html : Text) : Outcall = chain( request_builder.html(html) );

        public func json(blob : Blob, fields : [Text]) : Outcall = chain( request_builder.json(blob, fields) );

        public func max_bytes(max_bytes : Nat64) : Outcall = chain( request_builder.max_bytes(max_bytes) );

        public func method(method : Text) : Outcall = chain( request_builder.method(method) );

        public func queries(queries : [(Text, Text)]) : Outcall = chain( request_builder.queries(queries) );

        public func text(text : Text) : Outcall = chain( request_builder.text(text) );

        public func transform(context : ?T.TransformContext) : Outcall = chain( request_builder.transform(context) );

        var _max_redirects = 2;
        var _follow_redirects = false;
        
        let seed = Int.abs(Time.now());
        let random_generator = fuzz.createGenerator(seed);
        let randomText = fuzzText.FuzzText(random_generator);

        /// Sets the maximum amount of redirects that can be followed.
        public func max_redirects(max : Nat) : Outcall {
            _max_redirects := max;
            self;
        };

        /// Give permission to the request to follow redirects.
        public func follow_redirects(follow : Bool) : Outcall {
            _follow_redirects := follow;
            self;
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

        func _send_request(req: T.CanisterHttpRequest) : async* T.OutcallResponse {
            let internet_computer : T.ManagementCanister = actor ("aaaaa-aa");
            
            Cycles.add(Nat.min(request_builder_state.cycles, Cycles.balance()));
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
            
            if (request_builder_state.method == Method.Post){
                // set idempotency key for this request
                let idempotency_key = random_id();
                request_builder_state.headers.add("Idempotency-Key", idempotency_key);
            };

            let req = request_builder.build_canister_http();

            await* _send_request(req);
        };

        func random_id() : Text {
            randomText.randomAlphanumeric(10);
        };

    };

    /// Returns a request builder for a get request.
    public func get(url : Text) : Outcall = Outcall(url).method(Method.Get);

    /// Returns a request builder for a post request.
    public func post(url : Text) : Outcall = Outcall(url).method(Method.Post);

    /// Returns a request builder for a put request.
    public func head(url : Text) : Outcall = Outcall(url).method(Method.Head);

};
