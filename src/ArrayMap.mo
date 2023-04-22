import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Deque "mo:base/Deque";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

import Itertools "mo:itertools/Iter";

module {

    public class ArrayMap<K, V>(
        isKeyEq : (K, K) -> Bool,
        keyHash : K -> Hash.Hash,
    ) {

        var map = TrieMap.TrieMap<K, Deque.Deque<V>>(isKeyEq, keyHash);

        public let size = map.size;
        public let keys = map.keys;

        /// Associates the key with the given value in the map.
        /// Overwrites any existing values previously associated with the key
        public func put(key : K, value : V) {
            let deque = Deque.empty<V>();
            map.put(key, Deque.pushBack(deque, value));
        };

        /// Associates the key with the given values in the map.
        /// These new values overwrite any previous values.
        public func putAll(key : K, values : [V]) : () {
            let deque = dequeFromArray(values);
            map.put(key, deque);
        };

        /// Adds a value to the end of the list associated with the key
        public func add(key : K, value : V) {
            switch (map.get(key)) {
                case (?deque) {
                    map.put(key, Deque.pushBack(deque, value));
                };
                case (_) {
                    put(key, value);
                };
            };
        };

        /// Adds the value to the beginning of the list for the associated key
        public func addFront(key : K, value : V) {
            switch (map.get(key)) {
                case (?deque) {
                    map.put(key, Deque.pushFront(deque, value));
                };
                case (_) {
                    put(key, value);
                };
            };
        };

        /// Appends all the given `values` to the existing values associated with the given key
        public func addAll(key : K, values : [V]) {
            switch (map.get(key)) {
                case (?deque) {
                    map.put(key, appendArrayToDeque<V>(deque, values));
                };
                case (_) {
                    putAll(key, values);
                };
            };
        };

        /// Retrieves the first value associated with the key
        public func getFront(key : K) : ?V {
            let arr = optDequeToArray(map.get(key));

            if (arr.size() > 0) {
                ?arr[0];
            } else {
                null;
            };
        };

        /// Retrieves the last value associated with the key
        public func getBack(key : K) : ?V {
            let arr = optDequeToArray(map.get(key));

            if (arr.size() > 0) {
                ?arr[arr.size() - 1];
            } else {
                null;
            };
        };

        /// Retrieves the value at the given index associated with the key
        public func getAt(key : K, index : Nat) : V {
            let arr = optDequeToArray(map.get(key));
            arr[index];
        };

        /// Retrieves all the values associated with the given key
        public func get(key : K) : ?[V] {
            switch (map.get(key)) {
                case (?deque) ?dequeToArray(deque);
                case (_) null;
            };
        };

        public func vals() : Iter.Iter<[V]> {
            let iter = map.vals();

            return object {
                public func next() : ?[V] {
                    switch (iter.next()) {
                        case (?optVals) {
                            ?optDequeToArray(iter.next());
                        };
                        case (_) {
                            null;
                        };
                    };
                };
            };
        };

        public func contains(key : K) : Bool = Option.isSome(map.get(key));

        /// Returns the number of values associated with the given key
        public func sizeOf(key : K) : Nat {
            switch (map.get(key)) {
                case (?deque) optDequeToArray(?deque).size();
                case (_) Debug.trap("Key not found");
            };
        };

        /// Returns all the entries in the map as a tuple of
        /// key and values array
        public func entries() : Iter.Iter<(K, [V])> {
            let iter = map.entries();

            return object {
                public func next() : ?(K, [V]) {
                    switch (iter.next()) {
                        case (?(key, deque)) {
                            ?(key, dequeToArray(deque));
                        };
                        case (_) {
                            null;
                        };
                    };
                };
            };
        };

        /// Returns all the entries in the map but instead of
        /// an iterator with a key and a values array (`(K, [V])`), it returns
        /// every value in the map in a tuple with its associated key (`(K, V)`).
        public func flattenedEntries() : Iter.Iter<(K, V)> {
            let iter = Iter.map(
                entries(),
                func((key, values) : (K, [V])) : Iter.Iter<(K, V)> {
                    Iter.map<V, (K, V)>(
                        values.vals(),
                        func(val) { (key, val) },
                    );
                },
            );

            Itertools.flatten(iter);
        };

        /// Returns an iterator with key-value tuple pairs with every key in
        /// the map and its first value
        public func singleValueEntries() : Iter.Iter<(K, V)> {
            Iter.map<(K, [V]), (K, V)>(
                entries(),
                func((key, values)) { (key, values[0]) },
            );
        };

        /// Removes all the values associated with the specified key
        /// and returns them
        ///
        /// If the key is not found, the function returns null
        public func remove(key : K) : ?[V] = switch (map.remove(key)) {
            case (?deque) ?dequeToArray(deque);
            case (_) null;
        };

        /// Removes all the key-value pairs in the map
        public func clear() {
            map := TrieMap.TrieMap<K, Deque.Deque<V>>(isKeyEq, keyHash);
        };
    };

    public func fromEntries<K, V>(
        entries : [(K, [V])],
        isKeyEq : (K, K) -> Bool,
        keyHash : K -> Hash.Hash,
    ) : ArrayMap<K, V> {
        let mvMap = ArrayMap<K, V>(isKeyEq, keyHash);

        for ((key, values) in entries.vals()) {
            mvMap.addAll(key, values);
        };

        mvMap;
    };

    public func arrayToBuffer<T>(arr : [T]) : Buffer.Buffer<T> {
        let buffer = Buffer.Buffer<T>(arr.size());
        for (n in arr.vals()) {
            buffer.add(n);
        };
        return buffer;
    };

    func dequeFromArray<A>(values : [A]) : Deque.Deque<A> {
        let dq = Deque.empty<A>();

        appendArrayToDeque(dq, values);
    };

    func appendArrayToDeque<A>(deque : Deque.Deque<A>, values : [A]) : Deque.Deque<A> {
        var dq = deque;

        for (val in values.vals()) {
            dq := Deque.pushBack(dq, val);
        };

        dq;
    };

    func dequeToIter<A>(deque : Deque.Deque<A>) : Iter.Iter<A> {
        var iter = deque;

        object {
            public func next() : ?A {
                switch (Deque.popFront(iter)) {
                    case (?(val, next)) {
                        iter := next;
                        ?val;
                    };
                    case (null) null;
                };
            };
        };
    };

    func dequeToArray<A>(deque : Deque.Deque<A>) : [A] {
        Iter.toArray(
            dequeToIter(deque)
        );
    };

    func optDequeToArray<A>(deque : ?Deque.Deque<A>) : [A] {
        switch (deque) {
            case (?deque) {
                dequeToArray(deque);
            };
            case (_) { [] };
        };
    };
};
