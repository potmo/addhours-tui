import Foundation

extension String {
    
    var lines: [String]  {
        return self.components(separatedBy: .newlines)
    }
    
    func leftPadFit(with paddingChar: Character,
                    toFit maxChars: Int,
                    ellipsis: Bool = false) -> String {
        
        let fixed = self.lines.map{line in
            line.leftPadFitSingleLine(with: paddingChar, toFit: maxChars, ellipsis: ellipsis)
        }.joined(separator: "\n")
        
        return fixed
        
    }
    
    func leftPadFitSingleLine(with paddingChar: Character,
                              toFit maxChars: Int,
                              ellipsis: Bool = false) -> String {
        
        if self.count == maxChars {
            return self
        }
        if maxChars <= 0 {
            return ""
        }
        
        let paddingSize = max(0, maxChars - self.count)
        let padding = Array(repeating: String(paddingChar), count: paddingSize).joined()
        let padded = padding + self
        
        if (padded.count > maxChars && ellipsis){
            return padded.prefix(maxChars-1) + "…"
        }else if padded.count > maxChars {
            return String(padded.prefix(maxChars))
        }
        return padded
    }
    
    func rightPadFit(with paddingChar: Character,
                    toFit maxChars: Int,
                    ellipsis: Bool = false) -> String {
        
        let fixed = self.lines.map{line in
            line.rightPadFitSingleLine(with: paddingChar, toFit: maxChars, ellipsis: ellipsis)
        }.joined(separator: "\n")
        
        return fixed
        
    }
    
    func rightPadFitSingleLine(with paddingChar: Character,
                 toFit maxChars: Int,
                 ellipsis: Bool = false) -> String {
        
        
        if self.count == maxChars {
            return self
        }
        
        if maxChars <= 0 {
            return ""
        }
        
        let paddingSize = max(0, maxChars - self.count)
        let padding = Array(repeating: String(paddingChar), count: paddingSize).joined()
        let padded = self + padding
        
        if (padded.count > maxChars && ellipsis){
            return padded.prefix(maxChars-1) + "…"
        }else if padded.count > maxChars {
            return String(padded.prefix(maxChars))
        }
        return padded
    }
    
    func horizontalCenterPadFit(with paddingChar: Character,
                    toFit maxChars: Int,
                    ellipsis: Bool = false) -> String {
        
        let fixed = self.lines.map{line in
            return line.horizontalCenterPadFitSingleLine(with: paddingChar, toFit: maxChars, ellipsis: ellipsis)
        }.joined(separator: "\n")
        
        return fixed
        
    }
    
    func horizontalCenterPadFitSingleLine(with paddingChar: Character,
                  toFit maxChars: Int,
                  ellipsis: Bool = false) -> String {
        
        if self.count == maxChars {
            return self
        }
        
        if maxChars <= 0 {
            return ""
        }
        
        else if self.count < maxChars {
            let leftSize = Int((Double(max(0,maxChars - self.count)) / 2).rounded(.down))
            let rightSize = Int((Double(max(0,maxChars - self.count)) / 2).rounded(.up))
            let leftPadding = Array(repeating: String(paddingChar), count: leftSize).joined()
            let rightPadding = Array(repeating: String(paddingChar), count: rightSize).joined()
            return leftPadding + self + rightPadding
        } else if self.count > maxChars && maxChars >= 2 {
            return self.prefix(maxChars-1) + "…"
        } else {
            return "…"
        }
    }
    
    func topPadFit(with paddingChar: Character,
                   repeated width: Int,
                   toFit maxLines: Int) -> String {
        let paddingLine = Array(repeating: String(paddingChar), count: width).joined(separator: "")
        return topPadFit(withString: paddingLine, toFit: maxLines)
    }
    
    func topPadFit(withString paddingString: String,
                   toFit maxLines: Int) -> String {
        
        let lines = self.split(whereSeparator: \.isNewline)
        if lines.count > maxLines {
            return lines[0..<maxLines].joined(separator: "\n")
        }
        
        let paddingSize = max(0,maxLines - lines.count)
        let padding = Array(repeating: paddingString, count: paddingSize)
        
        return (padding + [self]).joined(separator: "\n")
    }
    
    func bottomPadFit(with paddingChar: Character,
                              repeated width: Int,
                              toFit maxLines: Int) -> String {
        let paddingLine = Array(repeating: String(paddingChar), count: width).joined(separator: "")
        return bottomPadFit(withString: paddingLine, toFit: maxLines)
    }
    
    func bottomPadFit(withString paddingString: String,
                      toFit maxLines: Int) -> String {
        
        if self.lines.count > maxLines{
            return self.lines[0..<maxLines].joined(separator: "\n")
        }
        
        let paddingSize = max(0,maxLines - self.lines.count)
        let padding = Array(repeating: paddingString, count: paddingSize)
        
        return ([self] + padding).joined(separator: "\n")
    }
    
    func verticalCenterPadFit(with paddingChar: Character,
                              repeated width: Int,
                              toFit maxLines: Int) -> String {
        let paddingLine = Array(repeating: String(paddingChar), count: width).joined(separator: "")
        return verticalCenterPadFit(withString: paddingLine, toFit: maxLines)
    }
        
    func verticalCenterPadFit(withString paddingString: String,
                              toFit maxLines: Int) -> String {
        let lines = self.lines
        
        // truncate
        if lines.count > maxLines {
            return lines[0..<maxLines].joined(separator: "\n")
        }
        
        let topPaddingSize = Int((Double(max(0,maxLines - lines.count)) / 2).rounded(.down))
        let bottomPaddingSize = Int((Double(max(0,maxLines - lines.count)) / 2).rounded(.up))
        
        let topPadding = Array(repeating: paddingString, count: topPaddingSize)
        let bottomPadding = Array(repeating: paddingString, count: bottomPaddingSize)
        
        return (topPadding + [self] + bottomPadding).joined(separator: "\n")
    }
}
