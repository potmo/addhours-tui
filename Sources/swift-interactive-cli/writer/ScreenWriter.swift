import Foundation


class VirtualCursor {
    var column: Int
    var row: Int
    
    init(column: Int, row: Int) {
        self.column = column
        self.row = row
    }
    
}
class BoundScreenWriter {
    let writer: TerminalWriter
    let writeBounds: GlobalDrawBounds
    let cursor: VirtualCursor
    
    init(writer: TerminalWriter, writeBounds: GlobalDrawBounds, cursor: VirtualCursor){
        self.writer = writer
        self.writeBounds = writeBounds
        self.cursor = cursor
    }
    
    func bound(to drawBounds: GlobalDrawBounds) -> BoundScreenWriter {
        return BoundScreenWriter(writer: writer,
                                 writeBounds: drawBounds.clamped(to: writeBounds),
                                 cursor: cursor)
    }
    
    func moveTo(_ column: Int, _ row: Int) {
        guard !writeBounds.isEmpty else { return }
        cursor.column = column
        cursor.row = row
        writer.moveCursorTo(column: cursor.column, row: cursor.row)
    }
    
    func moveUp( by rows: Int = 1) {
        guard !writeBounds.isEmpty else { return }
        guard rows != 0 else {
            return
        }
        cursor.row -= rows
        writer.moveCursorUp(by: rows)
    }
    
    func moveDown( by rows: Int = 1) {
        guard !writeBounds.isEmpty else { return }
        guard rows != 0 else {
            return
        }
        cursor.row += rows
        writer.moveCursorDown(by: rows)
    }
    
    func moveLeft( by columns: Int = 1) {
        guard !writeBounds.isEmpty else { return }
        guard columns != 0 else {
            return
        }
        cursor.column -= columns
        writer.moveCursorLeft(by: columns)
    }
    
    func moveRight( by columns: Int = 1) {
        guard !writeBounds.isEmpty else { return }
        guard columns != 0 else {
            return
        }
        cursor.column += columns
        writer.moveCursorRight(by: columns)
    }
    
    func print(_ string:String, column: Int, row: Int) {
        guard !writeBounds.isEmpty else { return }
        string.lines.enumerated().forEach{
            moveTo(column, row + Int($0.offset))
            printLineAtCursor(String($0.element))
        }
    }
    
    func print(_ string:String, with style: TextStyle, column: Int, row: Int) {
        guard !writeBounds.isEmpty else { return }
        runWithinStyledBlock(with: style){
            print(string, column: column, row: row)
        }
    }
    
    func printLineAtCursor(_ string: String) {
        guard !writeBounds.isEmpty else { return }
        var croppedString = string
        
        // check if trying to write above bounds
        if cursor.row < writeBounds.row {
            moveRight(by: croppedString.count)
            //log.log("fully above \(croppedString)")
            return
        }
        
        // check if trying to write below bounds
        if (cursor.row >= writeBounds.row + writeBounds.height) {
            moveRight(by: croppedString.count)
            //log.log("fully below \(croppedString)")
            return
        }
        
        //check if fully to the left outside bounds
        if cursor.column + croppedString.count < writeBounds.column {
            moveRight(by: croppedString.count)
            //log.log("fully left \(croppedString)")
            return
        }
        
        //check if fully to the right outside bounds
        if cursor.column > writeBounds.column + writeBounds.width {
            moveRight(by: croppedString.count)
            //log.log("fully right \(croppedString)")
            return
        }
        
        var horizontalSkipBefore = 0
        var horizontalSkipAfter = 0
        
        // check if partially to the left outside bounds
        if cursor.column < writeBounds.column {
            
            let horizontalSkip = writeBounds.column - cursor.column
            let horizontalSkipIndex = croppedString.index(croppedString.startIndex, offsetBy: horizontalSkip)
            croppedString = String(croppedString.suffix(from: horizontalSkipIndex))
            horizontalSkipBefore = horizontalSkip
            //log.log("partially left: \(horizontalSkip)")
        }
        
        moveRight(by: horizontalSkipBefore)
        
        // check if partially to the right outside bounds
        if cursor.column + croppedString.count > writeBounds.column + writeBounds.width {
            let stringMaxLength = (writeBounds.column + writeBounds.width) - cursor.column
            let horizontalSkip = croppedString.count - stringMaxLength
            croppedString = String(croppedString.prefix(stringMaxLength))
            horizontalSkipAfter = horizontalSkip
        }
        
        //let debugString = Array<Int>(0..<croppedString.count).map{ _ in Int.random(in: 0...9)}.map{"\($0)"}.joined(separator: "")
        
        cursor.column += croppedString.count
        printRawLine(croppedString)
        moveRight(by: horizontalSkipAfter)
        
    }
    
