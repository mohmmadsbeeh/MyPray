import Foundation
import SwiftData

public enum CalculationMethodOption: String, CaseIterable, Codable, Sendable {
    case muslimWorldLeague = "muslimWorldLeague"
    case isna = "isna"
    case ummAlQura = "ummAlQura"
    case egyptian = "egyptian"
    case karachi = "karachi"
    case dubai = "dubai"
    case kuwait = "kuwait"
    case qatar = "qatar"
    case singapore = "singapore"
    case turkey = "turkey"
    case tehran = "tehran"

    public var title: String {
        switch self {
        case .muslimWorldLeague: return "Muslim World League (MWL)"
        case .isna: return "Islamic Society of North America (ISNA)"
        case .ummAlQura: return "Umm al-Qura University, Makkah"
        case .egyptian: return "Egyptian General Authority of Survey"
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .dubai: return "Dubai (UAE)"
        case .kuwait: return "Kuwait"
        case .qatar: return "Qatar"
        case .singapore: return "MUIS, Singapore"
        case .turkey: return "Diyanet, Turkey"
        case .tehran: return "Institute of Geophysics, Tehran"
        }
    }
}

public enum MadhabOption: String, CaseIterable, Codable, Sendable {
    case shafi = "shafi"
    case hanafi = "hanafi"

    public var title: String {
        switch self {
        case .shafi: return "Standard (Shafi'i, Maliki, Hanbali)"
        case .hanafi: return "Hanafi"
        }
    }
}

public enum AdhanVoiceOption: String, CaseIterable, Codable, Sendable {
    case makkah = "adhan_makkah"
    case madinah = "adhan_madinah"
    case alafasy = "adhan_alafasy"
    case abdulbasit = "adhan_abdulbasit"
    case calmChime = "adhan_calm_chime"
    case silent = "silent"

    public var displayName: String {
        switch self {
        case .makkah: return "Makkah Al-Mukarramah"
        case .madinah: return "Al-Masjid An-Nabawi"
        case .alafasy: return "Mishary Rashid Alafasy"
        case .abdulbasit: return "Abdul Basit Abdus Samad"
        case .calmChime: return "Gentle Chime"
        case .silent: return "Silent"
        }
    }

    public var soundFileName: String? {
        switch self {
        case .silent: return nil
        case .calmChime: return "chime.caf"
        default: return "\(rawValue).caf"
        }
    }
}

@Model
public final class UserSettings {
    @Attribute(.unique) public var id: String
    public var calculationMethodRaw: String
    public var madhabRaw: String
    
    // Per-prayer timing manual calibration offsets (in minutes)
    public var fajrOffsetMinutes: Int
    public var dhuhrOffsetMinutes: Int
    public var asrOffsetMinutes: Int
    public var maghribOffsetMinutes: Int
    public var ishaOffsetMinutes: Int

    // Notifications & Alarms
    public var prePrayerNotificationMinutes: Int
    public var snoozeIntervalMinutes: Int
    public var fajrVoiceRaw: String
    public var dhuhrVoiceRaw: String
    public var asrVoiceRaw: String
    public var maghribVoiceRaw: String
    public var ishaVoiceRaw: String
    
    // Period / Excused Mode
    public var isPeriodModeActive: Bool
    public var periodModeStartedAt: Date?

    // Screen Time & App Blocking
    public var isScreenTimeBlockerEnabled: Bool
    public var screenTimeBlockDurationMinutes: Int

    // Location cache
    public var lastKnownLatitude: Double?
    public var lastKnownLongitude: Double?
    public var lastKnownCity: String?
    public var lastKnownCountry: String?

    public var calculationMethod: CalculationMethodOption {
        get { CalculationMethodOption(rawValue: calculationMethodRaw) ?? .muslimWorldLeague }
        set { calculationMethodRaw = newValue.rawValue }
    }

    public var madhab: MadhabOption {
        get { MadhabOption(rawValue: madhabRaw) ?? .shafi }
        set { madhabRaw = newValue.rawValue }
    }

