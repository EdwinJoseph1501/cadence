import SwiftUI

/// A property wrapper providing reactive local view state via SwiftUI DynamicProperty,
/// ensuring robust compilation across macOS SDK environments.
@propertyWrapper
public struct CadenceState<Value>: DynamicProperty {
    private var storage: State<Value>

    public init(wrappedValue: Value) {
        self.storage = State(wrappedValue: wrappedValue)
    }

    public init(initialValue: Value) {
        self.storage = State(initialValue: initialValue)
    }

    public var wrappedValue: Value {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }

    public var projectedValue: Binding<Value> {
        storage.projectedValue
    }
}
