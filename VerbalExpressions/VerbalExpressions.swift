//
//  VerbalExpressions.swift
//  VerbalExpressions
//
//  Created by Dominique d'Argent on 04/06/14.
//  Copyright (c) 2014 Dominique d'Argent. All rights reserved.
//

import Foundation

public func VerEx() -> VerbalExpressions {
    return VerbalExpressions()
}

public class VerbalExpressions {
    // stored properties
    var prefixes = ""
    var source = ""
    var suffixes = ""
    var options: NSRegularExpressionOptions = .AnchorsMatchLines

    // computed properties
    var pattern: String { return prefixes + source + suffixes }
    
    var regularExpression: NSRegularExpression! {
    get {
        var error: NSError?
        
        let regex = NSRegularExpression(pattern: pattern, options: options, error: &error)
        
        if (error != nil) {
            return nil
        }
        
        return regex
    }
    }

    // instance methods
    public func startOfLine(enabled: Bool = true) -> Self {
        prefixes = enabled ? "^" : ""

        return self
    }

    public func endOfLine(enabled: Bool = true) -> Self {
        suffixes = enabled ? "$" : ""

        return self
    }

    public func then(string: String) -> Self {
        return add("(?:\(sanitize(string)))")
    }

    // alias for then
    public func find(string: String) -> Self {
        return then(string)
    }

    public func maybe(string: String) -> Self {
        return add("(?:\(sanitize(string)))?")
    }
    
    public func anything() -> Self {
        return add("(?:.*)")
    }
    
    public func anythingBut(string: String) -> Self {
        return add("(?:[^\(sanitize(string))]*)")
    }

    public func something() -> Self {
        return add("(?:.+)")
    }

    public func somethingBut(string: String) -> Self {
        return add("(?:[^\(sanitize(string))]+)")
    }

    public func lineBreak() -> Self {
        return add("(?:(?:\n)|(?:\r\n))")
    }

    // alias for lineBreak
    public func br() -> Self {
        return lineBreak()
    }

    public func tab() -> Self {
        return add("\t")
    }

    public func word() -> Self {
        return add("\\w+")
    }
    
    public func anyOf(string: String) -> Self {
        return add("(?:[\(sanitize(string))])")
    }
    
    // alias for anyOf
    public func any(string: String) -> Self {
        return anyOf(string)
    }

    public func withAnyCase(enabled: Bool = true) -> Self {
        if enabled {
            return addModifier("i")
        }
        else {
            return removeModifier("i")
        }
    }
    
    public func searchOneLine(enabled: Bool = true) -> Self {
        if enabled {
            return removeModifier("m")
        }
        else {
            return addModifier("m")
        }
    }
    
    public func beginCapture() -> Self {
        suffixes += ")"
        
        return add("(")
    }
    
    public func endCapture() -> Self {
        suffixes = suffixes[suffixes.startIndex..<suffixes.endIndex.predecessor()]
        
        return add(")")
    }
    
    public func replace(string: String, template: String) -> String {
        let range = NSRange(location: 0, length: count(string.utf16))
        
        return regularExpression.stringByReplacingMatchesInString(string, options: nil, range: range, withTemplate: template)
    }
    
    public func replace(string: String, with: String) -> String {
        let range = NSRange(location: 0, length: count(string.utf16))
        let template = NSRegularExpression.escapedTemplateForString(with)
        
        return regularExpression.stringByReplacingMatchesInString(string, options: nil, range: range, withTemplate: template)
    }
    
    public func test(string: String) -> Bool {
        let range = NSRange(location: 0, length: count(string.utf16))
        
        if let result = regularExpression.firstMatchInString(string, options: nil, range: range) {
            return result.range.location != NSNotFound
        }

        return false
    }
    
    
    // internal methods
    
    func sanitize(string: String) -> String {
        return NSRegularExpression.escapedPatternForString(string)
    }
    
    func add(string: String) -> Self {
        source += string
        
        return self
    }
    
    func addModifier(modifier: Character) -> Self {
        if let option = option(forModifier: modifier) {
            options = options | option
        }
        
        return self
    }
    
    
    func removeModifier(modifier: Character) -> Self {
        if let option = option(forModifier: modifier) {
            options = options & ~option
        }
        
        return self
    }
    
    func option(forModifier modifier: Character) -> NSRegularExpressionOptions? {
        switch modifier {
        case "d": // UREGEX_UNIX_LINES
            return .UseUnixLineSeparators
        case "i": // UREGEX_CASE_INSENSITIVE
            return .CaseInsensitive
        case "x": // UREGEX_COMMENTS
            return .AllowCommentsAndWhitespace
        case "m": // UREGEX_MULTILINE
            return .AnchorsMatchLines
        case "s": // UREGEX_DOTALL
            return .DotMatchesLineSeparators
        case "u": // UREGEX_UWORD
            return .UseUnicodeWordBoundaries
        case "U": // UREGEX_LITERAL
            return .IgnoreMetacharacters
        default:
            fatalError("Unknown modifier")
        }
    }

}

extension VerbalExpressions: Printable {
    public var description: String { return pattern }
}


// Match operators
// Adapted from https://gist.github.com/JimRoepcke/d68dd41ee2fedc6a0c67
infix operator =~  { associativity left precedence 140 }
infix operator !=~ { associativity left precedence 140 }

public func =~(lhs: String, rhs: VerbalExpressions) -> Bool {
    return rhs.test(lhs)
}

public func !=~(lhs: String, rhs: VerbalExpressions) -> Bool {
    return !(lhs =~ rhs)
}