    public func voice(for prayer: PrayerType) -> AdhanVoiceOption {
        let raw: String
        switch prayer {
        case .fajr: raw = fajrVoiceRaw
        case .dhuhr: raw = dhuhrVoiceRaw
        case .asr: raw = asrVoiceRaw
        case .maghrib: raw = maghribVoiceRaw
        case .isha: raw = ishaVoiceRaw
        }
        return AdhanVoiceOption(rawValue: raw) ?? .makkah
    }

    public func setVoice(_ voice: AdhanVoiceOption, for prayer: PrayerType) {
        switch prayer {
        case .fajr: fajrVoiceRaw = voice.rawValue
        case .dhuhr: dhuhrVoiceRaw = voice.rawValue
        case .asr: asrVoiceRaw = voice.rawValue
        case .maghrib: maghribVoiceRaw = voice.rawValue
        case .isha: ishaVoiceRaw = voice.rawValue
        }
    }

    public func offset(for prayer: PrayerType) -> Int {
        switch prayer {
        case .fajr: return fajrOffsetMinutes
        case .dhuhr: return dhuhrOffsetMinutes
        case .asr: return asrOffsetMinutes
        case .maghrib: return maghribOffsetMinutes
        case .isha: return ishaOffsetMinutes
        }
    }

    public func setOffset(_ minutes: Int, for prayer: PrayerType) {
        switch prayer {
        case .fajr: fajrOffsetMinutes = minutes
        case .dhuhr: dhuhrOffsetMinutes = minutes
        case .asr: asrOffsetMinutes = minutes
        case .maghrib: maghribOffsetMinutes = minutes
        case .isha: ishaOffsetMinutes = minutes
        }
    }

    public init(
        id: String = "primary_user_settings",
        calculationMethod: CalculationMethodOption = .muslimWorldLeague,
        madhab: MadhabOption = .shafi,
        fajrOffsetMinutes: Int = 0,
        dhuhrOffsetMinutes: Int = 0,
        asrOffsetMinutes: Int = 0,
        maghribOffsetMinutes: Int = 0,
        ishaOffsetMinutes: Int = 0,
        prePrayerNotificationMinutes: Int = 15,
        snoozeIntervalMinutes: Int = 10,
        fajrVoice: AdhanVoiceOption = .makkah,
        dhuhrVoice: AdhanVoiceOption = .madinah,
        asrVoice: AdhanVoiceOption = .alafasy,
        maghribVoice: AdhanVoiceOption = .makkah,
        ishaVoice: AdhanVoiceOption = .madinah,
        isPeriodModeActive: Bool = false,
        periodModeStartedAt: Date? = nil,
        isScreenTimeBlockerEnabled: Bool = false,
        screenTimeBlockDurationMinutes: Int = 30,
        lastKnownLatitude: Double? = nil,
        lastKnownLongitude: Double? = nil,
        lastKnownCity: String? = nil,
        lastKnownCountry: String? = nil
    ) {
        self.id = id
        self.calculationMethodRaw = calculationMethod.rawValue
        self.madhabRaw = madhab.rawValue
        self.fajrOffsetMinutes = fajrOffsetMinutes
        self.dhuhrOffsetMinutes = dhuhrOffsetMinutes
        self.asrOffsetMinutes = asrOffsetMinutes
        self.maghribOffsetMinutes = maghribOffsetMinutes
        self.ishaOffsetMinutes = ishaOffsetMinutes
        self.prePrayerNotificationMinutes = prePrayerNotificationMinutes
        self.snoozeIntervalMinutes = snoozeIntervalMinutes
        self.fajrVoiceRaw = fajrVoice.rawValue
        self.dhuhrVoiceRaw = dhuhrVoice.rawValue
        self.asrVoiceRaw = asrVoice.rawValue
        self.maghribVoiceRaw = maghribVoice.rawValue
        self.ishaVoiceRaw = ishaVoice.rawValue
        self.isPeriodModeActive = isPeriodModeActive
        self.periodModeStartedAt = periodModeStartedAt
        self.isScreenTimeBlockerEnabled = isScreenTimeBlockerEnabled
        self.screenTimeBlockDurationMinutes = screenTimeBlockDurationMinutes
        self.lastKnownLatitude = lastKnownLatitude
        self.lastKnownLongitude = lastKnownLongitude
        self.lastKnownCity = lastKnownCity
        self.lastKnownCountry = lastKnownCountry
    }
}
