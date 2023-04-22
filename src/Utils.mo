import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import List "mo:base/List";

module {
    public module BufferModule {
        public func iterSlice<A>(buffer : Buffer.Buffer<A>, start : Nat, end : Nat) : Iter.Iter<A> {
            var i = start;
            var j = end;

            object {
                public func next() : ?A {
                    if (i < j and j < buffer.size()) {
                        buffer.getOpt(i);
                    } else {
                        null;
                    };
                };
            };
        };
    };

    public module ListModule{
        type List<A> = List.List<A>;
        public func isPrefixOf<A>(prefix: List<A>, list: List<A>, eq: (A, A) -> Bool) : Bool {
            switch(List.pop(prefix), List.pop(list)){
                case ((?p, ps), (?l, ls)) {
                    eq(p, l) and isPrefixOf(ps, ls, eq);
                };
                case ((null, _), _) {
                    true;
                };
                case (_, (null, _)) {
                    false;
                };
            };
        }
    };
};
