
import Foundation


struct GlobalDrawBounds: Equatable, CustomStringConvertible {
    let column: Int
    let row: Int
    let width: Int
    let height: Int
    
    init(column: Int, row: Int, width: Int, height: Int) {
        self.column = column
        self.row = row
        self.width = width
        self.height = height
    }
    
    init() {
        self.column = 0
        self.row = 0
        self.width = 0
        self.height = 0
    }
    
    func offset(columns: Int, rows: Int) -> GlobalDrawBounds {
        return GlobalDrawBounds(column: column + columns,
                                row: row + rows,
                                width: width,
                                height: height)
    }
    
    func offsetSize(columns: Int, rows: Int) -> GlobalDrawBounds {
        return GlobalDrawBounds(column: column,
                                row: row,
                                width: width + columns,
                                height: height + rows)
    }
    
    var isEmpty: Bool {
        return height <= 0 || width <= 0
    }
    
    func isFullyInside(_ other: GlobalDrawBounds) -> Bool {
        
        let verticalRange = other.row...other.row + other.height
        let horizontalRange = other.column...other.column + other.width
        // top inside
        guard verticalRange.contains(self.row) else {
            return false
        }
        
        guard verticalRange.contains(self.row + self.height) else {
            return false
        }
        
        guard horizontalRange.contains(self.column) else {
            return false
        }
        
        guard horizontalRange.contains(self.column + self.width) else {
            return false
        }
        
        return true
    }
    
    func isFullyOutside(_ other: GlobalDrawBounds) -> Bool {
        return !self.isFullyInside(other)
    }
    
    func clamped(to other: GlobalDrawBounds) -> GlobalDrawBounds {
        
        let horizontalRange = other.column...other.column + other.width
        let verticalRange = other.row...other.row + other.height
        
        let left = self.column.clamped(to: horizontalRange)
        let right = (self.column + self.width).clamped(to: horizontalRange)
        let top = self.row.clamped(to: verticalRange)
        let bottom = (self.row + self.height).clamped(to: verticalRange)
        
        return GlobalDrawBounds(column: left,
                                row: top,
                                width: right - left,
                                height: bottom - top)
    }
    
    func truncateToSize(size: DrawSize, horizontally horizontalDirective: ArrangeDirective, vertically verticalDirective: ArrangeDirective) -> GlobalDrawBounds {
        
        let xOffset: Int
        let yOffset: Int
        let width: Int
        let height: Int
        switch horizontalDirective {
            case .fill:
                xOffset = 0
                width = self.width
            case .alignStart:
                xOffset = 0
                width = min(size.width, self.width)
            case .alignEnd:
                xOffset = self.width-size.width
                width = min(size.width, self.width)
            case .alignCenter:
                xOffset = Int((Double(self.width-size.width)/2).rounded(.down))
                width = min(size.width, self.width)
        }
        
        switch verticalDirective {
            case .fill:
                yOffset = 0
                height = self.height
            case .alignStart:
                yOffset = 0
                height = min(size.height, self.height)
            case .alignEnd:
                yOffset = self.height-size.height
                height = min(size.height, self.height)
            case .alignCenter:
                yOffset = (self.height-size.height)/2
                height = min(size.height, self.height)
        }
        
        return GlobalDrawBounds(column: column + xOffset, row: row + yOffset, width: width, height: height)
    }
    
    func contains(x: Int, y: Int) -> Bool {
        return (column..<column+width).contains(x) && (row..<row+height).contains(y)
    }
    
    var description: String {
        return "GDB(\(column), \(row), \(width), \(height))"
    }
}
