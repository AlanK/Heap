import Foundation
import PlaygroundSupport

/// A property wrapper that creates and manages a mutable pointer to heap-allocated memory.
///
/// The pointee is guaranteed to be heap-allocated and will be deinitialized and deallocated when the wrapper is deinitialized.
///
/// The wrapped pointer should not be used outside the context of the instance containing the wrapper. Because the wrapper manages the lifecycle of the pointee, the pointer will no longer point to valid memory if the wrapper has been deallocated.
@propertyWrapper
public class Heap<Pointee> {
    
    /// A mutable pointer to the wrapped instance of `Pointee`.
    public let wrappedValue: UnsafeMutablePointer<Pointee>
    
    /// The `Heap` wrapper. Holding a reference to the wrapper extends the life of the pointer.
    public var projectedValue: Heap<Pointee> { self }
    
    private let tearDown: ((UnsafeMutablePointer<Pointee>) -> Void)?
    
    /// Creates a new property wrapper containing an instance of `Pointee` allocated on the heap.
    /// - Parameter initialize: An autoclosure that returns an instance of Pointee. Used to initialize heap-allocated memory of the correct type.
    /// - Parameter setUp: Any additional setup that needs to be performed before using the pointee.
    /// - Parameter tearDown: Any teardown that must occur before deinitializing and deallocating the pointee.
    public init(_ initialize: @autoclosure () -> Pointee,
                setUp: ((UnsafeMutablePointer<Pointee>) -> Void)? = nil,
                tearDown: ((UnsafeMutablePointer<Pointee>) -> Void)? = nil) {
        
        wrappedValue = .allocate(capacity: 1)
        wrappedValue.initialize(to: initialize())
        setUp?(wrappedValue)
        self.tearDown = tearDown
    }
    
    // We need to clean up after ourselves once we're done with the pointer
    deinit {
        tearDown?(wrappedValue)
        wrappedValue.deinitialize(count: 1)
        wrappedValue.deallocate()
    }
}



//
//
// Let's see it in action
//
//



@propertyWrapper
/// An quick & dirty wrapper that synchronizes access to a single property with a readers-writer lock.
public class RWSynced<Value> {
    
    public var wrappedValue: Value {
        readValue(value)
    }
    
    public var projectedValue: (inout Value) -> Void {
        get {
            { _ in }
        }
        set(mutate) { applyMutation(mutate) }
    }
    
    @Heap(pthread_rwlock_t(),
          setUp: { pthread_rwlock_init($0, nil) },
          tearDown: { pthread_rwlock_destroy($0) }) private var lock
    
    private var value: Value
    
    public init(wrappedValue: Value) {
        value = wrappedValue
    }
    
    private func readValue(_ value: Value) -> Value {
        pthread_rwlock_rdlock(lock)
        defer { pthread_rwlock_unlock(lock) }
        return value
    }
    
    private func applyMutation(_ mutate: (inout Value) -> Void) {
        pthread_rwlock_wrlock(lock)
        defer { pthread_rwlock_unlock(lock) }
        mutate(&value)
    }
}

/// An object with a synchronized property.
class Container {
    @RWSynced var number: Int = 0
}

let container = Container()

// Hammer the property with concurrent mutations
// If the synchronization is incorrect, some mutations will be missed and number will never reach 10000

let iterations = 10000
let group = DispatchGroup()
group.enter()

for _ in 0 ..< iterations {
    group.enter()
    DispatchQueue.global(qos: .userInitiated).async {
        container.$number = { $0 += 1 }
        group.leave()
    }
}

group.leave()
group.wait()
print("Finished!")
print(container.number)
