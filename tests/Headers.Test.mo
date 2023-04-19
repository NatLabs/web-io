import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import {test; suite} "mo:test";

import Headers "../src/Headers";

suite("Headers Test", func() {
	test("format field key", func() {
        assert Headers.formatKey("Content-Type") == "Content-Type";
        assert Headers.formatKey("CONTENT TYPE") == "Content-Type";
        assert Headers.formatKey("accept-encoding") == "Accept-Encoding";
        assert Headers.formatKey("ACCEPT encoding") == "Accept-Encoding";
	});

	test("insert field", func() {
        let headers = Headers.Headers();
        headers.put("content-type", "text/html");
        assert headers.get("content-type") == ?"text/html";
	});

});