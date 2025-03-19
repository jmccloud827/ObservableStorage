import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A macro that generates property wrappers for observing changes in `UserDefaults` storage.
///
/// The `ObservableAppStorageMacro` allows developers to easily create properties that
/// are backed by `UserDefaults` and automatically observe changes to those properties.
///
/// This macro ensures that the property is declared as a variable and checks for the
/// necessary conditions, such as the presence of the `@ObservationIgnored` attribute.
/// It also validates the provided arguments and constructs the appropriate accessors.
public struct ObservableAppStorageMacro: AccessorMacro {
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
        
        // Get the 'store' argument or default to '.standard'
        let storeExpression = labeledExpressionList.first { $0.label?.text == "store" }?.expression ?? ".standard"
        
        // Determine the type of the variable
        let variableType = binding.typeAnnotation?.type
        
        // Handle the case where the variable type is optional
        if let optionalVariableType = variableType?.as(OptionalTypeSyntax.self) {
            // Ensure no initializer exists for optional types
            guard binding.initializer == nil else {
                throw MacroError.optionalTypeShouldHasDefaultValue
            }
                
            return makeAccessor(patternIdentifier: patternIdentifier, variableType: optionalVariableType.wrappedType, keyExpression: keyExpression, defaultValue: nil, storeExpression: storeExpression)
        } else if let variableType {
            // Ensure a default value exists for non-optional types
            guard let defaultValue = binding.initializer?.value else {
                throw MacroError.nonOptionalPropertyHasNoDefaultValue
            }
                
            return makeAccessor(patternIdentifier: patternIdentifier, variableType: variableType, keyExpression: keyExpression, defaultValue: defaultValue, storeExpression: storeExpression)
        } else {
            throw MacroError.noTypeFound // Throw error if no type is found
        }
    }
    
    private static func makeAccessor(patternIdentifier: TokenSyntax, variableType: TypeSyntax, keyExpression: ExprSyntax, defaultValue: ExprSyntax?, storeExpression: ExprSyntax) -> [AccessorDeclSyntax] {
        let defaultValueCode =
            if let defaultValue {
                "?? \(defaultValue)"
            } else {
                ""
            }
        
        let storeCode =
        if "\(storeExpression)".hasPrefix(".") {
                "UserDefaults\(storeExpression)"
            } else {
                "\(storeExpression)"
            }
        
        return [
            #"""
            get {
                access(keyPath: \.\#(patternIdentifier))
                return \#(raw: storeCode).value(forKey: \#(keyExpression)) as? \#(variableType)\#(raw: defaultValueCode)
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
        case isNotObservationIgnored
        case nonOptionalPropertyHasNoDefaultValue
        case optionalTypeShouldHasDefaultValue
        case notIdentifierPatternSyntax
        case argumentsNotLabeledExpressionList
        case noKeyFoundInArguments
        case noTypeFound
        
        var description: String {
            switch self {
            case .notAVariable:
                return "'@ObservableAppStorage' can only be applied to variables"
            case .multipleVariables:
                return "'@ObservableAppStorage' cannot be applied to multiple variable bindings"
            case .computedProperty:
                return "'@ObservableAppStorage' cannot be applied to computed properties"
            case .isNotObservationIgnored:
                return "'@ObservableKeychain' must have @ObservationIgnored applied"
            case .nonOptionalPropertyHasNoDefaultValue:
                return "'@ObservableAppStorage' arguments on non-optional types must provide default values"
            case .optionalTypeShouldHasDefaultValue:
                return "'@ObservableAppStorage' arguments on optional types should not use default values"
            case .notIdentifierPatternSyntax:
                return "'@ObservableAppStorage' can only be applied to a variables using simple declaration syntax"
            case .argumentsNotLabeledExpressionList:
                return "'@ObservableAppStorage' can only have labeled arguments"
            case .noKeyFoundInArguments:
                return "'@ObservableAppStorage' unable to find the key in the argument"
            case .noTypeFound:
                return "'@ObservableAppStorage' unable to extract the type of the variable"
            }
        }
    }
}

@main
struct ObservableStoragePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ObservableAppStorageMacro.self,
        ObservableKeychainMacro.self
    ]
}
