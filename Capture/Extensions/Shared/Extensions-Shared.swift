import Foundation
import CryptoKit
import CommonCrypto
import NaturalLanguage

extension Array {
    func shuffled() -> [Element] {
        if count < 2 { return self }
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            if i != j {
                list.swapAt(i, j)
            }
        }
        return list
    }

    // Creates an array containing all combinations of two arrays.
    static func createAllCombinations<T, U>(from lhs: Array<T>, and rhs: Array<U>) -> Array<(T, U)> {
        let result: [(T, U)] = lhs.reduce([]) { (accum, t) in
            let innerResult: [(T, U)] = rhs.reduce([]) { (innerAccum, u) in
                return innerAccum + [(t, u)]
            }
            return accum + innerResult
        }
        return result
    }

    mutating func move(from oldIndex: Index, to newIndex: Index) {
        // Don't work for free and use swap when indices are next to each other - this
        // won't rebuild array and will be super efficient.
        if oldIndex == newIndex { return }
        if abs(newIndex - oldIndex) == 1 { return self.swapAt(oldIndex, newIndex) }
        self.insert(self.remove(at: oldIndex), at: newIndex)
    }
}

extension Array where Element: Equatable {
    mutating func move(_ element: Element, to newIndex: Index) {
        if let oldIndex: Int = self.firstIndex(of: element) { self.move(from: oldIndex, to: newIndex) }
    }
}

extension Collection {
    subscript(optional i: Index) -> Iterator.Element? {
        return self.indices.contains(i) ? self[i] : nil
    }
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}

extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }

    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }

    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }

    // let d = Date() -> Mar 12, 2020 at 1:51 PM
    // d.stringify() -> "1584039099.486827"
    func stringify() -> String {
        return timeIntervalSince1970.stringValue()
    }

    // Date.unstringify("1584039099.486827") -> Mar 12, 2020 at 1:51 PM
    static func unstringify(_ ts: String) -> Date? {
        if let dbl = Double(ts) {
            return Date(timeIntervalSince1970: dbl)
        }
        return nil
    }

    func addMonth(n: Int) -> Date? {
        return Calendar.current.date(byAdding: .month, value: n, to: self)
    }

    func addDay(n: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: n, to: self)
    }
    
    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    var year: Int {
        return Calendar.current.component(.year, from: self)
    }

    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var startOfMonth: Date {
        let components = Calendar.current.dateComponents([.year, .month], from: startOfDay)
        return Calendar.current.date(from: components)!
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfMonth)!
    }

    func numberOfDaysInMonth() -> Int {
        let range = Calendar.current.range(of: .day, in: .month, for: self)!
        return range.count
    }

    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }

    var midnight: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var startOfWeek: Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))!
    }
}

extension Dictionary {
    // Combines self with another dictionary.
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}

extension Double {
    // It's dumb, but I swear I end up having to dump a number into some type
    // of storage that only accepts a String way more often than I care to think about.
    func stringValue() -> String {
        return String(format:"%f", self)
    }

    func formatAsCurrency() -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        return nf.string(from: NSNumber(floatLiteral: self))!
    }
}

extension FileManager {
    // Given a basename such as "My Picture" and fileExtension "jpg",
    // it will produce a unique, seqential filename such as "My Picuture 1.jpg"
    // that does not exist in directoryURL. If the directory already contained
    // "My Picuture.jpg", "My Picuture 1.jpg", "My Picuture 2.jpg", this will
    // return "My Picuture 3.jpg".
    func uniqueFileURL(directoryURL: URL, basename: String, fileExtension: String?) -> URL {
        var fullPathURL = directoryURL.appendingPathComponent(basename)
        if let ext = fileExtension {
            fullPathURL = fullPathURL.appendingPathExtension(ext)
        }

        var i = 0
        while FileManager.default.fileExists(atPath: fullPathURL.path) {
            i += 1
            let newBasename = "\(basename) \(i)"
            fullPathURL = directoryURL.appendingPathComponent(newBasename)
            if let ext = fileExtension {
                fullPathURL = fullPathURL.appendingPathExtension(ext)
            }
        }

        return fullPathURL
    }
}

extension NSAttributedString {
    // Haphazard solution that returns the range of a line of text at a given position,
    // where a line is delimited by newlines.
    func rangeOfLineAtLocation(_ location: Int) -> NSRange {
        if string.character(location).isNewline {
            var start = location
            while(start > 0 && !string.character(start - 1).isNewline) {
                start -= 1
            }
            return NSMakeRange(start, location-start)
        }
        
        var start: Int = location
        while(start > 0 && !string.character(start - 1).isNewline) {
            start -= 1
        }
        
        var end = location
        while(end < string.count - 1 && !string.character(end + 1).isNewline) {
            end += 1
        }
        
        return NSMakeRange(start, end - start)
    }
    
