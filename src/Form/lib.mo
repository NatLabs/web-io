import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Option "mo:base/Option";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import Itertools "mo:itertools/Iter";

import Headers "../Headers";
import UrlEncoding "../UrlEncoding";
import File "../File";
import FormParser "SlowParser";

module {

    type File = File.File;
    type FileData = File.FileData;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public type Form = {
        files : TrieMap<Text, File>;
        fields : TrieMap<Text, Text>;
    };

    type MultiPartFormEntry = FormParser.MultiPartFormEntry;

    public func Form() : Form {
        {
            files = TrieMap.TrieMap(Text.equal, Text.hash);
            fields = TrieMap.TrieMap(Text.equal, Text.hash);
        }
    };
    
    public func parse_multipart(data: Blob, boundary: ?Text): ?Form = do ? {
        let entries = FormParser.parse(data, boundary)!;
        let form = Form();

        for (entry in List.toIter<MultiPartFormEntry>(entries)){
            switch(entry){
                case (#Field{ name; value }) {
                    form.fields.put(name, value);
                };
                case (#File{ name; filename; content; content_type }) {
                    let file = File.fromBytes(
                        { filename; content_type; mtime = null},
                        content
                    );
                    form.files.put(name, file);
                };
            }
        };

        form
    };

    public func parse_with_headers(data: Blob, headers: Headers.Headers): ?Form {
        let opt_content_type = headers.get("Content-Type");

        if (opt_content_type == ?"application/x-www-form-urlencoded") {
            return parse(data, #urlencoding);
        };

        ignore do ? {
            let content_type = opt_content_type!;

            if (Text.startsWith(content_type, #text("multipart/form-data"))) {
                let iter = Text.split(content_type, #text(";"));
                let entry = Itertools.nth(iter, 1)!;
                let val = Text.split(entry, #text("="));
                let boundary = Itertools.nth(val, 1)!;

                return parse_multipart(data, ?boundary);
            };
        };

        // try to parse as urlencoded data
        switch(parse(data, #urlencoding)){
            case (?form) ?form;

            // if it fails, try to parse as multipart
            case (null) parse_multipart(data, null);
        };
 
    };

    public type FormDataType = {
        #urlencoding;
        #multipart: {
            boundary: ?Text;
        };
    };

    public func parse(data: Blob, form_type: FormDataType): ?Form {
        switch(form_type){
            case (#multipart { boundary })  parse_multipart(data, boundary);
            case (#urlencoding) {
                let ?text = Text.decodeUtf8(data) else return null;
                let ?fields = UrlEncoding.parse(text) else return null;

                let form : Form = {
                    fields;
                    files = TrieMap.TrieMap(Text.equal, Text.hash);
                };

                ?form
            };
        };
    };

    func generate_boundary() : Text {
        ""
    };

    public func encode(form: Form, headers: ?Headers.Headers): Blob {
        if (form.fields.size() == 0 and form.files.size() == 0) {
            return "";
        };

        if (form.files.size() == 0 ){
            let encoded_text = UrlEncoding.toText(form.fields);
            ignore do ? {
                headers!.put("Content-Type", "application/x-www-form-urlencoded");
                headers!.put("Content-Length", debug_show encoded_text.size());
            };
            
            return Text.encodeUtf8(encoded_text);
        };

        let boundary = generate_boundary();
        ignore do ? {
            headers!.put("Content-Type", "multipart/form-data; boundary=" # boundary);
        };

        let buffer = Buffer.Buffer<Nat8>(10);
        func append_text(text: Text) {
            append(Text.encodeUtf8(text));
        };

        func append(blob: Blob) {
            for (byte in blob.vals()){
                buffer.add(byte);
            };
        };

        for ((key, val) in form.fields.entries()){
            append_text("--" # boundary # "\r\n");
            append_text("Content-Disposition: form-data; name=\"" # key # "\"\r\n\r\n");
            append_text(val # "\r\n");
        };

        for ((key, file) in form.files.entries()){
            append_text("--" # boundary # "\r\n");
            append_text("Content-Disposition: form-data; name=\"" # key # "\"; filename=\"" # file.filename # "\"\r\n");
            append_text("Content-Type: " # file.content_type # "\r\n");

            ignore do ? {
                let mtime = file.mtime!;
                // need DateTime library to convert time to string format
                // append_text("Last-Modified: " # debug_show (mtime / (10 ** 9)) # "\r\n");
            };

            append_text("\r\n");
            append(file.content());
            append_text("\r\n");
        };

        append_text("--" # boundary # "--\r\n");

        Blob.fromArray(Buffer.toArray(buffer));
    };

};
