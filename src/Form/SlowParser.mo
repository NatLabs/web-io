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

import P "mo:parser-combinators/Parser";
import C "mo:parser-combinators/Combinators";

import Itertools "mo:itertools/Iter";
import PeekableIter "mo:itertools/PeekableIter";

import Mo "mo:moh";

import Utils "../Utils";

module {
    type Buffer<A> = Buffer.Buffer<A>;
    type List<A> = List.List<A>;
    type Iter<A> = Iter.Iter<A>;

    type Parser<T, A> = P.Parser<T, A>;

    public type MultiPartFormEntry = {
        #Field : {
            name : Text;
            value : Text;
        };
        #File : {
            name : Text;
            filename : Text;
            content_type : Text;
            content : Iter<Nat8>;
        };
    };

    let NEWLINE : Nat8 = 10;
    let CR : Nat8 = 13; // carriage return (\r)
    let SPACE : Nat8 = 32;
    let DOUBLE_QUOTE : Nat8 = 34;
    let DASH : Nat8 = 45;

    public func parse(blob : Blob, opt_boundary : ?Text) : ?List<MultiPartFormEntry> {
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
                let boundary_as_list = Iter.toList(iter);

                while (bytes.peek() == ?CR or bytes.peek() == ?NEWLINE) {
                    ignore bytes.next(); // consume newline char
                };

                boundary_as_list;
            };

            // extract boundary from data
            case (null) {
                let boundary_bytes = PeekableIter.takeWhile(
                    bytes,
                    func(c : Nat8) : Bool {
                        c != NEWLINE and c != CR;
                    },
                );

                while (bytes.peek() == ?CR or bytes.peek() == ?NEWLINE) {
                    ignore bytes.next(); // consume newline char
                };

                Iter.toList(boundary_bytes);
            };
        };

        let list = Iter.toList(bytes);

        if (list == null) {
            return ?List.nil();
        };

        switch (parseForm(list, boundary)) {
            case (?parsed) ?parsed;
            case (null) { Debug.print("Failed to parse Form"); null };
        };
    };

    func parseForm(l : List<Nat8>, boundary : List<Nat8>) : ?List<MultiPartFormEntry> {
        switch (parseFormData(boundary)(l)) {
            case (null) {
                null;
            };
            case (?(x, xs)) {
                switch (xs) {
                    case (null) { ?x };
                    case (_xs) {
                        null;
                    };
                };
            };
        };
    };

    public func ignoreSpace<A>(parser : P.Parser<Nat8, A>) : P.Parser<Nat8, A> {
        C.right(
            C.many(Byte.char(' ')),
            parser,
        );
    };

    public func parseContentDisposition() : Parser<Nat8, (Text, Text)> {
        C.seq(
            C.right(
                Bytes.text("Content-Disposition: form-data; name="),
                C.bracket(
                    Byte.byte(DOUBLE_QUOTE),
                    Bytes.get_text(),
                    Byte.byte(DOUBLE_QUOTE),
                ),
            ),
            C.oneOf([
                C.right(
                    Bytes.text("; filename="),
                    C.bracket(
                        Byte.char('\"'),
                        Bytes.get_text(),
                        C.seq(
                            Byte.char('\"'),
                            Byte.newline(),
                        ),
                    ),
                ),
                C.map(
                    Byte.newline(),
                    func(_ : Nat8) : Text { "" },
                ),
            ]),
        );
    };

    public func parseContentType() : Parser<Nat8, Text> {
        C.right(
            Bytes.text("Content-Type: "),
            C.left(
                Bytes.get_text_line(),
                Byte.newline(),
            ),
        );
    };

    public func parseFile(boundary : List<Nat8>) : Parser<Nat8, (((Text, Text), Text), Iter<Nat8>)> {
        C.seq(
            C.seq(
                parseContentDisposition(),
                parseContentType(),
            ),
            parseByteLines(boundary),
        );
    };

    public func fileParser(boundary : List<Nat8>) : Parser<Nat8, MultiPartFormEntry> {
        C.map(
            parseFile(boundary),
            func(x : (((Text, Text), Text), Iter<Nat8>)) : MultiPartFormEntry {
                let (((name, filename), content_type), content) = x;

                #File {
                    name = name;
                    filename = filename;
                    content_type = content_type;
                    content;
                };
            },
        );
    };

    public func parseValue(boundary : List<Nat8>) : Parser<Nat8, ((Text, Text), Text)> {
        ignoreSpace(
            C.seq(
                C.left(
                    parseContentDisposition(),
                    Byte.newline(),
                ),
                parseLines(boundary),
            )
        );
    };

    public func valueParser(boundary : List<Nat8>) : Parser<Nat8, MultiPartFormEntry> {
        C.map(
            parseValue(boundary),
            func(x : ((Text, Text), Text)) : MultiPartFormEntry {
                let ((name, _), value) = x;
                #Field {
                    name = name;
                    value = value;
                };
            },
        );
    };

    public func parseFormData(boundary : List<Nat8>) : Parser<Nat8, List<MultiPartFormEntry>> {
        let sep_by_boundary = C.sepBy(
            P.delay(
                func() : Parser<Nat8, MultiPartFormEntry> {
                    C.oneOf([
                        fileParser(boundary),
                        valueParser(boundary),
                    ]);
                }
            ),
            C.right(
                Bytes.bytes(List.toIter(boundary)),
                Byte.newline(),
            ),
        );

        C.oneOf([
            C.left(
                P.delay(func() : Parser<Nat8, List<MultiPartFormEntry>> = sep_by_boundary),
                C.right(
                    Bytes.bytes(
                        Itertools.chain(
                            List.toIter(boundary),
                            [DASH, DASH].vals(),
                        )
                    ),
                    Byte.newline(),
                ),
            ),
            sep_by_boundary,
        ]);
    };

    public func consIf<T, A>(
        parserA : Parser<T, A>,
        parserAs : Parser<T, List<A>>,
        cond : (A, List<A>) -> Bool,
    ) : Parser<T, List<A>> {
        C.bind(
            parserA,
            func(a : A) : Parser<T, List<A>> {
                C.bind(
                    parserAs,
                    func(as : List<A>) : Parser<T, List<A>> {
                        if (cond(a, as)) {
                            P.result<T, List<A>>(List.push(a, as));
                        } else {
                            P.zero();
                        };
                    },
                );
            },
        );
    };

    public func parseByteLine(boundary : List<Nat8>) : Parser<Nat8, List<Nat8>> {
        C.oneOf<Nat8, List<Nat8>>([
            C.map(
                Byte.newline(),
                func(_ : Nat8) : List<Nat8> { List.nil<Nat8>() },
            ),
            C.left<Nat8, List<Nat8>, Nat8>(
                consIf<Nat8, Nat8>(
                    Byte.not_newline(),
                    C.many(Byte.not_newline()),
                    func(x : Nat8, xs : List.List<Nat8>) : Bool {
                        let line = List.push<Nat8>(x, xs);
                        // Debug.print("line: " # debug_show line);
                        // Debug.print("bound: " # debug_show boundary);

                        let res = not Utils.ListModule.isPrefixOf<Nat8>(
                            line,
                            boundary,
                            Nat8.equal,
                        );

                        // Debug.print("res: " # debug_show res);
                        res;
                    },
                ),
                Byte.newline(),
            ),
        ]);
    };

    public func parseByteLines(boundary : List<Nat8>) : Parser<Nat8, Iter<Nat8>> {
        C.map(
            C.many(
                parseByteLine(boundary)
            ),
            func(cs : List<List<Nat8>>) : Iter<Nat8> {
                var is_empty = true;
                var iter = Itertools.empty<Nat8>();

                for (byte_list in List.toIter(cs)){
                    if (is_empty) {
                        is_empty := false;
                    } else {
                        iter := Itertools.chain(
                            iter,
                            [CR, NEWLINE].vals(),
                        );
                    };

                    iter := Itertools.chain(
                        iter,
                        List.toIter(byte_list),
                    );
                };
                
                iter;
            },
        );
    };

    public func parseLine(boundary : List<Nat8>) : Parser<Nat8, Text> {
        C.map(
            parseByteLine(boundary),
            Bytes.toText,
        );
    };


    public func parseLines(boundary : List<Nat8>) : Parser<Nat8, Text> {
        C.map(
            C.many(
                parseLine(boundary)
            ),
            func(cs : List.List<Text>) : Text {
                var text = "";

                List.iterate(
                    cs,
                    func(c : Text) {
                        if (text.size() == 0) {
                            text #= c;
                        } else {
                            text #= "\r\n" # c;
                        };
                    },
                );

                text;
            },
        );

    };

    public module Byte = {
        type ByteParser = Parser<Nat8, Nat8>;

        public func byte(b : Nat8) : ByteParser {
            C.sat(func(b2 : Nat8) : Bool { b == b2 });
        };

        public func newline() : ByteParser {
            C.oneOf([
                C.map(
                    Bytes.text("\r\n"),
                    func(_ : List<Nat8>) : Nat8 { NEWLINE },
                ),
                Byte.char('\r'),
                Byte.char('\n'),
            ]);
        };

        public func not_newline() : ByteParser {
            C.sat(
                func(code : Nat8) : Bool {
                    code != NEWLINE and code != CR;
                }
            );
        };

        public func char(c : Char) : ByteParser {
            let code = Mo.Char.toNat8(c);
            byte(code);
        };

        public func any() : ByteParser {
            C.sat(func(_ : Nat8) : Bool { true });
        };

        public func char_no_quote() : ByteParser {
            C.oneOf<Nat8, Nat8>([
                C.sat<Nat8>(
                    func(code : Nat8) : Bool {
                        let char = Mo.Char.fromNat8(code);
                        code != 0x22 and char != '\\';
                    }
                ),
                C.right<Nat8, Nat8, Nat8>(
                    Byte.char('\\'),
                    C.map(
                        C.sat<Nat8>(
                            func(code : Nat8) : Bool {
                                let char = Mo.Char.fromNat8(code);

                                code == 0x22 or char == '\\' or char == '/' or char == 'b' or char == 'f' or char == 'n' or char == 'r' or char == 't';
                            }
                        ),
                        func(code : Nat8) : Nat8 {
                            let char = Mo.Char.fromNat8(code);

                            switch (char) {
                                case ('b') { 0x08 };
                                case ('f') { 0x0C };
                                case ('n') { 0x0A };
                                case ('r') { 0x0D };
                                case ('t') { 0x09 };
                                case (_) { code };
                            };
                        },
                    ),
                ),
            ]);
        };
    };

    public module Bytes = {
        type BytesParser = Parser<Nat8, List<Nat8>>;

        public func bytes(bytes_iter : Iter<Nat8>) : BytesParser {
            func iter(i : Iter.Iter<Nat8>) : BytesParser {
                switch (i.next()) {
                    case (null) { P.result(Iter.toList(bytes_iter)) };
                    case (?v) {
                        C.right(
                            Byte.byte(v),
                            iter(i),
                        );
                    };
                };
            };
            iter(bytes_iter);
        };

        public func text(t : Text) : BytesParser {
            let blob = Text.encodeUtf8(t);
            bytes(blob.vals());
        };

        public func get_text() : Parser<Nat8, Text> {
            C.map(
                C.many(Byte.char_no_quote()),
                Bytes.toText,
            );
        };

        public func get_text_line() : Parser<Nat8, Text> {
            C.map(
                C.left(
                    C.many(Byte.not_newline()),
                    Byte.newline(),
                ),
                Bytes.toText,
            );
        };

        public func get_line() : Parser<Nat8, List<Nat8>> {
            C.left(
                C.many(Byte.not_newline()),
                Byte.newline(),
            );
        };

        public func toText(bs : List<Nat8>) : Text {
            Text.fromIter(
                List.toIter(
                    List.map(
                        bs,
                        func(b : Nat8) : Char {
                            Char.fromNat32(Nat32.fromNat(Nat8.toNat(b)));
                        },
                    )
                )
            );
        };
    };
};
