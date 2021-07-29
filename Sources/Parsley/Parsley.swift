import Foundation
import cmark

public enum MarkdownError: Error {
  case conversionFailed
}

public struct Parsley {
  /// This parses a String into HTML, without parsing Metadata or the document title.
  public static func html(_ content: String, options: MarkdownOptions = [.safe]) throws -> String {
    var buffer: String?
    try content.withCString {
      guard let buf = cmark_gfm_markdown_to_html($0, Int(strlen($0)), options.rawValue) else {
        throw MarkdownError.conversionFailed
      }
      buffer = String(cString: buf)
      free(buf)
    }
    guard let output = buffer else {
      throw MarkdownError.conversionFailed
    }

    return output
  }

  /// This parses a String into a Document, which contains parsed Metadata and the document title.
  public static func parse(_ content: String, options: MarkdownOptions = [.safe]) throws -> Document {
    let rawBody = content

    let metadata = Parsley.metadata(from: "")
    let bodyHtml = try Parsley.html(rawBody, options: options).trimmingCharacters(in: .newlines)

    return Document(title: "", rawBody: rawBody, body: bodyHtml, metadata: metadata)
  }
}

private extension Parsley {
  /// Turns a string like `author: Kevin\ntags: Swift` into a dictionary:
  /// ["author": "Kevin", "tags": "Swift"]
  static func metadata(from content: String?) -> [String: String] {
    guard let content = content else {
      return [:]
    }

    let pairs = content
      .split(separator: "\n")
      .map { lines in
        lines
          .split(separator: ":", maxSplits: 1)
          .map {
            $0.trimmingCharacters(in: .whitespaces)
          }
      }
      .filter {
        $0.count == 2
      }
      .map {
        ($0[0], $0[1])
      }

    return Dictionary(pairs) { a, _ in a }
  }

}
