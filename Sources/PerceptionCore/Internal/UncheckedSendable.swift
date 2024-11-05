@usableFromInline struct UncheckedSendable<Value>: @unchecked Sendable {
  @usableFromInline let value: Value
  @usableFromInline init(_ value: Value) {
    self.value = value
  }
}
