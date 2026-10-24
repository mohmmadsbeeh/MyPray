import Foundation
import CoreLocation

#if canImport(Adhan)
import Adhan
#endif

public struct DailyPrayerSchedule: Sendable {
    public let date: Date
    public let fajr: Date
    public let sunrise: Date
    public let dhuhr: Date
    public let asr: Date
    public let maghrib: Date
    public let isha: Date

    public var obligatoryPrayers: [(prayer: PrayerType, time: Date)] {
        [
            (.fajr, fajr),
            (.dhuhr, dhuhr),
            (.asr, asr),
            (.maghrib, maghrib),
            (.isha, isha)
        ]
    }

    public func time(for prayer: PrayerType) -> Date {
        switch prayer {
        case .fajr: return fajr
        case .dhuhr: return dhuhr
        case .asr: return asr
        case .maghrib: return maghrib
        case .isha: return isha
        }
    }

    public func window(for prayer: PrayerType, nextDayFajr: Date? = nil) -> (start: Date, end: Date) {
        switch prayer {
        case .fajr:
            return (start: fajr, end: sunrise)
        case .dhuhr:
            return (start: dhuhr, end: asr)
        case .asr:
            return (start: asr, end: maghrib)
        case .maghrib:
            return (start: maghrib, end: isha)
        case .isha:
            let defaultEnd = nextDayFajr ?? isha.addingTimeInterval(6 * 3600)
            return (start: isha, end: defaultEnd)
        }
    }
}

public final class PrayerTimeService {
    public static let shared = PrayerTimeService()

    public init() {}

    public func calculateSchedule(
        for date: Date = Date(),
        latitude: Double,
        longitude: Double,
        settings: UserSettings
    ) -> DailyPrayerSchedule {
        #if canImport(Adhan)
        let coordinates = Coordinates(latitude: latitude, longitude: longitude)
        var params: CalculationParameters

        switch settings.calculationMethod {
        case .muslimWorldLeague:
            params = CalculationMethod.muslimWorldLeague.params
        case .isna:
            params = CalculationMethod.northAmerica.params
        case .ummAlQura:
            params = CalculationMethod.ummAlQura.params
        case .egyptian:
            params = CalculationMethod.egyptian.params
        case .karachi:
            params = CalculationMethod.karachi.params
        case .dubai:
            params = CalculationMethod.dubai.params
        case .kuwait:
            params = CalculationMethod.kuwait.params
        case .qatar:
            params = CalculationMethod.qatar.params
        case .singapore:
            params = CalculationMethod.singapore.params
        case .turkey:
            params = CalculationMethod.turkey.params
        case .tehran:
            params = CalculationMethod.tehran.params
        }

        switch settings.madhab {
        case .shafi:
            params.madhab = .shafi
        case .hanafi:
            params.madhab = .hanafi
        }

        params.adjustments.fajr = Int(settings.fajrOffsetMinutes)
        params.adjustments.dhuhr = Int(settings.dhuhrOffsetMinutes)
        params.adjustments.asr = Int(settings.asrOffsetMinutes)
        params.adjustments.maghrib = Int(settings.maghribOffsetMinutes)
        params.adjustments.isha = Int(settings.ishaOffsetMinutes)

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        if let prayerTimes = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) {
            return DailyPrayerSchedule(
                date: date,
                fajr: prayerTimes.fajr,
                sunrise: prayerTimes.sunrise,
                dhuhr: prayerTimes.dhuhr,
                asr: prayerTimes.asr,
                maghrib: prayerTimes.maghrib,
                isha: prayerTimes.isha
            )
        }
        #endif

