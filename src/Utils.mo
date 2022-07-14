import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

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
};
