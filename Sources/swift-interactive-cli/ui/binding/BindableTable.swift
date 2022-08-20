import Foundation

import Foundation

class BindableTable: BoundDrawable {
    
    // TODO: THIS IS NOT REALLY IMPLEMENTED
    fileprivate let headers: [BoundDrawable]
    fileprivate let rows: [[BoundDrawable]]
    fileprivate var childDrawBounds: DrawBounds
    
    init(headers: [BoundDrawable], rows:[[BoundDrawable]]) {
        self.headers = headers
        self.rows = rows
        self.childDrawBounds = DrawBounds(headers: [], rows: [])
    }
    
    func draw(with screenWriter: BoundScreenWriter, in bounds: GlobalDrawBounds, force forced: Bool) -> DidRedraw {
        
        // check if we need a redraw
        let newDrawBounds = createDrawBounds(in: bounds)
        let childChanged = newDrawBounds != childDrawBounds
        childDrawBounds = newDrawBounds
        
        let forceRest = forced || childChanged
        
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
        
        if forceRest {
            
            let headerHeight = childDrawBounds.headers.map(\.drawBound.height).max() ?? 0
            let columnWidths = childDrawBounds.headers.map(\.drawBound.width)
            
            var currentRow = bounds.row
            
            let topLine = "╔" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╤") + "╗"
            screenWriter.print(topLine, column: bounds.column, row: currentRow)
            
            currentRow += 1
            
            // draw frames around headers
            for row in currentRow ..< currentRow + headerHeight {
                screenWriter.moveTo(bounds.column, row)
                screenWriter.printLineAtCursor("║")
                for headerWidth in childDrawBounds.headers.map(\.drawBound.width).dropLast() {
                    screenWriter.moveRight(by: headerWidth)
                    screenWriter.printLineAtCursor("│")
                }
                screenWriter.moveRight(by: childDrawBounds.headers.map(\.drawBound.width).last ?? 0)
                screenWriter.printLineAtCursor("║")
            }
            
            currentRow += 1
            
            let headerSeparator = "╠" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╪") + "╣"
            screenWriter.moveTo(bounds.column, currentRow)
            screenWriter.printLineAtCursor(headerSeparator)
            
            currentRow += 1
            
            for cellRowCursor in childDrawBounds.rows.enumerated() {
                let cellRow = cellRowCursor.element
                let rowHeight = cellRow.map(\.drawBound.height).max() ?? 0
                for row in currentRow ..< currentRow + rowHeight {
                    screenWriter.moveTo(bounds.column, row)
                    screenWriter.printLineAtCursor("║")
                    for cellWidth in cellRow.map(\.drawBound.width).dropLast() {
                        screenWriter.moveRight(by: cellWidth)
                        screenWriter.printLineAtCursor("│")
                    }
                    screenWriter.moveRight(by: cellRow.map(\.drawBound.width).last ?? 0)
                    screenWriter.printLineAtCursor("║")
                }
                
                currentRow += 1
                
                if cellRowCursor.offset < childDrawBounds.rows.count - 1 {
                    let dataSeparator = "╟" + columnWidths.map{Array(repeating: "─", count: $0).joined()}.joined(separator: "┼") + "╢"
                    screenWriter.moveTo(bounds.column, currentRow)
                    screenWriter.printLineAtCursor(dataSeparator)
                    currentRow += 1
                }

                
            }

            let bottomLine = "╚" + columnWidths.map{Array(repeating: "═", count: $0).joined()}.joined(separator: "╧") + "╝"
            
            screenWriter.moveTo(bounds.column, currentRow)
            screenWriter.printLineAtCursor(bottomLine)
        }
        
        
        let headerDrew = childDrawBounds.headers.map{header in
            header.drawable.draw(with: screenWriter.bound(to: header.drawBound), in: header.drawBound, force: forceRest)
        }
        
        let rowDrew = childDrawBounds.rows.map{row in
            row.map{ cell in
                cell.drawable.draw(with: screenWriter.bound(to: cell.drawBound), in: cell.drawBound, force: forceRest)
            }
        }.flatMap{$0}
        
        if (headerDrew + rowDrew).contains(.drew) {
            return .drew
        } else {
            return .skippedDraw
        }
    }
    
    func update(with cause: UpdateCause, in bounds: GlobalDrawBounds) -> RequiresRedraw {
        
        childDrawBounds = createDrawBounds(in: bounds)
        
        let headerUpdates = childDrawBounds.headers.map{header in
            header.drawable.update(with: cause, in: header.drawBound)
        }
        
        let rowUpdates = childDrawBounds.rows.map{row in
            row.map{ cell in
                cell.drawable.update(with: cause, in: cell.drawBound)
            }
        }.flatMap{$0}
        
        if (headerUpdates + rowUpdates).contains(.yes) {
            return .yes
        } else {
            return .no
        }
    }
    
    func getDrawBounds(given bounds: GlobalDrawBounds, with arrangeDirective: Arrange) -> GlobalDrawBounds {
        return bounds.truncateToSize(size: getMinimumSize(),
                                     horizontally: arrangeDirective.horizontal,
                                     vertically: arrangeDirective.vertical)
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
    
    func createDrawBounds(in bounds: GlobalDrawBounds) -> DrawBounds {
        let cells = rows.map{ row in
            row.map{$0.getMinimumSize()}
        }
        
        let columnWidths = headers.enumerated().map{ headerCursor -> Int in
            let maxCellWith = cells.map{$0[headerCursor.offset].width}.max() ?? 0
            return max(maxCellWith, headerCursor.element.getMinimumSize().width)
        }
        
        let headerHight = headers.map{$0.getMinimumSize().height}.max() ?? 0
        let rowHeights = cells.map { $0.map{$0.height}.max() ?? 0 }
        
        var headerDrawBounds: [DrawBound] = []
        var rowDrawBounds: [[DrawBound]] = []
        
        var col = bounds.column + 1
        var row = bounds.row + 1
        for cursor in headers.enumerated() {
            let childBounds = GlobalDrawBounds(column: col, row: row, width: columnWidths[cursor.offset], height: headerHight)
            
            headerDrawBounds.append(DrawBound(drawable: cursor.element, drawBound: childBounds))
            
            col += childBounds.width + 1
        }
        
        row += headerHight + 1
        
        for rowCursor in rows.enumerated() {
            col = bounds.column + 1
            rowDrawBounds.append([])
            for columnCursor in rowCursor.element.enumerated() {
                
                let childBounds = GlobalDrawBounds(column: col, row: row, width: columnWidths[columnCursor.offset], height: rowHeights[rowCursor.offset])
                
                rowDrawBounds[rowCursor.offset].append(DrawBound(drawable: columnCursor.element, drawBound: childBounds))
                
                col += childBounds.width + 1
            }
            row += rowHeights[rowCursor.offset] + 1
        }
        
        return DrawBounds(headers: headerDrawBounds, rows: rowDrawBounds)
        
        
    }
    
    struct DrawBounds: Equatable {
        let headers: [DrawBound]
        let rows: [[DrawBound]]
    }
    
    struct DrawBound: Equatable {
        static func == (lhs: BindableTable.DrawBound, rhs: BindableTable.DrawBound) -> Bool {
            return lhs.drawBound == rhs.drawBound && lhs.drawable === rhs.drawable
        }
        
        let drawable: BoundDrawable
        let drawBound: GlobalDrawBounds
    }
    
}

