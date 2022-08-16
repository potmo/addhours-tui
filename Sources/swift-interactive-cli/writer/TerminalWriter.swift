import Foundation

class TerminalWriter {
    func clearScreen() {
        printEscaped("[2J", flush: false)
    }
    
    func clearFromCursorToEndOfScreen() {
        printEscaped("[0J", flush: false)
    }
    
    func clearFromCursorToBeginningOfScreen() {
        printEscaped("[1J", flush: false)
    }
    
    func clearFromCursorToEndOfLine() {
        printEscaped("[0K", flush: false)
    }
    
    func clearFromCursorToStartOfLine() {
        printEscaped("[1K", flush: false)
    }
    
    func clearEntireLine() {
        printEscaped("[2K", flush: false)
    }
    
    func moveCursorToHome() {
        printEscaped("[H", flush: false)
    }
    
    func moveCursorUp(by lines: Int){
        printEscaped("[\(lines)A", flush: false)
    }
    
    func moveCursorDown(by lines: Int){
        printEscaped("[\(lines)B", flush: false)
    }
    
    func moveCursorRight(by columns: Int){
        printEscaped("[\(columns)C", flush: false)
    }
    
    func moveCursorLeft(by columns: Int){
        printEscaped("[\(columns)D", flush: false)
    }
    
    // https://sw.kovidgoyal.net/kitty/keyboard-protocol/
    func enterProgressiveEnhancementKeyMode() {
        // Note that all of these modes are not working in all terminals
        // some terminals like xterm2 doesnt allow them by default but
        // it needs to be enabled
        // Kitty supports all of them
        let disambigueEscapeCode = 0b1
        //let reportEventTypes = 0b10
        //let reportAlternateKeys = 0b100
        //let reportAllKeysAsEscapeCodes = 0b1000
        //let reportAssociatedText = 0b10000*/
        
        printEscaped("[>\(disambigueEscapeCode)u", flush: false)
    }
    
    func exitProgressiveEnhancementKeyMode() {
        printEscaped("[<u", flush: false)
    }
    
    func requestCurrentProgressiveEnhancementKeyMode() {
        printEscaped("[?u", flush: false)
    }
    
    //https://chromium.googlesource.com/apps/libapps/+/nassh-0.8.41/hterm/doc/ControlSequences.md
    func disableWraparound() {
        printEscaped("[?7l")
    }
    
    func enableWraparound() {
        printEscaped("[?7h")
    }
    
    func enterAllowOtherKeysMode() {
        printEscaped("[>4;2m", flush: false)
    }
    
    func exitAllowOtherKeysMode() {
        printEscaped("[>4;0m", flush: false)
    }
    
    func saveCursorPosition() {
        printEscaped("7", flush: false)
    }
    
    func restoreCursorPosition() {
        printEscaped("8", flush: false)
    }
    
    func moveCursorTo(column: Int, row: Int) {
        printEscaped("[\(row);\(column)H", flush: false)
    }
    
    func requestCursorPosition() {
        printEscaped("[6n", flush: false)
    }
    
    func hideCursor() {
        printEscaped("[?25l", flush: false)
    }
    
    func showCursor() {
        printEscaped("[?25h", flush: false)
    }
    
    func enterAlternativeScreenMode() {
        printEscaped("[?1047h", flush: false)
    }
    
    func exitAlternativeScreenMode() {
        printEscaped("[?1047l", flush: false)
    }
    
    func startRequestingMousePosition(){
        
        // https://tintin.mudhalla.net/info/xterm/
        
        // Enable Mouse Tracking Mode
        printEscaped("[?1000h", flush: false)
        
        // Enable highlight tracking mode
        printEscaped("[?1001h", flush: false)
        
        // Enable button mouse tracking mode
        printEscaped("[?1002h", flush: false)
        
        // Any-event tracking: Report all motion events
        printEscaped("[?1003h", flush: false)
        
        // Enable window focus tracking
        printEscaped("[?1004h", flush: false)
        
        // SGR mouse mode: Allows mouse coordinates of >223, preferred over RXVT mode
        printEscaped("[?1006h", flush: false)
    }
    
    func stopRequestingMousePosition(){
        printEscaped("[?1006l", flush: false)
        printEscaped("[?1004l", flush: false)
        printEscaped("[?1003l", flush: false)
        printEscaped("[?1002l", flush: false)
        printEscaped("[?1001l", flush: false)
        printEscaped("[?1000l", flush: false)
    }
    
    func bounceDockIndefinetly() {
        // Iterm2 propriatary escape code
        //https://iterm2.com/3.2/documentation-escape-codes.html
        printEscaped("]1337;RequestAttention=yes\u{0007}")
    }
    
    func bounceDockOnce() {
        // Iterm2 propriatary escape code
        //https://iterm2.com/3.2/documentation-escape-codes.html
        printEscaped("]1337;RequestAttention=once\u{0007}")
    }
    
    func bounceCancel() {
        // Iterm2 propriatary escape code
        //https://iterm2.com/3.2/documentation-escape-codes.html
        printEscaped("]1337;RequestAttention=no\u{0007}")
    }
    
    func stealFocus() {
        // Iterm2 propriatary escape code
        //https://iterm2.com/3.2/documentation-escape-codes.html
        printEscaped("]1337;StealFocus\u{0007}")
    }
    
    func printEscaped(_ string: String, flush: Bool = false) {
        printRaw("\u{001B}\(string)", flush: flush)
    }
    
    
    func printRaw( _ string: String, flush: Bool) {
        Swift.print(string, terminator: "")
        if (flush) {
            fflush(stdout)
        }
    }
    
  
    
    func flushBuffer() {
        fflush(stdout)
    }
}
