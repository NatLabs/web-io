<<<<<<< HEAD
=======
Filename: `[Section]/[Function].Test.mo`

>>>>>>> ce6a4b5 (template)
```motoko
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

<<<<<<< HEAD
import ActorSpec "./utils/ActorSpec";
import Lib "../src";
=======
import ActorSpec "../utils/ActorSpec";
import Algo "../../src";
// import [FnName] "../../src/[section]/[FnName]";
>>>>>>> ce6a4b5 (template)

let {
    assertTrue; assertFalse; assertAllTrue; 
    describe; it; skip; pending; run
} = ActorSpec;

let success = run([
    describe(" (Function Name) ", [
        it("(test name)", do {
<<<<<<< HEAD
            // assertTrue(Lib.fnCall() == expectedResult)
            // assertAllTrue([Lib.fnCall() == expectedResult, Lib.fn2() == res2])

           assertTrue(true)
=======
            
            // ...
>>>>>>> ce6a4b5 (template)
        }),
    ])
]);

if(success == false){
  Debug.trap("\1b[46;41mTests failed\1b[0m");
}else{
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};

```