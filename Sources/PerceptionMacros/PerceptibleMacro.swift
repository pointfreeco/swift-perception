//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SwiftSyntax
import SwiftSyntaxMacros
import SwiftDiagnostics
import SwiftSyntaxBuilder

public struct PerceptibleMacro {
  static let moduleName = "Perception"

  static let conformanceName = "Perceptible"
  static var qualifiedConformanceName: String {
    return "\(moduleName).\(conformanceName)"
  }

  static var perceptibleConformanceType: TypeSyntax {
    "\(raw: qualifiedConformanceName)"
  }

  static let registrarTypeName = "PerceptionRegistrar"
  static var qualifiedRegistrarTypeName: String {
    return "\(moduleName).\(registrarTypeName)"
  }
  
  static let trackedMacroName = "PerceptionTracked"
  static let ignoredMacroName = "PerceptionIgnored"

  static let registrarVariableName = "_$perceptionRegistrar"
  
  static func registrarVariable(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    return
      """
      @\(raw: ignoredMacroName) private let \(raw: registrarVariableName) = \(raw: qualifiedRegistrarTypeName)()
      """
  }
  
  static func accessFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    return
      """
      internal nonisolated func access<\(memberGeneric)>(
        keyPath: KeyPath<\(perceptibleType), \(memberGeneric)>
      ) {
        \(raw: registrarVariableName).access(self, keyPath: keyPath)
      }
      """
  }
  
  static func withMutationFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    let mutationGeneric = context.makeUniqueName("MutationResult")
    return
      """
      internal nonisolated func withMutation<\(memberGeneric), \(mutationGeneric)>(
        keyPath: KeyPath<\(perceptibleType), \(memberGeneric)>,
        _ mutation: () throws -> \(mutationGeneric)
      ) rethrows -> \(mutationGeneric) {
        try \(raw: registrarVariableName).withMutation(of: self, keyPath: keyPath, mutation)
      }
      """
  }
  
  static func shouldNotifyObserversNonEquatableFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    return
      """
       private nonisolated func shouldNotifyObservers<\(memberGeneric)>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { true }
      """
  }
  
  static func shouldNotifyObserversEquatableFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    return
      """
      private nonisolated func shouldNotifyObservers<\(memberGeneric): Equatable>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs != rhs }
      """
  }
  
  static func shouldNotifyObserversNonEquatableObjectFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    return
      """
       private nonisolated func shouldNotifyObservers<\(memberGeneric): AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs !== rhs }
      """
  }

  static func shouldNotifyObserversEquatableObjectFunction(_ perceptibleType: TokenSyntax, context: some MacroExpansionContext) -> DeclSyntax {
    let memberGeneric = context.makeUniqueName("Member")
    return
      """
      private nonisolated func shouldNotifyObservers<\(memberGeneric): Equatable & AnyObject>(_ lhs: \(memberGeneric), _ rhs: \(memberGeneric)) -> Bool { lhs != rhs }
      """
  }

  static var ignoredAttribute: AttributeSyntax {
    AttributeSyntax(
      leadingTrivia: .space,
      atSign: .atSignToken(),
      attributeName: IdentifierTypeSyntax(name: .identifier(ignoredMacroName)),
      trailingTrivia: .space
    )
  }

  static var trackedAttribute: AttributeSyntax {
    AttributeSyntax(
      leadingTrivia: .space,
      atSign: .atSignToken(),
      attributeName: IdentifierTypeSyntax(name: .identifier(trackedMacroName)),
      trailingTrivia: .space
    )
  }
}

struct PerceptionDiagnostic: DiagnosticMessage {
  enum ID: String {
    case invalidApplication = "invalid type"
    case missingInitializer = "missing initializer"
  }
  
  var message: String
  var diagnosticID: MessageID
  var severity: DiagnosticSeverity
  
  init(message: String, diagnosticID: SwiftDiagnostics.MessageID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
    self.message = message
    self.diagnosticID = diagnosticID
    self.severity = severity
  }
  
