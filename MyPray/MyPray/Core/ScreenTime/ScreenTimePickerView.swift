import SwiftUI
import DeviceActivity
#if canImport(FamilyControls)
import FamilyControls
#endif

public struct ScreenTimePickerView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isPickerPresented: Bool = false
    @State private var isBlockerEnabled: Bool = false
    @State private var selectedDuration: Int = 30
    @State private var showingUnlockAlert: Bool = false

    private let durationOptions = [15, 30, 45, 60]

    public init() {}

    public var body: some View {
        Form {
            // MARK: - Authorization Section
            Section {
                HStack(spacing: 16) {
                    Image(systemName: screenTimeManager.isAuthorized ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(screenTimeManager.isAuthorized ? Color.green : Color.orange)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(screenTimeManager.isAuthorized ? "Screen Time Connected" : "Permission Required")
                            .font(.headline)

                        Text(screenTimeManager.isAuthorized
                             ? "Apps will be shielded during prayer times."
                             : "MyPray needs FamilyControls permission to shield distracting apps.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)

                if !screenTimeManager.isAuthorized {
                    Button {
                        Task {
                            await screenTimeManager.requestAuthorization()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Authorize Screen Time", systemImage: "lock.shield.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            } header: {
                Text("Authorization")
            }

            // MARK: - Blocker Configuration
            if screenTimeManager.isAuthorized {
                Section {
                    Toggle(isOn: $isBlockerEnabled) {
                        Label("Enable Prayer App Shield", systemImage: "hourglass")
                    }
                    .onChange(of: isBlockerEnabled) { _, newValue in
                        SwiftDataStore.shared.updateSettings { settings in
                            settings.isScreenTimeBlockerEnabled = newValue
                        }
                        if !newValue {
                            screenTimeManager.stopAllPrayerMonitoring()
                        }
                    }

                    Picker("Shield Duration", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) minutes").tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedDuration) { _, newValue in
                        SwiftDataStore.shared.updateSettings { settings in
                            settings.screenTimeBlockDurationMinutes = newValue
                        }
                        ScreenTimeAppGroupBridge.shared.setBlockDurationMinutes(newValue)
                    }
                } header: {
                    Text("Rules & Duration")
                } footer: {
                    Text("Apps will be automatically shielded when the Adhan calls and remain blocked for the chosen duration or until you mark the prayer completed.")
                }

                // MARK: - Selected Apps Section
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Distracting Apps & Categories")
                                .font(.headline)

                            HStack(spacing: 12) {
                                Label("\(screenTimeManager.activitySelection.applicationTokens.count) Apps", systemImage: "app.dashed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Label("\(screenTimeManager.activitySelection.categoryTokens.count) Categories", systemImage: "folder")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Button("Select") {
                            isPickerPresented = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Apps to Block")
                }

                // MARK: - Live Testing Section
                Section {
                    if screenTimeManager.isShieldCurrentlyActive {
                        Button(role: .destructive) {
                            screenTimeManager.clearShields()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Instant Unlock All Apps", systemImage: "lock.open.fill")
                                Spacer()
                            }
                        }
                    } else {
                        Button {
                            screenTimeManager.applyImmediateShield(for: "Dhuhr")
                        } label: {
                            HStack {
                                Spacer()
                                Label("Test App Shield Now", systemImage: "play.shield.fill")
                                Spacer()
                            }
                        }
                    }
                } header: {
                    Text("Shield Diagnostics")
                } footer: {
                    Text("Test the shield overlay to verify that opening shielded apps triggers the custom MyPray prayer reminder.")
                }
            }
        }
        .navigationTitle("Screen Time Blocker")
        #if canImport(FamilyControls)
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $screenTimeManager.activitySelection
        )
        .onChange(of: screenTimeManager.activitySelection) { _, newSelection in
            screenTimeManager.updateSelection(newSelection)
        }
        #endif
        .onAppear {
            let settings = SwiftDataStore.shared.fetchSettings()
            self.isBlockerEnabled = settings.isScreenTimeBlockerEnabled
            self.selectedDuration = settings.screenTimeBlockDurationMinutes
            screenTimeManager.checkAuthorizationStatus()
        }
    }
}
