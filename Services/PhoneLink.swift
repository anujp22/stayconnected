import Foundation

// MARK: - Phone Link

/// Builds `tel:` / `sms:` URLs from a raw phone number string.
///
/// Unlike stripping every non-digit character, this preserves a leading `+`
/// so international numbers dial correctly, while removing spaces, dashes,
/// parentheses, and other formatting the URL schemes can't handle.
enum PhoneLink {
    enum Scheme: String {
        case tel
        case sms
    }

    /// Normalizes a raw phone number for use in a `tel:`/`sms:` URL.
    /// Keeps a single leading `+` and strips everything that isn't a digit.
    /// Returns `nil` when there are no digits to dial.
    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasPlus = trimmed.hasPrefix("+")
        let digits = trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        guard !digits.isEmpty else { return nil }

        return hasPlus ? "+" + digits : digits
    }

    /// Builds a URL for the given scheme, or `nil` if the number can't be dialed.
    static func url(_ scheme: Scheme, number: String) -> URL? {
        guard let normalized = normalize(number) else { return nil }
        return URL(string: "\(scheme.rawValue):\(normalized)")
    }
}