  init(message: String, domain: String, id: ID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
    self.message = message
    self.diagnosticID = MessageID(domain: domain, id: id.rawValue)
    self.severity = severity
  }
}

extension DiagnosticsError {
  init<S: SyntaxProtocol>(syntax: S, message: String, domain: String = "Perception", id: PerceptionDiagnostic.ID, severity: SwiftDiagnostics.DiagnosticSeverity = .error) {
    self.init(diagnostics: [
      Diagnostic(node: Syntax(syntax), message: PerceptionDiagnostic(message: message, domain: domain, id: id, severity: severity))
    ])
  }
}


struct LocalMacroExpansionContext<Context: MacroExpansionContext> {
  var context: Context
}

extension DeclModifierListSyntax {
  func privatePrefixed(_ prefix: String, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> DeclModifierListSyntax {
    let modifier: DeclModifierSyntax = DeclModifierSyntax(name: "private", trailingTrivia: .space)
    return [modifier] + filter {
      switch $0.name.tokenKind {
      case .keyword(let keyword):
        switch keyword {
        case .fileprivate: fallthrough
        case .private: fallthrough
        case .internal: fallthrough
        case .package: fallthrough
        case .public:
          return false
        default:
          return true
        }
      default:
        return true
      }
    }
  }
  
  init(keyword: Keyword) {
    self.init([DeclModifierSyntax(name: .keyword(keyword))])
  }
}

extension TokenSyntax {
  func privatePrefixed(_ prefix: String, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> TokenSyntax {
    switch tokenKind {
    case .identifier(let identifier):
      return TokenSyntax(.identifier(prefix + identifier), leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia, presence: presence)
    default:
      return self
    }
  }
}

extension CodeBlockSyntax {
  func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> CodeBlockSyntax {
    guard let firstStatement = statements.first, let loc = context.context.location(of: firstStatement) else {
      return self
    }
    
    return CodeBlockSyntax(
      leadingTrivia: leadingTrivia,
      leftBrace: leftBrace,
      statements: CodeBlockItemListSyntax {
        "#sourceLocation(file: \(loc.file), line: \(loc.line))"
        statements
        "#sourceLocation()"
      },
      rightBrace: rightBrace,
      trailingTrivia: trailingTrivia
    )
  }
}


extension AccessorDeclSyntax {
  func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> AccessorDeclSyntax {
    return AccessorDeclSyntax(
      leadingTrivia: leadingTrivia,
      attributes: attributes,
      modifier: modifier,
      accessorSpecifier: accessorSpecifier,
      parameters: parameters,
      effectSpecifiers: effectSpecifiers,
      body: body?.locationAnnotated(in: context),
      trailingTrivia: trailingTrivia
    )
  }
}

extension AccessorBlockSyntax {
  func locationAnnotated(in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> AccessorBlockSyntax {
    switch accessors {
    case .accessors(let accessorList):
      let remapped = AccessorDeclListSyntax {
        for accessor in accessorList {
          accessor.locationAnnotated(in: context)
        }
      }
      return AccessorBlockSyntax(accessors: .accessors(remapped))
    case .getter(let codeBlockList):
      return AccessorBlockSyntax(accessors: .getter(codeBlockList))
    }
  }
}

extension PatternBindingListSyntax {
  func privatePrefixed(_ prefix: String, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> PatternBindingListSyntax {
    var bindings = self.map { $0 }
    for index in 0..<bindings.count {
      let binding = bindings[index]
      if let identifier = binding.pattern.as(IdentifierPatternSyntax.self) {
        bindings[index] = PatternBindingSyntax(
          leadingTrivia: binding.leadingTrivia,
          pattern: IdentifierPatternSyntax(
            leadingTrivia: identifier.leadingTrivia,
            identifier: identifier.identifier.privatePrefixed(prefix, in: context),
            trailingTrivia: identifier.trailingTrivia
          ),
          typeAnnotation: binding.typeAnnotation,
          initializer: binding.initializer,
          accessorBlock: binding.accessorBlock?.locationAnnotated(in: context),
          trailingComma: binding.trailingComma,
          trailingTrivia: binding.trailingTrivia)
        
      }
    }
    
    return PatternBindingListSyntax(bindings)
  }
}

extension VariableDeclSyntax {
  func privatePrefixed(_ prefix: String, addingAttribute attribute: AttributeSyntax, removingAttribute toRemove: AttributeSyntax, in context: LocalMacroExpansionContext<some MacroExpansionContext>) -> VariableDeclSyntax {
    let newAttributes = attributes.filter { attribute in
      switch attribute {
      case .attribute(let attr):
        attr.attributeName.identifier != toRemove.attributeName.identifier
      default: true
      }
    } + [.attribute(attribute)]
    return VariableDeclSyntax(
      leadingTrivia: leadingTrivia,
      attributes: newAttributes,
      modifiers: modifiers.privatePrefixed(prefix, in: context),
      bindingSpecifier: TokenSyntax(bindingSpecifier.tokenKind, leadingTrivia: .space, trailingTrivia: .space, presence: .present),
      bindings: bindings.privatePrefixed(prefix, in: context),
      trailingTrivia: trailingTrivia
    )
  }
  
