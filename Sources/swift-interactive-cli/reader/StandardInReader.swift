import Foundation

class StandardInReader {
    
    private var old:termios
    
    //TODO: Maybe everything should be in a giant callback here so that we can enforce the stop command
    
    //Maybe check https://github.com/andybest/linenoise-swift/blob/master/Sources/linenoise/Terminal.swift
    // for more flags and raw mode
    
    // according to this https://man7.org/linux/man-pages/man3/tcflush.3.html
    // raw mode is turned on with
    //new.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON)
    //new.c_oflag &= ~OPOST
    //new.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN)
    //new.c_cflag &= ~(CSIZE | PARENB)
    //new.c_cflag |= CS8
    
    init() {
        old = termios()
        var new = termios()
        tcgetattr(STDIN_FILENO, &old)
        
        new = old
        // turn off buffering (ie all characters are read once available and not line by line)
        new.c_lflag &= ~(UInt(ICANON))
        // turn of auto echo
        new.c_lflag &= ~(UInt(ECHO))
        
        // set attributes now (TCSANOW)
        tcsetattr(STDIN_FILENO, TCSANOW, &new)
        
    }
    
    func terminate() {
        tcsetattr(STDIN_FILENO, TCSANOW, &old)
    }
    
    private func readByte() -> UInt8 {
        var input: UInt8 = 0
        _ = read(STDIN_FILENO, &input, 1)
        
        //log.addLine(text: "byte: \(String.init(input, radix: 16, uppercase: true))", style: .color(.ansi(.red)))
        return input
    }
    
    func readUnicodeScalar() -> Int {
        
        // implementation found at: https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/LineReader.swift#L340
        let byte1 = readByte()
        
        // Read unicode character and insert it at the cursor position using UTF8 encoding
        var scalar: UInt32? = nil
        if byte1 >> 7 == 0 {
            scalar = UInt32(byte1)
        } else if byte1 >> 5 == 0x6 {
            let byte2 = readByte()
            scalar = (UInt32(byte1 & 0x1F) << 6) | UInt32(byte2 & 0x3F)
        } else if byte1 >> 4 == 0xE {
            let byte2 = readByte()
            let byte3 = readByte()
            scalar = (UInt32(byte1 & 0xF) << 12) | (UInt32(byte2 & 0x3F) << 6) | UInt32(byte3 & 0x3F)
        } else if byte1 >> 3 == 0x1E {
            let byte2 = readByte()
            let byte3 = readByte()
            let byte4 = readByte()
            scalar = (UInt32(byte1 & 0x7) << 18) |
            (UInt32(byte2 & 0x3F) << 12) |
            (UInt32(byte3 & 0x3F) << 6) |
            UInt32(byte4 & 0x3F)
        }
        
        guard let scalar = scalar else {
            fatalError("the byte read was not 1,2,3 or four bytes")
        }

        return Int(scalar)
    }
}
