import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Option "mo:base/Option";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import MultiValuedMap "mo:MultiValuedMap";
import File "../File";
import FormParser "Parser";

module {

    type File = File.File;
    type FileData = File.FileData;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;

    public type Form = {
        files : TrieMap<Text, File>;
        values : TrieMap<Text, Text>;
    };

    public func Form() : Form {
        {
            files = TrieMap.TrieMap(Text.equal, Text.hash);
            values = TrieMap.TrieMap(Text.equal, Text.hash);
        }
    };

    public func parse(data: Text, boundary: ?Text): Form {
        let entries = FormParser.parse(data, boundary);
        Debug.print("form body: " # data);
        let form = Form();

        for (entry in List.toIter(entries)){
            switch(entry){
                case (#Field{ name; value }) {
                    form.values.put(name, value);
                };
                case (#File{ name; filename; content; content_type }) {
                    let file = File.File(filename, content_type, null);
                    file.append(content);
                    form.files.put(name, file);
                };
            }
        };

        form
    };

    // public func encode(form: MultipartForm): Blob {

    // };

};
