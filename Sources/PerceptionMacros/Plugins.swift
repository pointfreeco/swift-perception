import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    PerceptibleMacro.self,
    PerceptionTrackedMacro.self,
    PerceptionIgnoredMacro.self,
  ]
}