    private func printRawLine(_ string: String) {
        writer.printRaw(string, flush: false)
    }
    
    func runWithinStyledBlock(with style: TextStyle, block: ()->Void) {
        guard !writeBounds.isEmpty else { return }
        printRawLine(style.openingEscapeSequence)
        block()
        printRawLine(style.closingEscapeSequence)
    }
    
}
class ScreenWriter {
    
    let writer: TerminalWriter
    init(writer: TerminalWriter) {
        self.writer = writer
    }
    
    func moveTo(_ column: Int, _ row: Int) {
        writer.moveCursorTo(column: column, row: row)
    }
    
    func moveUp( by rows: Int = 1) {
        writer.moveCursorUp(by: rows)
    }
    
    func moveDown(by rows:Int = 1) {
        writer.moveCursorDown(by: rows)
    }
    
    func moveLeft(by columns: Int = 1) {
        writer.moveCursorLeft(by: columns)
    }
    
    func moveRight(by columns: Int = 1) {
        writer.moveCursorRight(by: columns)
    }
    
    func printRaw(_ string: String) {
        writer.printRaw(string, flush: false)
    }
    
    func print(_ string:String, column: Int, row: Int) {
        string.lines.enumerated().forEach{
            moveTo(column, row + Int($0.offset))
            printRaw(String($0.element))
        }
    }
    
    func printEscaped(string: String) {
        writer.printEscaped(string, flush: false)
    }
    
    func flush() {
        writer.flushBuffer()
    }
    
    func fill( bounds: GlobalDrawBounds, with char: Character) {
        //TODO: It is maybe better to just allocate the entire row and then fill that once per row
        // instead of printing it character by character
        let filling = String(char)
        for row in bounds.row ..< (bounds.row+bounds.height) {
            moveTo(bounds.column, row)
            for _ in bounds.column ..< (bounds.column+bounds.width) {
                printRaw(filling)
            }
        }
    }
    
    func fill( bounds: GlobalDrawBounds, with char: Character, excluding exclusion: GlobalDrawBounds) {
        let filling = String(char)

        for row in bounds.row ..< (bounds.row+bounds.height) {
            var column = bounds.column
            moveTo(column, row)
            while column < bounds.column + bounds.width {
                if exclusion.contains(x: column, y: row) {
                    let jump = min(exclusion.column + exclusion.width, bounds.column + bounds.width) - exclusion.column
                    moveRight(by: jump)
                    column += jump
                } else {
                    printRaw(filling)
                    column += 1
                }
            }
        }
    }
    
    func fill( bounds: GlobalDrawBounds, with char: Character, excluding exclusion: [GlobalDrawBounds]) {
        let filling = String(char)
        moveTo(bounds.column, bounds.row)
        for row in bounds.row ..< (bounds.row+bounds.height) {
            //for var column = bounds.column ..< (bounds.column+bounds.width) {
            var column = bounds.column
            while column < bounds.column+bounds.width {
                if exclusion.contains(where: { $0.contains(x: column, y: row)}) {
                    //TODO: Figure out first possible jump spot
                    let jump = 1
                    moveRight(by: jump)
                    column += jump
                } else {
                    printRaw(filling)
                    column += 1
                }
            }
            moveDown(by: 1)
            moveLeft(by: bounds.width)
        }
    }
    
    func runWithinStyledBlock(with style: TextStyle, block: ()->Void) {
        printRaw(style.openingEscapeSequence)
        block()
        printRaw(style.closingEscapeSequence)
    }
}
