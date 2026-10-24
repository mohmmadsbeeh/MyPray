import SwiftUI

public struct KnowledgeArticleDetailView: View {
    public let article: KnowledgeArticle

    public init(article: KnowledgeArticle) {
        self.article = article
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Category badge & read time
                HStack {
                    Label(article.category.rawValue, systemImage: article.category.iconName)
                        .font(.caption.bold())
                        .foregroundStyle(Color.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Label("\(article.estimatedReadTimeMinutes) min read", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Title & Arabic subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(article.title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)

                    if let arabic = article.arabicSubtitle {
                        Text(arabic)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                // Source Citation Card
                if let ref = article.hadithReference {
                    HStack(spacing: 12) {
                        Image(systemName: "quote.opening")
                            .font(.title3)
                            .foregroundStyle(Color.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Source & Reference")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Text(ref)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(uiColor: .tertiarySystemFill))
                    )
                }

                // Markdown Body
                Text(.init(article.bodyMarkdown))
                    .font(.body)
                    .lineSpacing(7)
                    .foregroundStyle(.primary)
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