        // Standalone mathematical astronomical fallback
        return calculateFallbackSchedule(
            for: date,
            latitude: latitude,
            longitude: longitude,
            settings: settings
        )
    }

    public func currentPrayer(at date: Date = Date(), schedule: DailyPrayerSchedule) -> PrayerType? {
        if date >= schedule.isha {
            return .isha
        } else if date >= schedule.maghrib {
            return .maghrib
        } else if date >= schedule.asr {
            return .asr
        } else if date >= schedule.dhuhr {
            return .dhuhr
        } else if date >= schedule.fajr && date < schedule.sunrise {
            return .fajr
        }
        return nil
    }

    public func nextPrayer(
        at date: Date = Date(),
        schedule: DailyPrayerSchedule,
        tomorrowSchedule: DailyPrayerSchedule? = nil
    ) -> (prayer: PrayerType, time: Date, isTomorrow: Bool) {
        if date < schedule.fajr {
            return (.fajr, schedule.fajr, false)
        } else if date < schedule.dhuhr {
            return (.dhuhr, schedule.dhuhr, false)
        } else if date < schedule.asr {
            return (.asr, schedule.asr, false)
        } else if date < schedule.maghrib {
            return (.maghrib, schedule.maghrib, false)
        } else if date < schedule.isha {
            return (.isha, schedule.isha, false)
        } else {
            // Next prayer is tomorrow's Fajr
            let nextFajr = tomorrowSchedule?.fajr ?? schedule.fajr.addingTimeInterval(86400)
            return (.fajr, nextFajr, true)
        }
    }

    public func timeRemainingUntilNextPrayer(
        at date: Date = Date(),
        schedule: DailyPrayerSchedule,
        tomorrowSchedule: DailyPrayerSchedule? = nil
    ) -> TimeInterval {
        let next = nextPrayer(at: date, schedule: schedule, tomorrowSchedule: tomorrowSchedule)
        return max(0, next.time.timeIntervalSince(date))
    }

    public func formattedCountdown(
        at date: Date = Date(),
        schedule: DailyPrayerSchedule,
        tomorrowSchedule: DailyPrayerSchedule? = nil
    ) -> String {
        let remaining = timeRemainingUntilNextPrayer(at: date, schedule: schedule, tomorrowSchedule: tomorrowSchedule)
        let totalSeconds = Int(remaining)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public func currentPrayerWindowProgress(
        at date: Date = Date(),
        schedule: DailyPrayerSchedule,
        tomorrowSchedule: DailyPrayerSchedule? = nil
    ) -> Double {
        guard let current = currentPrayer(at: date, schedule: schedule) else {
            return 0.0
        }
        let window = schedule.window(for: current, nextDayFajr: tomorrowSchedule?.fajr)
        let totalDuration = window.end.timeIntervalSince(window.start)
        guard totalDuration > 0 else { return 0.0 }
        let elapsed = date.timeIntervalSince(window.start)
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }

    // MARK: - Standalone Astronomical Calculation Engine

    private func calculateFallbackSchedule(
        for date: Date,
        latitude: Double,
        longitude: Double,
        settings: UserSettings
    ) -> DailyPrayerSchedule {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // Solar Julian Day
        let jd = julianDate(from: startOfDay)
        let d = jd - 2451545.0

        // Mean anomaly and solar longitude
        let q = (280.459 + 0.98564736 * d).truncatingRemainder(dividingBy: 360.0)
        let g = (357.529 + 0.98560028 * d) * .pi / 180.0
        let l = (q + 1.915 * sin(g) + 0.020 * sin(2 * g)) * .pi / 180.0

        // Obliquity of ecliptic
        let e = (23.439 - 0.00000036 * d) * .pi / 180.0

        // Declination
        let sinDec = sin(e) * sin(l)
        let dec = asin(sinDec)

        // Equation of time (in minutes)
        let ra = atan2(cos(e) * sin(l), cos(l)) / 15.0 * 180.0 / .pi
        var eqTime = (q / 15.0 - ra) * 60.0
        while eqTime > 720 { eqTime -= 1440 }
        while eqTime < -720 { eqTime += 1440 }

        // Local noon (Solar transit)
        let timeZoneOffsetHours = Double(calendar.timeZone.secondsFromGMT(for: date)) / 3600.0
        let noonMinutes = 720.0 - (longitude * 4.0) - eqTime + (timeZoneOffsetHours * 60.0)

        let latRad = latitude * .pi / 180.0

        // Fajr angle depending on calculation method
        let fajrAngle: Double
        let ishaAngle: Double

        switch settings.calculationMethod {
        case .muslimWorldLeague:
            fajrAngle = 18.0; ishaAngle = 17.0
        case .isna:
            fajrAngle = 15.0; ishaAngle = 15.0
        case .ummAlQura:
            fajrAngle = 18.5; ishaAngle = 19.0
        case .egyptian:
            fajrAngle = 19.5; ishaAngle = 17.5
        case .karachi:
            fajrAngle = 18.0; ishaAngle = 18.0
        default:
            fajrAngle = 18.0; ishaAngle = 17.0
        }

        func hourAngle(forAltitude alpha: Double) -> Double? {
            let alphaRad = alpha * .pi / 180.0
            let cosH = (sin(alphaRad) - sin(latRad) * sin(dec)) / (cos(latRad) * cos(dec))
            if cosH < -1.0 || cosH > 1.0 { return nil }
            return acos(cosH) * 180.0 / .pi / 15.0 * 60.0 // in minutes
        }

        let fajrDiff = hourAngle(forAltitude: -fajrAngle) ?? 90.0
        let sunriseDiff = hourAngle(forAltitude: -0.833) ?? 72.0
        let maghribDiff = sunriseDiff
        let ishaDiff = hourAngle(forAltitude: -ishaAngle) ?? 90.0

        // Asr shadow length factor (1 = Shafi, 2 = Hanafi)
        let shadowFactor: Double = (settings.madhab == .hanafi) ? 2.0 : 1.0
        let asrAltitude = atan(1.0 / (shadowFactor + tan(abs(latRad - dec)))) * 180.0 / .pi
        let asrDiff = hourAngle(forAltitude: asrAltitude) ?? 60.0

        let fajrMin = noonMinutes - fajrDiff + Double(settings.fajrOffsetMinutes)
        let sunriseMin = noonMinutes - sunriseDiff
        let dhuhrMin = noonMinutes + Double(settings.dhuhrOffsetMinutes)
        let asrMin = noonMinutes + asrDiff + Double(settings.asrOffsetMinutes)
        let maghribMin = noonMinutes + maghribDiff + Double(settings.maghribOffsetMinutes)
        let ishaMin = noonMinutes + ishaDiff + Double(settings.ishaOffsetMinutes)

        return DailyPrayerSchedule(
            date: date,
            fajr: startOfDay.addingTimeInterval(fajrMin * 60.0),
            sunrise: startOfDay.addingTimeInterval(sunriseMin * 60.0),
            dhuhr: startOfDay.addingTimeInterval(dhuhrMin * 60.0),
            asr: startOfDay.addingTimeInterval(asrMin * 60.0),
            maghrib: startOfDay.addingTimeInterval(maghribMin * 60.0),
            isha: startOfDay.addingTimeInterval(ishaMin * 60.0)
        )
    }

    private func julianDate(from date: Date) -> Double {
        return date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }
}
