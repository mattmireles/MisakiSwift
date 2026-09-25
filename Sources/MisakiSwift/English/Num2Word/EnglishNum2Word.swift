import Foundation

/// Converts numbers to English words, converted from num2words Python package and from Num2Word_EN class
struct EnglishNum2Word {
  enum ConversionFormat {
    case ordinal
    case ordinalNum
    case decimal
    case year
  }
  
  private let negWord = "minus "
  private let pointWord = "point"
  private let excludeTitle = ["and", "point", "minus"]
  
  /// Indexed by `number / 10`; only indices 2...9 are used.
  private let tensWords = [
    "", "", "twenty", "thirty", "forty",
    "fifty", "sixty", "seventy", "eighty", "ninety"
  ]
  
  private let lowNumWords = [
    "twenty", "nineteen", "eighteen", "seventeen",
    "sixteen", "fifteen", "fourteen", "thirteen",
    "twelve", "eleven", "ten", "nine", "eight",
    "seven", "six", "five", "four", "three", "two",
    "one", "zero"
  ]
  
  private let ords: [String: String] = [
    "one": "first", "two": "second", "three": "third",
    "four": "fourth", "five": "fifth", "six": "sixth",
    "seven": "seventh", "eight": "eighth", "nine": "ninth",
    "ten": "tenth", "eleven": "eleventh", "twelve": "twelfth"
  ]
  
  /// Scale words from largest to smallest, e.g. (1_000_000, "million") before (1000, "thousand").
  private let scales: [(Int, String)]
  
  init() {
    // Initialize high number words
    var scales: [(Int, String)] = []
    let highWords = ["m", "b", "tr", "quadr", "quint", "sext", "sept", "oct", "non", "dec"]
    for (index, word) in highWords.enumerated() {
      let power = 6 + (index * 3)
      let val = pow(10.0, Double(power))
      if val <= Double(Int.max) {
        let intVal: Int = Int(val)
        scales.append((intVal, word + "illion"))
      } else {
        // Currently really, really large numbers are not handled
      }
    }
    scales.append((1000, "thousand"))
    self.scales = scales.sorted { $0.0 > $1.0 }
  }
  
  private func toOrdinal(_ decimalNumber: Decimal) -> String {
    let number = NSDecimalNumber(decimal: decimalNumber).intValue
    guard number > 0 else { return "" }
    
    var outWords = toCardinal(number).components(separatedBy: " ")
    var lastWords = outWords[outWords.count - 1].components(separatedBy: "-")
    var lastWord = lastWords[lastWords.count - 1].lowercased()
    
    if let ordinalWord = ords[lastWord] {
      lastWord = ordinalWord
    } else {
      if lastWord.hasSuffix("y") {
        lastWord = String(lastWord.dropLast()) + "ie"
      }
      lastWord += "th"
    }
    
    lastWords[lastWords.count - 1] = lastWord.capitalized
    outWords[outWords.count - 1] = lastWords.joined(separator: "-")
    return outWords.joined(separator: " ")
  }
  
  private func toOrdinalNum(_ decimalNumber: Decimal) -> String {
    let number = NSDecimalNumber(decimal: decimalNumber).intValue
    let ordinal = toOrdinal(decimalNumber)
    if ordinal.count >= 2 {
      let suffix = String(ordinal.suffix(2))
      return "\(number)\(suffix)"
    } else {
      return ""
    }
  }
  
  private func toCardinal(_ number: Int) -> String {
    if number < 0 {
      return negWord + toCardinal(abs(number))
    }
    
    if number < 21 {
      return lowNumWords[20 - number]
    }
    
    // Handle numbers from 21-99
    if number < 100 {
      let tensWord = tensWords[number / 10]
      let ones = number % 10
      return ones == 0 ? tensWord : "\(tensWord)-\(lowNumWords[20 - ones])"
    }
    
    // Handle hundreds
    if number < 1000 {
      let hundreds = number / 100
      let remainder = number % 100
      let hundredsWord = toCardinal(hundreds) + " hundred"
      if remainder == 0 {
        return hundredsWord
      } else {
        return "\(hundredsWord) and \(toCardinal(remainder))"
      }
    }
    
    // Handle thousands and higher
    for (value, word) in scales where number >= value {
      let quotientWord = toCardinal(number / value)
      let remainder = number % value
      if remainder == 0 {
        return "\(quotientWord) \(word)"
      } else {
        return "\(quotientWord) \(word), \(toCardinal(remainder))"
      }
    }
    
    return ""
  }
  
  private func toYear(_ yearDecimal: Decimal, suffix: String? = nil, longVal: Bool = true) -> String {
    let year = NSDecimalNumber(decimal: yearDecimal).intValue
    var val = year
    var finalSuffix = suffix
    
    if val < 0 {
      val = abs(val)
      finalSuffix = finalSuffix ?? "BC"
    }
    
    let high = val / 100
    let low = val % 100
    
    let valText: String
    // If year is 00XX, X00X, or beyond 9999, go cardinal
    if high == 0 || (high % 10 == 0 && low < 10) || high >= 100 {
      valText = toCardinal(val)
    } else {
      let highText = toCardinal(high)
      let lowText: String
      if low == 0 {
        lowText = "hundred"
      } else if low < 10 {
        lowText = "oh-\(toCardinal(low))"
      } else {
        lowText = toCardinal(low)
      }
      valText = "\(highText) \(lowText)"
    }
    
    if let suffix = finalSuffix {
      return "\(valText) \(suffix)"
    } else {
      return valText
    }
  }
  
  private func toDecimal(_ number: Decimal) -> String {
    let integerPart = NSDecimalNumber(decimal: number).intValue
    let fractionalPart = number - Decimal(integerPart)
    
    if fractionalPart == 0 {
      return toCardinal(integerPart)
    }
    
    let integerWords = toCardinal(integerPart)
    
    // Remove "0."
    let fractionalString = "\(fractionalPart)".dropFirst(2)
    let fractionalWords = fractionalString.map { toCardinal(Int(String($0)) ?? 0) }.joined(separator: " ")
    
    return "\(integerWords) \(pointWord) \(fractionalWords)"
  }
  
  /// Converts a number representing year, oridnal number or a decimal (integer numbers included) to words
  func convert(_ number: Decimal, to format: ConversionFormat = .decimal) -> String {
    switch format {
    case .ordinal:
      return toOrdinal(number)
    case .ordinalNum:
      return toOrdinalNum(number)
    case .year:
      return toYear(number)
    case .decimal:
      return toDecimal(number)
    }
  }
}
