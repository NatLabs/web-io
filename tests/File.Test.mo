import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";

import ActorSpec "../utils/ActorSpec";

import File "../../src/File";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

let success = run([
    describe(
        "File",
        [
            it(
                "append blob",
                do {
                    let file = File.File("test.txt", "plain/text", null);
                    let blob = Text.encodeUtf8("Hello World");

                    file.append(blob);

                    assertTrue(
                        file.blob() == file.slice(0, 11),
                    );
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
