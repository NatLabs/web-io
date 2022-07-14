import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Text "mo:base/Text";
import TrieMap "mo:base/TrieMap";

import MultiValuedMap "mo:MultiValuedMap";

import File "File";

module {

    type File = File.File;
    type FileData = File.FileData;
    type MultiValuedMap<K, V> = MultiValuedMap.MultiValuedMap<K, V>;

    public type MultipartForm = {
        files : MultiValuedMap<Text, File>;
        textValues : MultiValuedMap<Text, Text>;
    };

    public func getText(form : MultipartForm, name : Text) : ?Text {
        for (val in form.getAll(name).vals()) {
            switch (val) {
                case (#text(t)) return ?t;
                case (_) {};
            };
        };

        null;
    };

    public func getFile(form : MultipartForm, name : Text) : ?File {
        for (val in form.getAll(name).vals()) {
            switch (val) {
                case (#file(file)) return ?file;
                case (_) {};
            };
        };

        null;
    };

    // public func parse(data: Text): MultipartForm {

    // };

    // public func encode(form: MultipartForm): Blob {

    // };
};
