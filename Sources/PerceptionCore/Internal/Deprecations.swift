@available(*, deprecated)
extension PerceptionRegistrar {
  public init(isPerceptionCheckingEnabled: Bool) {
    self.init()
  }

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

@available(*, deprecated)
public enum _PerceptionLocals {
  @TaskLocal public static var skipPerceptionChecking = false
}