    func attributedStringByTrimmingCharacterSet(charSet: CharacterSet) -> NSAttributedString {
        let modifiedString = NSMutableAttributedString(attributedString: self)
        modifiedString.trimCharactersInSet(charSet: charSet)
        return NSAttributedString(attributedString: modifiedString)
    }
}

extension NSMutableAttributedString {
    func trimCharactersInSet(charSet: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: charSet as CharacterSet)

        // Trim leading characters from character set.
        while range.length != 0 && range.location == 0 {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet)
        }

        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        while range.length != 0 && NSMaxRange(range) == length {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: charSet, options: .backwards)
        }
    }
}

extension NSNotification.Name {
    func post(_ object: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: self, object: object, userInfo: userInfo)
    }
}

extension NSRange {
    init?(string: String, lowerBound: String.Index, upperBound: String.Index) {
        let utf16 = string.utf16

        if let lowerBound = lowerBound.samePosition(in: utf16), let upperBound = upperBound.samePosition(in: utf16) {
            let location = utf16.distance(from: utf16.startIndex, to: lowerBound)
            let length = utf16.distance(from: lowerBound, to: upperBound)

            self.init(location: location, length: length)
        }
        return nil
    }

    init?(range: Range<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }

    init?(range: ClosedRange<String.Index>, in string: String) {
        self.init(string: string, lowerBound: range.lowerBound, upperBound: range.upperBound)
    }
}

extension String {
    // An incredibly lenient and forgiving way to get a numeric String
    // out of another string - typically one provided by the user.
    // You shouldn't rely on this for anything truly mission critical.
    func numberString() -> String? {
        let strippedStr = trimmingCharacters(in: .whitespacesAndNewlines)
        let isNegative = strippedStr.hasPrefix("-")
        let allowedCharSet = CharacterSet(charactersIn: ".,0123456789")
        let filteredStr = components(separatedBy: allowedCharSet.inverted).joined()
        if (count(of: ".") + count(of: ",")) > 1 { return nil }
        return (isNegative ? "-" : "") + filteredStr
    }

    // Number of times a character occurs within a string.
    func count(of needle: Character) -> Int {
        return reduce(0) {
            $1 == needle ? $0 + 1 : $0
        }
    }

    // Returns an array of substrings delimited by whitespace - and also
    // combines tokens inside matching quotes into a single token. I don't
    // claim this to be pefect in every edge case - but I haven't encountered
    // a bug yet 🤷‍♀️.
    // "My name is Tim Apple".tokenize() -> ["My", "name", "is", "Tim", "Apple"]
    // "I hope the \"SF Giants\" have a \"better season\" this year" -> ["I", "hope", "the", "SF Giants", "have", "a", "better season", "this", "year"]
    @available(OSX 10.15, iOS 13, *)
    func tokenize() -> [String] {
        enum State {
            case Normal
            case InsideAQuote
        }
        
        let theString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var tokens = [String]()
        var state = State.Normal
        let delimeters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\""))
        let quote = CharacterSet(charactersIn: "\"")

        let scanner = Scanner(string: theString)
        scanner.charactersToBeSkipped = .none
        
        while !scanner.isAtEnd {
            if state == .Normal {
                if let token = scanner.scanCharacters(from: delimeters.inverted) {
                    tokens.append(token.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if let delims = scanner.scanCharacters(from: delimeters) {
                    if delims.hasSuffix("\"") {
                        state = .InsideAQuote
                    }
                }
            } else {
                if let token = scanner.scanCharacters(from: quote.inverted) {
                    tokens.append(token.trimmingCharacters(in: .whitespacesAndNewlines))
                    state = .Normal
                }
            }
        }

        return tokens
    }

    func number() -> NSNumber? {
        let amountStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let nf = NumberFormatter()
        
        nf.numberStyle = .currency
        if let num = nf.number(from: amountStr) {
            return num
        }

        nf.numberStyle = .none
        if let num = nf.number(from: amountStr) {
            return num
        }

        return nil
    }

    func formatAsCurrency() -> String? {
        return number()?.doubleValue.formatAsCurrency()
    }

    func substring(to : Int) -> String {
        let toIndex = self.index(self.startIndex, offsetBy: to)
        return String(self[...toIndex])
    }

    func substring(from : Int) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: from)
        return String(self[fromIndex...])
    }

    func substring(_ r: Range<Int>) -> String {
        let fromIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let toIndex = self.index(self.startIndex, offsetBy: r.upperBound)
        let indexRange = Range<String.Index>(uncheckedBounds: (lower: fromIndex, upper: toIndex))
        return String(self[indexRange])
    }

    func character(_ at: Int) -> Character {
        return self[self.index(self.startIndex, offsetBy: at)]
    }

    func lastIndexOfCharacter(_ c: Character) -> Int? {
        guard let index = range(of: String(c), options: .backwards)?.lowerBound else { return nil }
        return distance(from: startIndex, to: index)
    }

    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    
    func lowerTrimmed() -> String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func keyVal() -> (String, String?)? {
        if let colonIndex = self.firstIndex(of: ":") {
            let key = self[..<colonIndex]
            let val = self[self.index(colonIndex, offsetBy: 1)...]
            return (String(key).trimmingCharacters(in: .whitespacesAndNewlines), String(val).trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            return nil
        }
    }

    var sha256: String {
        let data = Data(self.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: [.dotMatchesLineSeparators]) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [.withoutAnchoringBounds], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map {
                result.range(at: $0).location != NSNotFound
                    ? nsString.substring(with: result.range(at: $0))
                    : ""
            }
        }
    }

    // right is the first encountered string after left
    func between(_ left: String, _ right: String) -> String? {
        guard let leftRange = range(of: left) else { return nil }
        guard let rightRange = range(of: right, options: .backwards) else { return nil }
        guard leftRange.upperBound <= rightRange.lowerBound else { return nil }

        let sub = self[leftRange.upperBound...]
        let closestToLeftRange = sub.range(of: right)!
        return String(sub[..<closestToLeftRange.lowerBound])
    }

    func nsRange(from range: Range<Index>) -> NSRange {
        guard let lower = UTF16View.Index(range.lowerBound, within: utf16) else { return .init() }
        guard let upper = UTF16View.Index(range.upperBound, within: utf16) else { return .init() }
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: lower), length: utf16.distance(from: lower, to: upper))
    }

    func lemmatize() -> [String] {
        let tagger = NSLinguisticTagger(tagSchemes: [.lemma], options: 0)
        tagger.string = self
        let range = NSMakeRange(0, self.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation]

        var results = [String]()
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { (tag, tokenRange, stop) in
            if let lemma = tag?.rawValue {
                results.append(lemma)
            }
        }

        return (results.count > 0) ? [self] : results
    }
}

