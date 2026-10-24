import SwiftUI

public enum QuranReaderMode: String, CaseIterable, Identifiable {
    case ayahByAyah = "Ayah"
    case wordByWord = "Word by Word"
    case mushafPage = "Page View"

    public var id: String { rawValue }
}

public struct QuranReaderView: View {
    public let surah: Surah

    @State private var selectedMode: QuranReaderMode = .ayahByAyah
    @State private var verses: [Verse] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @ObservedObject private var player = QuranAudioPlayer.shared

    public init(surah: Surah) {
        self.surah = surah
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode Picker
            Picker("Reader Mode", selection: $selectedMode) {
                ForEach(QuranReaderMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGroupedBackground))

            // Content Area
            ZStack {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading Surah \(surah.nameSimple)...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadVerses()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    switch selectedMode {
                    case .ayahByAyah:
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(verses) { verse in
                                    AyahRowView(verse: verse) { _ in
                                        Task {
                                            await player.playSurah(surah)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }

                    case .wordByWord:
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(verses) { verse in
                                    WordByWordView(verse: verse)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }

                    case .mushafPage:
                        MushafPageView(verses: verses)
                    }
                }
            }

            // Sticky Audio Mini Player
            QuranMiniPlayerView()
        }
        .navigationTitle("\(surah.id). \(surah.nameSimple)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Section("Audio Reciter") {
                        ForEach(Reciter.availableReciters) { reciter in
                            Button {
                                player.setReciter(reciter)
                            } label: {
                                HStack {
                                    Text(reciter.name)
                                    if player.currentReciter.id == reciter.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    Button {
                        Task {
                            await player.playSurah(surah)
                        }
                    } label: {
                        Label("Play Full Surah", systemImage: "play.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            loadVerses()
        }
    }

    private func loadVerses() {
        self.isLoading = true
        self.errorMessage = nil

        Task {
            do {
                let fetched = try await QuranAPIService.shared.fetchAllVerses(
                    chapterId: surah.id,
                    totalVerses: surah.versesCount
                )
                await MainActor.run {
                    self.verses = fetched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load verses: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
