import Blob "mo:base/Blob";
import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import List "mo:base/List";
import Option "mo:base/Option";
import Text "mo:base/Text";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Prelude "mo:base/Prelude";

import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";
import Mo "mo:moh";

import Utils "../Utils";

module {

    type Buffer<A> = Buffer.Buffer<A>;
    type List<A> = List.List<A>;
    type Iter<A> = Iter.Iter<A>;
    type PeekableIter<A> = PeekableIter.PeekableIter<A>;

    public type MultiPartFormEntry = {
        #Field : {
            name : Text;
            value : Text;
        };
        #File : {
            name : Text;
            filename : Text;
            content_type : Text;
            content : Buffer<Nat8>;
        };
    };

    let NEWLINE : Nat8 = 10;
    let CR : Nat8 = 13; // carriage return (\r)
    let SPACE : Nat8 = 32;
    let DOUBLE_QUOTE : Nat8 = 34;
    let DASH : Nat8 = 45;

    public func parse(blob : Blob, opt_boundary : ?Text) : ?List<MultiPartFormEntry> {
        Debug.print("parse multipart form data");
        let bytes = Itertools.peekable(blob.vals());

        let boundary = switch (opt_boundary) {
            case (?b) {
                let boundary_blob = Text.encodeUtf8("--" # b);
                let boundary_bytes = boundary_blob.vals();

                let iter = PeekableIter.takeWhile(
                    bytes,
                    func(c : Nat8) : Bool = ?c == boundary_bytes.next(),
                );

                // consume iter in for loop;
                let boundary = Itertools.toBuffer<Nat8>(iter);

                while (bytes.peek() == ?CR or bytes.peek() == ?NEWLINE) {
                    ignore bytes.next(); // consume newline char
                };

                boundary;
            };

            // extract boundary from data
            case (null) {
                let boundary_bytes = PeekableIter.takeWhile<Nat8>(
                    bytes,
                    func(c : Nat8) : Bool {
                        c != NEWLINE and c != CR;
                    },
                );

                while (bytes.peek() == ?CR or bytes.peek() == ?NEWLINE) {
                    ignore bytes.next(); // consume newline char
                };

                Itertools.toBuffer<Nat8>(boundary_bytes);
            };
        };

        Debug.print("retrieved boundary");

        var entries = List.nil<MultiPartFormEntry>();

        while (bytes.peek() == null) {
            let entry = parse_form_entry(bytes);
            let x = switch (entry) {
                case (#Field(f)) f;
                case (#File(f)) { { f with content = null } };
            };

            Debug.print(debug_show (x));

            entries := List.push(entry, entries);
        };

        ?entries;
    };

    func skip_expected(bytes : PeekableIter<Nat8>, expected_text : Text) {
        var expected = Text.encodeUtf8(expected_text).vals();

        PeekableIter.skipWhile(
            bytes,
            func(byte : Nat8) : Bool = ?byte == expected.next(),
        );
    };

    func take_text_no_quote(bytes : PeekableIter<Nat8>) : Text {
        let iter = PeekableIter.takeWhile(
            bytes,
            func(byte : Nat8) : Bool = byte != DOUBLE_QUOTE,
        );

        let text = Text.fromIter(
            Iter.map(
                iter,
                func(byte : Nat8) : Char = Mo.Char.fromNat8(byte),
            )
        );

        ignore bytes.next(); // consume Double Quote

        text;
    };

    public func take_line_text(bytes : PeekableIter<Nat8>) : Text {
        let iter = PeekableIter.takeWhile(
            bytes,
            func(byte : Nat8) : Bool = byte != NEWLINE,
        );

        let text = Text.fromIter(
            Iter.map(
                iter,
                func(byte : Nat8) : Char = Mo.Char.fromNat8(byte),
            )
        );

        ignore bytes.next(); // consume newline

        text;
    };

    public func skip_newline(bytes : PeekableIter<Nat8>) {
        if (bytes.peek() == ?CR) {
            ignore bytes.next();
        };

        if (bytes.peek() == ?NEWLINE) {
            ignore bytes.next();
        };
    };

    public func parse_composition_data(bytes : PeekableIter<Nat8>) : (Text, ?Text) {
        skip_expected(bytes, "Content-Disposition: form-data; name=");

        let iter = PeekableIter.takeWhile(
            bytes,
            func(byte : Nat8) : Bool = byte != DOUBLE_QUOTE,
        );

        let name = take_text_no_quote(bytes);

        skip_expected(bytes, "; filename=");

        let filename = take_text_no_quote(bytes);

        if (filename.size() == 0) {
            return (name, null);
        };

        skip_newline(bytes);

        (name, ?filename);
    };

    public func parse_content_type(bytes : PeekableIter<Nat8>) : Text {
        skip_expected(bytes, "Content-Type: ");
        take_line_text(bytes);
    };

    public func read_line(bytes : PeekableIter<Nat8>, buffer : Buffer<Nat8>) {
        let iter = PeekableIter.takeWhile(
            bytes,
            func(byte : Nat8) : Bool = byte != NEWLINE,
        );

        for (byte in iter) {
            buffer.add(byte);
        };

        skip_newline(bytes);
    };

    // should start at the beginning of the entry data (after the content-type and any lines)
    public func parse_data(bytes : PeekableIter<Nat8>, boundary : Buffer<Nat8>) : Buffer<Nat8> {
        let buffer = Buffer.Buffer<Nat8>(8);
        let line = Buffer.Buffer<Nat8>(8);
        Debug.print("parse_data");
        while (line.size() == 0 or Buffer.isPrefixOf(line, boundary, Nat8.equal) or Buffer.isPrefixOf(boundary, line, Nat8.equal)) {
            let ?byte = bytes.next() else return Debug.trap("Unexpected end of file");

            if (byte == NEWLINE) {
                skip_newline(bytes);
                return buffer;
            };

            line.add(byte);

            if (not Buffer.isPrefixOf(line, boundary, Nat8.equal)) {
                if (buffer.size() > 0) {
                    buffer.add(CR);
                    buffer.add(NEWLINE);
                };

                for (byte in line.vals()) {
                    buffer.add(byte);
                };

                line.clear();

                read_line(bytes, buffer);
            };
        };

        buffer;
    };

    public func parse_value(bytes : PeekableIter<Nat8>) : Text {
        skip_newline(bytes);
        take_line_text(bytes);
    };

    public func parse_file(bytes : PeekableIter<Nat8>) : Buffer<Nat8> {
        skip_newline(bytes);
        parse_data(bytes, Buffer.Buffer<Nat8>(8));
    };

    public func parse_form_entry(bytes : PeekableIter<Nat8>) : MultiPartFormEntry {
        let (name, filename) = parse_composition_data(bytes);

        switch (filename) {
            case (?filename) {
                let content_type = parse_content_type(bytes);
                skip_newline(bytes);
                let content = parse_file(bytes);
                #File { name; filename; content_type; content };
            };
            case (null) {
                skip_newline(bytes);
                let value = parse_value(bytes);
                #Field { name; value };
            };
        };
    };
};
