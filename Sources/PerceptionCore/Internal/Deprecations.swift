extension PerceptionRegistrar {
  @available(iOS, deprecated: 9999, renamed: "access(_:keyPath:)")
  @available(macOS, deprecated: 9999, renamed: "access(_:keyPath:)")
  @available(tvOS, deprecated: 9999, renamed: "access(_:keyPath:)")
  @available(watchOS, deprecated: 9999, renamed: "access(_:keyPath:)")
  public func access<Subject: Perceptible, Member>(
    _ subject: Subject,
    keyPath: KeyPath<Subject, Member>,
    fileID: StaticString,
    filePath: StaticString,
    line: UInt,
    column: UInt
  ) {
    access(subject, keyPath: keyPath)
  }
}
