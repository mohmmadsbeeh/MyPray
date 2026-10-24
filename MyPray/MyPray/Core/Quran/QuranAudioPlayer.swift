import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
public final class QuranAudioPlayer: ObservableObject {
    public static let shared = QuranAudioPlayer()

    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var isBuffering: Bool = false
    @Published public private(set) var currentSurah: Surah?
    @Published public private(set) var currentReciter: Reciter = Reciter.availableReciters[0]
    @Published public private(set) var currentTime: Double = 0.0
    @Published public private(set) var duration: Double = 0.0
    @Published public private(set) var progress: Double = 0.0
    @Published public var playbackError: String?

    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var playerItemStatusObserver: NSKeyValueObservation?

    private init() {
        configureAudioSession()
        setupRemoteCommandCenter()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
        } catch {
            #if DEBUG
            print("Failed to configure AVAudioSession for Quran playback: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Playback Controls

    public func playSurah(_ surah: Surah, reciter: Reciter? = nil) async {
        let chosenReciter = reciter ?? currentReciter
        self.currentReciter = chosenReciter
        self.currentSurah = surah
        self.isBuffering = true
        self.playbackError = nil

        do {
            let audioURL = try await QuranAPIService.shared.fetchChapterAudioUrl(
                recitationId: chosenReciter.recitationId,
                chapterId: surah.id
            )

            tearDownPlayer()

            let playerItem = AVPlayerItem(url: audioURL)
            self.avPlayer = AVPlayer(playerItem: playerItem)

            observePlayerItem(playerItem)
            addPeriodicTimeObserver()

            avPlayer?.play()
            self.isPlaying = true
            self.isBuffering = false

            updateNowPlayingInfo()
        } catch {
            self.isBuffering = false
            self.isPlaying = false
            self.playbackError = "Unable to stream recitation: \(error.localizedDescription)"
        }
    }

    public func togglePlayPause() {
        guard let player = avPlayer else { return }
        if isPlaying {
            player.pause()
            self.isPlaying = false
        } else {
            player.play()
            self.isPlaying = true
        }
        updateNowPlayingInfo()
    }

    public func seek(to newProgress: Double) {
        guard let player = avPlayer, duration > 0 else { return }
        let targetSeconds = newProgress * duration
        let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
        player.seek(to: targetTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }

    public func skip(seconds: Double) {
        guard let player = avPlayer else { return }
        let target = max(0, min(currentTime + seconds, duration))
        seek(to: duration > 0 ? target / duration : 0)
    }

    public func stop() {
        tearDownPlayer()
        self.isPlaying = false
        self.isBuffering = false
        self.currentSurah = nil
        self.currentTime = 0
        self.duration = 0
        self.progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    public func setReciter(_ reciter: Reciter) {
        self.currentReciter = reciter
        if let surah = currentSurah, isPlaying {
            Task {
                await playSurah(surah, reciter: reciter)
            }
        }
    }

    // MARK: - Observers & Lifecycle

    private func observePlayerItem(_ item: AVPlayerItem) {
        playerItemStatusObserver = item.observe(\.status, options: [.new, .old]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if playerItem.status == .readyToPlay {
                    self.duration = playerItem.duration.seconds.isFinite ? playerItem.duration.seconds : 0.0
                    self.isBuffering = false
                    self.updateNowPlayingInfo()
                } else if playerItem.status == .failed {
                    self.isBuffering = false
                    self.isPlaying = false
                    self.playbackError = playerItem.error?.localizedDescription ?? "Playback error"
                }
            }
        }
    }

    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = avPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if self.duration > 0 {
                self.progress = min(max(self.currentTime / self.duration, 0.0), 1.0)
            }
        }
    }

    private func tearDownPlayer() {
        if let token = timeObserverToken {
            avPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil
        avPlayer?.pause()
        avPlayer = nil
    }

    // MARK: - Lock Screen Media Controls (NowPlaying & RemoteCommand)

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
                return .success
            }
            return .commandFailed
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }

        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skip(seconds: 15)
            return .success
        }

        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skip(seconds: -15)
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        guard let surah = currentSurah else { return }
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = "Surah \(surah.nameSimple) (\(surah.nameArabic))"
        info[MPMediaItemPropertyArtist] = currentReciter.name
        info[MPMediaItemPropertyAlbumTitle] = "The Noble Quran"
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
