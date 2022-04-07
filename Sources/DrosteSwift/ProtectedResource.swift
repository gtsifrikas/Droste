//
//  ProtectedResource.swift
//  Droste
//
//  Created by George Tsifrikas on 3/3/20.
//

import Foundation

public class ReadWriteLock {
    private let queue: DispatchQueue

    public init(label: String) {
        queue = DispatchQueue(label: label, attributes: .concurrent) // (1)
    }

    public func read<T>(closure: () -> T) -> T {
        return queue.sync { // (2)
            closure()
        }
    }

    public func write(closure: @escaping () -> Void) {
        // using the barrier flag ensures that no
        // other operation will run during a write
        queue.async(flags: .barrier) { // (3)
            closure()
        }
    }
}

public class Protected<Resource: Any> {
    private let lock: ReadWriteLock
    private var resource: Resource

    public init(resource: Resource) {
        self.lock = ReadWriteLock(label: "\(Resource.self)")
        self.resource = resource
    }

    public func read() -> Resource {
        return lock.read {
            self.resource
        }
    }

    public func mutate(closure: @escaping (Resource) -> Resource) {
        lock.write {
            self.resource = closure(self.resource)
        }
    }
}
