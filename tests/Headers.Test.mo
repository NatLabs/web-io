// @testmode wasi
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import { test; suite } "mo:test";

import Headers "../src/Headers";

suite(
    "Headers Test",
    func() {
        test(
            "format field key",
            func() {
                assert Headers.formatKey("Content-Type") == "Content-Type";
                assert Headers.formatKey("CONTENT TYPE") == "Content-Type";
                assert Headers.formatKey("accept-encoding") == "Accept-Encoding";
                assert Headers.formatKey("ACCEPT   encoding") == "Accept-Encoding";
            },
        );

        test(
            "insert field and retrieve them case-insensitively",
            func() {
                let headers = Headers.Headers();
                headers.put("content-type", "text/html");
                assert headers.get("content-type") == ?"text/html";
                assert headers.get("Content-Type") == ?"text/html";
                assert headers.get("CONTENT-TYPE") == ?"text/html";
                assert headers.get("content       type") == ?"text/html";
            },
        );

        test(
            "store multiple values for a field using the 'add()' method",
            func() {
                let headers = Headers.Headers();
                headers.add("content-type", "text/html"); 
                headers.add("content-type", "text/plain");

                assert headers.get("content-type") == ?"text/plain"; // get most recent value
                assert headers.getAll("content-type") == ?["text/html", "text/plain"];

            },
        )
    },
);
