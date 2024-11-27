@usableFromInline final class UncheckedBox<Value>: @unchecked Sendable {
  @usableFromInline var value: Value
  @usableFromInline init(_ value: Value) {
    self.value = value
  }
}
@usableFromInline struct UncheckedSendable<Value>: @unchecked Sendable {
  @usableFromInline let value: Value
  @usableFromInline init(_ value: Value) {
    self.value = value
  }
}
