import Foundation
import SwiftData
import UniformTypeIdentifiers

@Model
final class MarkdownDocument {
    @Attribute(.unique) var id: UUID
    var name: String
    var markdown: String
    var importedAt: Date

    init(name: String, markdown: String) {
        id = UUID()
        self.name = name
        self.markdown = markdown
        importedAt = .now
    }
}

extension UTType {
    static let markdownDocument = UTType(importedAs: "net.daringfireball.markdown")
}

enum DocumentImport {
    static let maximumBytes = 5 * 1_024 * 1_024

    static func read(_ url: URL) throws -> MarkdownDocument {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: maximumBytes + 1) ?? Data()
        guard data.count <= maximumBytes else {
            throw ImportError.tooLarge
        }
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidEncoding
        }
        return MarkdownDocument(name: url.lastPathComponent, markdown: markdown)
    }

    enum ImportError: LocalizedError {
        case tooLarge
        case invalidEncoding

        var errorDescription: String? {
            switch self {
            case .tooLarge:
                "Choose a Markdown file smaller than or equal to 5 MB."
            case .invalidEncoding:
                "This file is not UTF-8 text. Save it as UTF-8 Markdown and try again."
            }
        }
    }
}
