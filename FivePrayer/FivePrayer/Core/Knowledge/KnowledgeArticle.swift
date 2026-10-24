import Foundation

public enum KnowledgeCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case khushu = "Khushu' & Focus"
    case fiqh = "Fiqh & Rulings"
    case hadith = "Hadith & Virtues"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .khushu: return "heart.fill"
        case .fiqh: return "book.closed.fill"
        case .hadith: return "quote.opening"
        }
    }
}

public struct KnowledgeArticle: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let category: KnowledgeCategory
    public let title: String
    public let arabicSubtitle: String?
    public let summary: String
    public let bodyMarkdown: String
    public let estimatedReadTimeMinutes: Int
    public let hadithReference: String?
    public let authorOrSource: String

    public init(
        id: String,
        category: KnowledgeCategory,
        title: String,
        arabicSubtitle: String? = nil,
        summary: String,
        bodyMarkdown: String,
        estimatedReadTimeMinutes: Int,
        hadithReference: String? = nil,
        authorOrSource: String
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.arabicSubtitle = arabicSubtitle
        self.summary = summary
        self.bodyMarkdown = bodyMarkdown
        self.estimatedReadTimeMinutes = estimatedReadTimeMinutes
        self.hadithReference = hadithReference
        self.authorOrSource = authorOrSource
    }
}