extension String {
    struct Summary {
        var characters = 0
        var nonWhitespaceCharacters = 0
        var words = 0
        var sentences = 0
        var lines = 0
        var averageReadingTime: TimeInterval = 0
        var aloudReadingTime: TimeInterval = 0
    }

    var summary: Summary {
        var s = Summary(characters: countCharacters(),
                       nonWhitespaceCharacters: countNonWhitespaceCharacters(),
                       words: countWords(),
                       sentences: countSentences(),
                       lines: countLines())
        s.averageReadingTime = calculateAverageReadingTime(words: s.words)
        s.aloudReadingTime = calculateAloudReadingTime(words: s.words)
        return s
    }
    
    // https://digest.bps.org.uk/2019/06/13/most-comprehensive-review-to-date-suggests-the-average-persons-reading-speed-is-slower-than-commonly-thought/
    func calculateAverageReadingTime(words: Int) -> TimeInterval {
        return TimeInterval(words) / 238.0 * 60.0
    }

    // https://www.visualthesaurus.com/cm/wc/seven-ways-to-write-a-better-speech/
    func calculateAloudReadingTime(words: Int) -> TimeInterval {
        return TimeInterval(words) / 125.0 * 60.0
    }

    func countCharacters() -> Int {
        return count
    }

    func countNonWhitespaceCharacters() -> Int {
        components(separatedBy: CharacterSet.whitespacesAndNewlines).joined().count
    }

    func countWords() -> Int {
        let words = components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    func countSentences() -> Int {
        let s = self
        var r = [Range<String.Index>]()
        let t = s.linguisticTags(in: s.startIndex..<s.endIndex, scheme: NSLinguisticTagScheme.lexicalClass.rawValue, tokenRanges: &r)
        var result = [String]()
        let ixs = t.enumerated().filter { $0.1 == "SentenceTerminator" }.map { r[$0.0].lowerBound }
        var prev = s.startIndex
        for ix in ixs {
            let r = prev...ix
            result.append(s[r].trimmingCharacters(in: NSCharacterSet.whitespaces))
            prev = s.index(after: ix)
        }
        return result.count
    }

    func countLines() -> Int {
        return components(separatedBy: .newlines).count
    }
}

extension TimeInterval {
    // let foo: TimeInterval = 6227
    // foo.durationString() -> "2h"
    // foo.durationString(2) -> "1h 44m"
    // foo.durationString(3) -> "1h 43m 47s"
    func durationString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 1
        return formatter.string(from: self)!
    }
}

extension URL {
    var isAccessibleFile: Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        if !exists || isDir.boolValue {
            return false
        }
        return FileManager.default.isReadableFile(atPath: self.path)
    }

    var isAccessibleDirectory: Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir)
        if !exists || !isDir.boolValue {
            return false
        }
        return FileManager.default.isReadableFile(atPath: self.path)
    }

    func dumbGET(_ results: ((Data?) -> ())? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: self)
                results?(data)
            } catch {
                results?(nil)
            }
        }
    }
}
