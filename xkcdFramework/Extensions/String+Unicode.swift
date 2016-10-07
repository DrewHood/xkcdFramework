//
//  String+Unicode.swift
//  xkcd
//
//  Created by Drew Hood on 9/22/16.
//  Copyright © 2016 Drew R. Hood. All rights reserved.
//

import Foundation

extension String {
    enum StringUnicodeError: Error {
        case malformedUnicode
        case unknown
    }
    
    private func convertFromUtf8(hexStr: String) throws -> String {
        var outStr: String = ""
        var counter = 0
        var n = 0
        
        for str in hexStr.components(separatedBy: " ") {
            let uint = UInt(str, radix: 16)!
            let int = Int(uint)
            
            switch counter {
            case 0:
                if 0 <= int && int <= 0x7f {
                    guard let scalarStr = UnicodeScalar(int)?.description else { throw StringUnicodeError.malformedUnicode }
                    outStr += scalarStr
                } else if 0xC0 <= int && int <= 0xDF {
                    counter = 1
                    n = int & 0x1f
                } else if 0xE0 <= int && int <= 0xEF {
                    counter = 2
                    n = int & 0xf
                } else if 0xF0 <= int && int <= 0xF7 {
                    counter = 3
                    n = int & 0x7
                } else {
                    print("FAIL")
                }
                break
            case 1:
                if int < 0x80 || int > 0xBF {
                    print("FAIL 2")
                }
                
                counter -= 1
                let x = (n << 6) | (int - 0x80)
                guard let scalarStr = UnicodeScalar(x)?.description else { throw StringUnicodeError.malformedUnicode }
                outStr += scalarStr
                
                n = 0
                break
            case 2, 3:
                if int < 0x80 || int > 0xBF {
                    print("FAIL3")
                }
                
                n = (n << 6) | (int - 0x80)
                counter -= 1
                break
            default:
                throw StringUnicodeError.unknown
            }
        }
        
        return outStr
    }
    
    func decodeUtf8() throws -> String {
        var input = self
        var more = true
        
        let marker = "\\u00"
        
        while more {
            let inputStr = input.substring(from: input.startIndex)
            if let firstMatchRange: Range = inputStr.range(of: "\\\(marker)\\S{2}", options: .regularExpression, range: nil, locale: nil) {
                let begin = inputStr.index(firstMatchRange.upperBound, offsetBy: -2)
                var hexStr = inputStr.substring(with: Range(uncheckedBounds: (lower: begin, upper: firstMatchRange.upperBound)))
                
                var moreInThisChunk = true
                
                var minBound = firstMatchRange.upperBound
                var chunkCount = 1
                while moreInThisChunk {
                    if let nextChunkRangeUpper = inputStr.index(minBound, offsetBy: 6, limitedBy: inputStr.endIndex) {
                        let nextChunkRange = Range(uncheckedBounds: (lower: minBound, upper: nextChunkRangeUpper))
                        let nextChunk = inputStr.substring(with: nextChunkRange)
                        
                        // Do the next characters match the marker?
                        if let nextMatchRange: Range = nextChunk.range(of: "\\\(marker)\\S{2}", options: .regularExpression, range: nil, locale: nil) {
                            chunkCount += 1
                            if chunkCount == 3 {
                                moreInThisChunk = false
                            }
                            
                            // Do this again.
                            let nextbegin = nextChunk.index(nextMatchRange.upperBound, offsetBy: -2)
                            let nexthex = nextChunk.substring(with: Range(uncheckedBounds: (lower: nextbegin, upper: nextMatchRange.upperBound)))
                            
                            // add to fixed
                            hexStr += " \(nexthex)"
                            
                            // Move to the next chunk
                            minBound = nextChunkRangeUpper
                            
                        } else { moreInThisChunk = false }
                        
                    } else { moreInThisChunk = false }
                    
                }
                
                // Completed chunk — translate and replace
                do {
                    let fixedStr = try self.convertFromUtf8(hexStr: hexStr)
                    
                    let endIndex = input.index(firstMatchRange.lowerBound, offsetBy: (6 * chunkCount))
                    let totalRange = Range(uncheckedBounds: (lower: firstMatchRange.lowerBound, upper: endIndex))
                    print(totalRange)
                    input.replaceSubrange(totalRange, with: fixedStr)
                } catch StringUnicodeError.malformedUnicode {
                    throw StringUnicodeError.malformedUnicode
                } catch {
                    throw StringUnicodeError.unknown
                }
                
            } else {
                more = false
            }
            
        }
        
        return input
    }
}