  var isValidForPerception: Bool {
    !isComputed && isInstance && !isImmutable && identifier != nil
  }
}

extension PerceptibleMacro: MemberMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    providingMembersOf declaration: Declaration,
    conformingTo protocols: [TypeSyntax],
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let identified = declaration.asProtocol(NamedDeclSyntax.self) else {
      return []
    }
    
    let perceptibleType = identified.name.trimmed

    if declaration.isEnum {
      // enumerations cannot store properties
      throw DiagnosticsError(syntax: node, message: "'@Perceptible' cannot be applied to enumeration type '\(perceptibleType.text)'", id: .invalidApplication)
    }
    if declaration.isStruct {
      // structs are not yet supported; copying/mutation semantics tbd
      throw DiagnosticsError(syntax: node, message: "'@Perceptible' cannot be applied to struct type '\(perceptibleType.text)'", id: .invalidApplication)
    }
    if declaration.isActor {
      // actors cannot yet be supported for their isolation
      throw DiagnosticsError(syntax: node, message: "'@Perceptible' cannot be applied to actor type '\(perceptibleType.text)'", id: .invalidApplication)
    }
    
    var declarations = [DeclSyntax]()

    declaration.addIfNeeded(PerceptibleMacro.registrarVariable(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.accessFunction(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.withMutationFunction(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.shouldNotifyObserversNonEquatableFunction(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.shouldNotifyObserversEquatableFunction(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.shouldNotifyObserversNonEquatableObjectFunction(perceptibleType, context: context), to: &declarations)
    declaration.addIfNeeded(PerceptibleMacro.shouldNotifyObserversEquatableObjectFunction(perceptibleType, context: context), to: &declarations)

    return declarations
  }
}

extension PerceptibleMacro: MemberAttributeMacro {
  public static func expansion<
    Declaration: DeclGroupSyntax,
    MemberDeclaration: DeclSyntaxProtocol,
    Context: MacroExpansionContext
  >(
    of node: AttributeSyntax,
    attachedTo declaration: Declaration,
    providingAttributesFor member: MemberDeclaration,
    in context: Context
  ) throws -> [AttributeSyntax] {
    guard let property = member.as(VariableDeclSyntax.self), property.isValidForPerception,
          property.identifier != nil else {
      return []
    }

    // dont apply to ignored properties or properties that are already flagged as tracked
    if property.hasMacroApplication(PerceptibleMacro.ignoredMacroName) ||
       property.hasMacroApplication(PerceptibleMacro.trackedMacroName) {
      return []
    }
    
    
    return [
      AttributeSyntax(attributeName: IdentifierTypeSyntax(name: .identifier(PerceptibleMacro.trackedMacroName)))
    ]
  }
}

extension PerceptibleMacro: ExtensionMacro {
  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    // This method can be called twice - first with an empty `protocols` when
    // no conformance is needed, and second with a `MissingTypeSyntax` instance.
    if protocols.isEmpty {
      return []
    }

    #if compiler(>=6.2)
    let decl: DeclSyntax = """
        extension \(raw: type.trimmedDescription): nonisolated \(raw: qualifiedConformanceName), \
        nonisolated Observation.Observable {}
        """
    #else
    let decl: DeclSyntax = """
        extension \(raw: type.trimmedDescription): \(raw: qualifiedConformanceName), \
        Observation.Observable {}
        """
    #endif
    let ext = decl.cast(ExtensionDeclSyntax.self)

    if let availability = declaration.attributes.availability {
      return [ext.with(\.attributes, availability)]
    } else {
      return [ext]
    }
  }
}

public struct PerceptionTrackedMacro: AccessorMacro {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: Declaration,
    in context: Context
  ) throws -> [AccessorDeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self),
          property.isValidForPerception,
          let identifier = property.identifier?.trimmed else {
      return []
    }

    #if canImport(SwiftSyntax600)
    guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
      return []
    }
    #endif

    if property.hasMacroApplication(PerceptibleMacro.ignoredMacroName) {
      return []
    }

    let initAccessor: AccessorDeclSyntax =
      """
      @storageRestrictions(initializes: _\(identifier))
      init(initialValue) {
        _\(identifier) = initialValue
      }
      """
    let getAccessor: AccessorDeclSyntax =
      """
      get {
        _$perceptionRegistrar.access(self, keyPath: \\.\(identifier))
        return _\(identifier)
      }
      """

    // the guard else case must include the assignment else
    // cases that would notify then drop the side effects of `didSet` etc
    let setAccessor: AccessorDeclSyntax =
      """
      set {
        guard shouldNotifyObservers(_\(identifier), newValue) else {
          _\(identifier) = newValue
          return
        }
        withMutation(keyPath: \\.\(identifier)) {
          _\(identifier) = newValue
        }
      }
      """
      
    // Note: this accessor cannot test the equality since it would incur
    // additional CoW's on structural types. Most mutations in-place do
    // not leave the value equal so this is "fine"-ish.
    // Warning to future maintence: adding equality checks here can make
    // container mutation O(N) instead of O(1).
    // e.g. perceptible.array.append(element) should just emit a change
    // to the new array, and NOT cause a copy of each element of the
    // array to an entirely new array.
    let modifyAccessor: AccessorDeclSyntax =
      """
      _modify {
        access(keyPath: \\.\(identifier))
        \(raw: PerceptibleMacro.registrarVariableName).willSet(self, keyPath: \\.\(identifier))
        defer { \(raw: PerceptibleMacro.registrarVariableName).didSet(self, keyPath: \\.\(identifier)) }
        yield &_\(identifier)
      }
      """

    return [initAccessor, getAccessor, setAccessor, modifyAccessor]
  }
}

extension PerceptionTrackedMacro: PeerMacro {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: Declaration,
    in context: Context
  ) throws -> [DeclSyntax] {
    guard let property = declaration.as(VariableDeclSyntax.self),
          property.isValidForPerception,
          property.identifier?.trimmed != nil else {
      return []
    }

    #if canImport(SwiftSyntax600)
    guard context.lexicalContext[0].as(ClassDeclSyntax.self) != nil else {
      return []
    }
    #endif

    if property.hasMacroApplication(PerceptibleMacro.ignoredMacroName) {
      return []
    }
    
    let localContext = LocalMacroExpansionContext(context: context)
    let storage = DeclSyntax(property.privatePrefixed("_", addingAttribute: PerceptibleMacro.ignoredAttribute, removingAttribute: PerceptibleMacro.trackedAttribute, in: localContext))
    return [storage]
  }
}

public struct PerceptionIgnoredMacro: AccessorMacro {
  public static func expansion<
    Context: MacroExpansionContext,
    Declaration: DeclSyntaxProtocol
  >(
    of node: AttributeSyntax,
    providingAccessorsOf declaration: Declaration,
    in context: Context
  ) throws -> [AccessorDeclSyntax] {
    return []
  }
}
