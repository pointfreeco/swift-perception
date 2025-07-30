#if os(macOS)
  import MacroTesting
  import PerceptionMacros
  import Testing

  @Suite(
    .macros(
      [
        PerceptibleMacro.self,
        PerceptionTrackedMacro.self,
        PerceptionIgnoredMacro.self,
      ],
      record: .failed
    )
  )
  struct PerceptibleMacroTests {
    @Test func basics() {
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
              _$perceptionRegistrar.access(self, keyPath: \.count)
              return _count
            }
            set {
              guard shouldNotifyObservers(_count, newValue) else {
                _count = newValue
                return
              }
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

          private  var _count  = 0

          private let _$perceptionRegistrar = Perception.PerceptionRegistrar()

          internal nonisolated func access<__macro_local_6MemberfMu_>(
            keyPath: KeyPath<Feature, __macro_local_6MemberfMu_>
          ) {
            _$perceptionRegistrar.access(self, keyPath: keyPath)
          }

          internal nonisolated func withMutation<__macro_local_6MemberfMu0_, __macro_local_14MutationResultfMu_>(
            keyPath: KeyPath<Feature, __macro_local_6MemberfMu0_>,
            _ mutation: () throws -> __macro_local_14MutationResultfMu_
          ) rethrows -> __macro_local_14MutationResultfMu_ {
            try _$perceptionRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu1_>(_ lhs: __macro_local_6MemberfMu1_, _ rhs: __macro_local_6MemberfMu1_) -> Bool {
            true
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu2_: Equatable>(_ lhs: __macro_local_6MemberfMu2_, _ rhs: __macro_local_6MemberfMu2_) -> Bool {
            lhs != rhs
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu3_: AnyObject>(_ lhs: __macro_local_6MemberfMu3_, _ rhs: __macro_local_6MemberfMu3_) -> Bool {
            lhs !== rhs
          }

          private nonisolated func shouldNotifyObservers<__macro_local_6MemberfMu4_: Equatable & AnyObject>(_ lhs: __macro_local_6MemberfMu4_, _ rhs: __macro_local_6MemberfMu4_) -> Bool {
            lhs != rhs
          }
        }
        """#
      }
    }
  }
#endif
