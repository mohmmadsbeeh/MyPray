import SwiftUI

public struct KnowledgeFeedView: View {
    @State private var selectedCategory: KnowledgeCategory? = nil
    @State private var searchQuery: String = ""

    public init() {}

    private var articles: [KnowledgeArticle] {
        let base = KnowledgeService.shared.fetchArticles(for: selectedCategory)
        if searchQuery.isEmpty {
            return base
        }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchQuery) ||
            $0.summary.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryPill(title: "All Topics", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }

                            ForEach(KnowledgeCategory.allCases) { category in
                                categoryPill(title: category.rawValue, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 6)

                    // Article Cards List
                    LazyVStack(spacing: 14) {
                        ForEach(articles) { article in
                            NavigationLink {
                                KnowledgeArticleDetailView(article: article)
                            } label: {
                                articleCard(for: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Islamic Knowledge")
            .searchable(text: $searchQuery, prompt: "Search Khushu', Fiqh, Hadith...")
        }
    }

    private func categoryPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.green : Color(uiColor: .secondarySystemBackground))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
    }

    private func articleCard(for article: KnowledgeArticle) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(article.category.rawValue, systemImage: article.category.iconName)
                    .font(.caption.bold())
                    .foregroundStyle(Color.green)

                Spacer()

                Text("\(article.estimatedReadTimeMinutes)m read")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text(article.title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let arabic = article.arabicSubtitle {
                Text(arabic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(article.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Text("By \(article.authorOrSource)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.green)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
