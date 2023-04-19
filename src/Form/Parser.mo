import Char "mo:base/Char";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Option "mo:base/Option";
import Text "mo:base/Text";

import P "mo:parser-combinators/Parser";
import C "mo:parser-combinators/Combinators";
import Itertools "mo:itertools/Iter";

module {
    type List<A> = List.List<A>;
    type Iter<A> = Iter.Iter<A>;

    type Parser<T, A> = P.Parser<T, A>;

    type MultiPartForm = {
        #Field : {
            name : Text;
            value : Text;
        };
        #File : {
            name : Text;
            filename : Text;
            content_type : Text;
            content : Blob;
        };
    };

    public func parse(text : Text, _boundary: ?Text) : List<MultiPartForm> {
        let chars = Iter.toList(text.chars());

        let boundary = switch(_boundary){
            case (?b) b;

            // extract boundary from data
            case (null) {
                let iter = Itertools.peekable(text.chars());
                
                var end = false;
                let boundary_chars = Itertools.takeWhile(
                    iter, 
                    func(c : Char) : Bool { 
                        let res = not end;

                        if (c == '\n') { end := true; };
                        if (c == '\r' and iter.peek() != ?'\n') { end := true; };
                        res
                    }
                );

                Text.fromIter(boundary_chars);
            };
        };

        switch (parseForm(chars, boundary)) {
            case (?parsed) parsed;
            case (null){
                 Debug.print("Failed to parse Form text for input: " # debug_show (chars));
                 List.nil()
            }
        };
    };

    func parseForm(l : List.List<Char>, boundary: Text) : ?List<MultiPartForm> {
        switch (parseFormData(boundary)(l)) {
            case (null) { null };
            case (?(x, xs)) {
                switch (xs) {
                    case (null) { ?x };
                    case (_xs) {
                        Debug.print("Failed to parse Form: " # debug_show (x, _xs));
                        null;
                    };
                };
            };
        };
    };

    public func parseContentDisposition() : Parser<Char, (Text, Text)> {
        C.seq(
            C.right(
                C.String.string("Content-Disposition: form-data; name="),
                C.bracket(
                    C.Character.char('\"'),
                    anyText(),
                    C.Character.char('\"'),
                ),
            ),
            C.oneOf([
                C.right(
                    C.String.string("; filename="),
                    C.bracket(
                        C.Character.char('\"'),
                        anyText(),
                        C.seq(
                            C.Character.char('\"'),
                            newline(),
                        ),
                    ),
                ),
                C.map(
                    newline(),
                    func(_ : Char) : Text { "" },
                ),
            ]),
        );
    };

    public func parseContentType() : Parser<Char, Text> {
        C.right(
            C.String.string("Content-Type: "),
            C.left(
                anyText(),
                newline(),
            ),
        );
    };

    public func parseContent() : Parser<Char, Text> {
        C.bracket(
            newline(),
            // C.many(any()),
            anyText(),
            newline(),
        );
    };

    public func parseFile() : Parser<Char, (((Text, Text), Text), Text)> {
        C.seq(
            C.seq(
                parseContentDisposition(),
                parseContentType(),
            ),
            parseContent(),
        );
    };

    public func fileParser() : Parser<Char, MultiPartForm> {
        C.map(
            parseFile(),
            func(x : (((Text, Text), Text), Text)) : MultiPartForm {
                let (((name, filename), content_type), content) = x;

                if (filename.size() > 0 or content_type != "text/plain") {
                    #File {
                        name = name;
                        filename = filename;
                        content_type = content_type;
                        content = Text.encodeUtf8(content);
                    };
                } else {
                    #Field {
                        name = name;
                        value = content;
                    };
                };
            },
        );
    };

    public func parseValue() : Parser<Char, ((Text, Text), Text)> {
        C.seq(
            parseContentDisposition(),
            parseContent(),
        );
    };

    public func valueParser() : Parser<Char, MultiPartForm> {
        C.map(
            parseValue(),
            func(x : ((Text, Text), Text)) : MultiPartForm {
                let ((name, _), value) = x;
                #Field {
                    name = name;
                    value = value;
                };
            },
        );
    };

    public func parseFormData(boundary: Text) : Parser<Char, List<MultiPartForm>> {
        C.sepBy1(
            C.oneOf([
                fileParser(),
                valueParser(),
            ]),
            C.String.string(boundary)
        );
    };

    public func any() : Parser<Char, Char> {
        C.sat(func(_ : Char) : Bool { true });
    };

    public func newline() : Parser<Char, Char> {
        C.oneOf([
            C.Character.char('\r'),
            C.Character.char('\n'),
            C.map(
                C.String.string("\r\n"),
                func(_ : Text) : Char { '\n' },
            ),
        ]);
    };

    func anyText() : Parser<Char, Text> {
        C.map(
            C.many(textChar()),
            func(cs : List.List<Char>) : Text {
                Text.fromIter(List.toIter(cs));
            },
        );

    };

    func textChar() : P.Parser<Char, Char> = C.oneOf([
        C.sat<Char>(
            func(c : Char) : Bool {
                c != Char.fromNat32(0x22) and c != '\\';
            },
        ),
        C.right(
            C.Character.char('\\'),
            C.map(
                C.Character.oneOf([
                    Char.fromNat32(0x22),
                    '\\',
                    '/',
                    'b',
                    'f',
                    'n',
                    'r',
                    't',
                    // TODO : u hex { 4 },
                ]),
                func(c : Char) : Char {
                    switch (c) {
                        case ('b') { Char.fromNat32(0x08) };
                        case ('f') { Char.fromNat32(0x0C) };
                        case ('n') { Char.fromNat32(0x0A) };
                        case ('r') { Char.fromNat32(0x0D) };
                        case ('t') { Char.fromNat32(0x09) };
                        case (_) { c };
                    };
                },
            ),
        ),
    ]);

};
