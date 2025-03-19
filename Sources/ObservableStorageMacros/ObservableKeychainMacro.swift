import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates property wrappers for observing changes in keychain storage.
///
/// The `ObservableKeychainMacro` allows developers to easily create properties that
/// are backed by the keychain and automatically observe changes to those properties.
///
/// This macro enforces that the property is declared as a variable, must be a main actor,
/// and checks for the necessary conditions, such as the presence of the `@ObservationIgnored` attribute.
/// It also validates the provided arguments and constructs the appropriate accessors.
public struct ObservableKeychainMacro: AccessorMacro {
    public static func expansion(of node: AttributeSyntax,
                                 providingAccessorsOf declaration: some DeclSyntaxProtocol,
                                 in _: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        // Ensure the declaration is a variable declaration and not a let constant
        guard let variableDeclaration = declaration.as(VariableDeclSyntax.self),
              variableDeclaration.bindingSpecifier.tokenKind == .keyword(.var) else {
            throw MacroError.notAVariable
        }
        
        // Check that there is exactly one binding in the variable declaration
        guard variableDeclaration.bindings.count == 1,
              let binding = variableDeclaration.bindings.first else {
            throw MacroError.multipleVariables
        }
        
        // Ensure the binding does not have an accessor block (i.e., it's not a computed property)
        guard binding.accessorBlock == nil else {
            throw MacroError.computedProperty
        }
        
        // Extract the pattern identifier from the binding
        guard let patternIdentifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            throw MacroError.notIdentifierPatternSyntax
        }
        
        // Ensure the variable has the 'MainActor' attribute
        guard variableDeclaration.attributes.contains(where: { "\($0.as(AttributeSyntax.self)?.attributeName ?? "")" == "MainActor" }) else {
            throw MacroError.isNotMainActor
        }
        
        // Ensure the variable has the 'ObservationIgnored' attribute
        guard variableDeclaration.attributes.contains(where: { "\($0.as(AttributeSyntax.self)?.attributeName ?? "")" == "ObservationIgnored" }) else {
            throw MacroError.isNotObservationIgnored
        }
        
        // Retrieve the arguments passed to the macro
        guard let arguments = node.arguments,
              let labeledExpressionList = arguments.as(LabeledExprListSyntax.self) else {
            throw MacroError.argumentsNotLabeledExpressionList
        }
        
        // Find the 'key' argument from the labeled expression list
        guard let keyExpression = labeledExpressionList.first(where: { $0.label?.text == "key" })?.expression else {
            throw MacroError.noKeyFoundInArguments
        }
        
        // Get the 'store' argument or default to '.shared'
        let storeExpression = labeledExpressionList.first { $0.label?.text == "store" }?.expression ?? ".shared"
        
        // Ensure no variable is not optional
        guard binding.typeAnnotation?.type.as(OptionalTypeSyntax.self) == nil else {
            throw MacroError.cannotBeOptional
        }
        
        // Ensure a default value exists
        guard let defaultValue = binding.initializer?.value else {
            throw MacroError.propertyHasNoDefaultValue
        }
            
        return makeAccessor(patternIdentifier: patternIdentifier, keyExpression: keyExpression, defaultValue: defaultValue, storeExpression: storeExpression)
    }
    
    private static func makeAccessor(patternIdentifier: TokenSyntax, keyExpression: ExprSyntax, defaultValue: ExprSyntax, storeExpression: ExprSyntax) -> [AccessorDeclSyntax] {
        let storeCode =
        if "\(storeExpression)".hasPrefix(".") {
                "KeychainManager\(storeExpression)"
            } else {
                "\(storeExpression)"
            }
        
        return [
            #"""
            get {
                access(keyPath: \.\#(patternIdentifier))
                return \#(raw: storeCode).get(\#(keyExpression)) ?? \#(defaultValue)
            }
            """#,
            #"""
            set {
                withMutation(keyPath: \.\#(patternIdentifier)) {
                    \#(raw: storeCode).set(newValue, forKey: \#(keyExpression))
                }
            }
            """#
        ]
    }
    
    private enum MacroError: Error, CustomStringConvertible {
        case notAVariable
        case multipleVariables
        case computedProperty
        case isNotMainActor
        case isNotObservationIgnored
        case propertyHasNoDefaultValue
        case cannotBeOptional
        case notIdentifierPatternSyntax
        case argumentsNotLabeledExpressionList
        case noKeyFoundInArguments
        
        var description: String {
            switch self {
            case .notAVariable:
                return "'@ObservableKeychain' can only be applied to variables"
            case .multipleVariables:
                return "'@ObservableKeychain' cannot be applied to multiple variable bindings"
            case .computedProperty:
                return "'@ObservableKeychain' cannot be applied to computed properties"
            case .isNotMainActor:
                return "'@ObservableKeychain' must have @MainActor applied"
            case .isNotObservationIgnored:
                return "'@ObservableKeychain' must have @ObservationIgnored applied"
            case .propertyHasNoDefaultValue:
                return "'@ObservableKeychain' arguments must provide default values"
            case .cannotBeOptional:
                return "'@ObservableKeychain' cannot be an optional"
            case .notIdentifierPatternSyntax:
                return "'@ObservableKeychain' can only be applied to a variables using simple declaration syntax"
            case .argumentsNotLabeledExpressionList:
                return "'@ObservableKeychain' can only have labeled arguments"
            case .noKeyFoundInArguments:
                return "'@ObservableKeychain' unable to find the key in the argument"
            }
        }
    }
}
