import Foundation

class Table: Drawable {
    fileprivate let headers: [Drawable]
    fileprivate let rows: [[Drawable]]
    fileprivate let headerMinSizes: [DrawSize]
    fileprivate let rowMinSizes: [[DrawSize]]
    
    init(headers: [Drawable], rows:[[Drawable]]) {
        self.headers = headers
        self.rows = rows
        self.headerMinSizes = headers.map{$0.getMinimumSize()}
        self.rowMinSizes = rows.map{row in row.map{$0.getMinimumSize()}}
    }
    
    func draw(cause: DrawCause,
              in bounds: GlobalDrawBounds,
              with screenWriter: ScreenWriter,
              horizontally horizontalDirective: ArrangeDirective,
              vertically verticalDirective: ArrangeDirective) -> DrawSize {
        
        // check if we need a redraw
        let currentMinHeaders = headers.map{$0.getMinimumSize()}
        let currentMinRows = rows.map{row in row.map{$0.getMinimumSize()}}
        let childChanged = headerMinSizes != currentMinHeaders || rowMinSizes != currentMinRows
            
        let childCause = cause == .forced || childChanged ? .forced : cause
        
        let cells = rows.map{ row in
            row.map{$0.getMinimumSize()}
        }
        
        let columnWidths = headers.enumerated().map{ headerCursor -> Int in
            let maxCellWith = cells.map{$0[headerCursor.offset].width}.max() ?? 0
            return max(maxCellWith, headerCursor.element.getMinimumSize().width)
        }
        
        let headerHight = headers.map{$0.getMinimumSize().height}.max() ?? 0
        let rowHeights = cells.map { $0.map{$0.height}.max() ?? 0 }
        
        
        /*
         TODO: Use a templete like this to draw the lines
        let template =
        """
        ╔═╤╗
        ║H│║
        ╠═╪╣
        ║1│║
        ╟─┼╢
        ║2│║
        ╚═╧╝
        """
        */
        
        // Draw the frame
        // but exit early if nothing changed
        if childCause == .forced {
            
            let topLine = "╔" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╤") + "╗"
            
            let singleHeaderLine = "║" + headers
                .enumerated()
                .map{Array(repeating: " ", count: columnWidths[$0.offset]).joined()}
                .joined(separator: "│") + "║"
            
            let headerLine = Array(repeating: singleHeaderLine, count: headerHight).joined(separator: "\n")
            
            let headerSeparator = "╠" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╪") + "╣"
            
            let dataLine = "║" + headers
                .enumerated()
                .map{Array(repeating: " ", count: columnWidths[$0.offset]).joined()}
                .joined(separator: "│") + "║"
            
            let dataSeparator = "╟" + columnWidths.map{Array(repeating: "─", count: $0).joined()}.joined(separator: "┼") + "╢"
            
            let datas = rows
                .enumerated()
                .map{ [Array(repeating: dataLine, count: rowHeights[$0.offset]).joined(separator: "\n")] }
                .joined(separator: [dataSeparator]).joined(separator: "\n")
            
            let bottomLine = "╚" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╧") + "╝"
            
            let table = [topLine, headerLine, headerSeparator, datas, bottomLine].joined(separator: "\n")
            
            screenWriter.print(table, column: bounds.column, row: bounds.row)
        }
        
        // fill in the actual data
        var col = bounds.column + 2
        var row = bounds.row + 1
        for cursor in headers.enumerated() {
            let childBounds = GlobalDrawBounds(column: col, row: row, width: columnWidths[cursor.offset], height: headerHight)
            _ = cursor.element.draw(cause: childCause, in: childBounds, with: screenWriter, horizontally: .alignStart, vertically: .alignEnd)
            col += childBounds.width + 1
        }
        
        row += headerHight + 1
        
        for rowCursor in rows.enumerated() {
            col = bounds.column + 2
            for columnCursor in rowCursor.element.enumerated() {
                let childBounds = GlobalDrawBounds(column: col, row: row, width: columnWidths[columnCursor.offset], height: rowHeights[rowCursor.offset])
                _ = columnCursor.element.draw(cause: childCause, in: childBounds, with: screenWriter, horizontally: .alignStart, vertically: .alignEnd)
                col += childBounds.width + 1
            }
            row += rowHeights[rowCursor.offset] + 1
        }
        
        let size = getMinimumSize()
        return size
    }
    
    func getMinimumSize() -> DrawSize {
        let horizontalFrameLines = 1 + headers.count
        let verticalFrameLines = 1 + 1 + rows.count
        
        let cells = rows.map{ row in
            row.map{$0.getMinimumSize()}
        }
        
        let columnWidths = headers.enumerated().map{ headerCursor -> Int in
            let maxCellWith = cells.map{$0[headerCursor.offset].width}.max() ?? 0
            return max(maxCellWith, headerCursor.element.getMinimumSize().width)
        }
        
        let tableContentMinWidth = columnWidths.reduce(0, +)
        
        let headerMinHeight = headers.map{$0.getMinimumSize().height}.max() ?? 0
        
        let rowMinHeight = rows.map{row in
            row.map{ $0.getMinimumSize().height}.max() ?? 0
        }.reduce(0, +)

        return DrawSize(width: tableContentMinWidth + horizontalFrameLines,
                        height: headerMinHeight + rowMinHeight + verticalFrameLines)
    }
    
}
