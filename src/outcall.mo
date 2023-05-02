/// A module for making Http outbound requests.

import { Method } "mo:http/Http";

import RequestBuilder "RequestBuilder";

module {
    public type RequestBuilder = RequestBuilder.RequestBuilder;

    public let KB = 1024;
    public let MB = 1048576;

    /// Returns a request builder for a get request.
    public func get(url: Text): RequestBuilder = RequestBuilder
        .RequestBuilder(url)
        .method(Method.Get);

    /// Returns a request builder for a post request.
    public func post(url: Text): RequestBuilder = RequestBuilder
        .RequestBuilder(url)
        .method(Method.Post);
    
    /// Returns a request builder for a put request.
    public func head(url: Text): RequestBuilder = RequestBuilder
        .RequestBuilder(url)
        .method(Method.Head);

};
