import SwiftUI

public struct QuranSurahListView: View {
    @State private var surahs: [Surah] = []
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @ObservedObject private var player = QuranAudioPlayer.shared

    public init() {}

    private var filteredSurahs: [Surah] {
        if searchQuery.isEmpty {
            return surahs
        }
        return surahs.filter {
            $0.nameSimple.localizedCaseInsensitiveContains(searchQuery) ||
            $0.translatedName.localizedCaseInsensitiveContains(searchQuery) ||
            $0.nameArabic.contains(searchQuery) ||
            "\($0.id)".contains(searchQuery)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading Chapters...")
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                        Button("Retry") {
                            loadSurahs()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredSurahs) { surah in
                            NavigationLink {
                                QuranReaderView(surah: surah)
                            } label: {
                                surahRow(for: surah)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchQuery, prompt: "Search by number or name (e.g. Al-Kahf)")
                }
            }
            .safeAreaInset(edge: .bottom) {
                QuranMiniPlayerView()
            }
            .navigationTitle("Noble Quran")
            .task {
                loadSurahs()
            }
        }
    }

    private func surahRow(for surah: Surah) -> some View {
        HStack(spacing: 14) {
            // Surah Number Diamond / Circle
            ZStack {
                Circle()
                    .fill(Color(uiColor: .tertiarySystemFill))
                    .frame(width: 36, height: 36)

                Text("\(surah.id)")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            // Names & Revelation Type
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(surah.nameSimple)
                        .font(.headline)

                    Text(surah.revelationPlace.capitalized)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(surah.revelationPlace == "makkah" ? Color.orange.opacity(0.15) : Color.green.opacity(0.15))
                        .foregroundStyle(surah.revelationPlace == "makkah" ? Color.orange : Color.green)
                        .clipShape(Capsule())
                }

                Text("\(surah.translatedName) • \(surah.versesCount) Verses")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Arabic Name
            Text(surah.nameArabic)
                .font(.title3)
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 4)
    }

    private func loadSurahs() {
        self.isLoading = true
        self.errorMessage = nil

        Task {
            do {
                let list = try await QuranAPIService.shared.fetchChapters()
                await MainActor.run {
                    self.surahs = list
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load Quran: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
