#if canImport(PerceptionMacros)
  import MacroTesting
  import PerceptionMacros
  import XCTest

  class PerceptionMacroTests: XCTestCase {
    override func invokeTest() {
      withMacroTesting(
        // isRecording: true,
        macros: [
          PerceptibleMacro.self,
          PerceptionTrackedMacro.self,
          PerceptionIgnoredMacro.self,
        ]
      ) {
        super.invokeTest()
      }
    }

    func testPerceptible() {
      assertMacro {
        """
        @Perceptible
        class Feature {
          var count = 0
        }
        """
      } expansion: {
        #"""
        class Feature {
          var count {
            @storageRestrictions(initializes: _count)
            init(initialValue) {
              _count = initialValue
            }
            get {
              access(keyPath: \.count)
              return _count
            }
            set {
              withMutation(keyPath: \.count) {
                _count = newValue
              }
            }
            _modify {
              access(keyPath: \.count)
              _$perceptionRegistrar.willSet(self, keyPath: \.count)
              defer {
                _$perceptionRegistrar.didSet(self, keyPath: \.count)
              }
              yield &_count
            }
          }

          private let _$perceptionRegistrar = Perception.PerceptionRegistrar()

          internal nonisolated func access<Member>(
            keyPath: KeyPath<Feature, Member>,
            fileID: StaticString = #fileID,
            filePath: StaticString = #filePath,
            line: UInt = #line,
            column: UInt = #column
          ) {
            _$perceptionRegistrar.access(
              self,
              keyPath: keyPath,
              fileID: fileID,
              filePath: filePath,
              line: line,
              column: column
            )
          }

          internal nonisolated func withMutation<Member, MutationResult>(
            keyPath: KeyPath<Feature, Member>,
            _ mutation: () throws -> MutationResult
          ) rethrows -> MutationResult {
            try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
          }
        }
        """#
      }
    }
  }
#endif
