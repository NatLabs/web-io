// @testmode wasi
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Text "mo:base/Text";

import Itertools "mo:itertools/Iter";

import { suite; test } "mo:test";

import UrlEncoding "../../src/UrlEncoding";


type Metadata = {
    items : Nat;
    level : Nat;
    species : Text;
};

suite(
    "UrlEncoding Tests",
    func() {
        test(
            "Parse Query String",
            func() {

                let query_map = UrlEncoding.fromText("items=11&level=21&species=pisces");

                assert UrlEncoding.toText(query_map) == "items=11&level=21&species=pisces";
                assert Iter.toArray(query_map.keys()) == ["items", "level", "species"];

                assert query_map.get("items") == ?"11";
                assert query_map.get("level") == ?"21";
                assert query_map.get("species") == ?"pisces";
            },
        );

        test(
            "serialize",
            func() {
                let query_map = UrlEncoding.fromText("items=11&level=21&species=");
                let candid = UrlEncoding.serialize(query_map);

                type MetadataWithOptionalSpecies = {
                    items : Nat;
                    level : Nat;
                    species : ?Text;
                };

                let motoko : ?MetadataWithOptionalSpecies = from_candid (candid);

                assert Iter.toArray(query_map.entries()) == [
                    ("items", "11"),
                    ("level", "21"),
                    ("species", ""),
                ];

                assert motoko == ?{
                    items = 11;
                    level = 21;
                    species = null;
                };
            },
        );

        test(
            "deserialize",
            func() {

                let query_map = UrlEncoding.fromText("items=11&level=21&species=pisces");

                let metadata : Metadata = {
                    items = 11;
                    level = 21;
                    species = "pisces";
                };

                let MetadataKeys = ["items", "level", "species"];

                let candid = to_candid (metadata);
                let query_map2 = UrlEncoding.deserialize(candid, MetadataKeys);

                assert Itertools.equal<(Text, Text)>(
                    query_map.entries(),
                    query_map2.entries(),
                    func(a : (Text, Text), b : (Text, Text)) : Bool = a.0 == b.0 and a.1 == b.1,
                );
            },
        );

        test(
            "Decodes URL Encoded pairs",
            func() {
                let query_map = UrlEncoding.fromText("name=Dwayne%20Wade&language=French%26English");

                assert Iter.toArray(query_map.keys()) == ["name", "language"];
                
                assert query_map.get("name") == ?"Dwayne Wade";
                assert query_map.get("language") == ?"French&English";
            },
        );
    },
);
