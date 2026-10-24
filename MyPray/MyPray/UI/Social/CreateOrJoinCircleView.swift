import SwiftUI

public struct CreateOrJoinCircleView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: Int = 0 // 0 = Join, 1 = Create
    @State private var inviteCodeInput: String = ""
    @State private var circleNameInput: String = ""
    @State private var yourNameInput: String = "You"
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    public var onCircleCreatedOrJoined: ((PrayerCircle) -> Void)?

    public init(onCircleCreatedOrJoined: ((PrayerCircle) -> Void)? = nil) {
        self.onCircleCreatedOrJoined = onCircleCreatedOrJoined
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Mode Switcher
                Section {
                    Picker("Action", selection: $selectedTab) {
                        Text("Join Circle").tag(0)
                        Text("Create Circle").tag(1)
                    }
                    .pickerStyle(.segmented)
                }

                // User Identity
                Section {
                    TextField("Your Name", text: $yourNameInput)
                        .autocorrectionDisabled()
                } header: {
                    Text("Your Profile")
                } footer: {
                    Text("This is how your friends will see you on the accountability board.")
                }

                if selectedTab == 0 {
                    // MARK: - Join with 6-char Code
                    Section {
                        TextField("6-Character Code (e.g. FAJR77)", text: $inviteCodeInput)
                            .font(.system(.title3, design: .monospaced).bold())
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .onChange(of: inviteCodeInput) { _, newValue in
                                if newValue.count > 6 {
                                    inviteCodeInput = String(newValue.prefix(6))
                                }
                            }

                        Button {
                            submitJoin()
                        } label: {
                            HStack {
                                Spacer()
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Label("Join Accountability Circle", systemImage: "person.badge.plus")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(inviteCodeInput.trimmingCharacters(in: .whitespaces).count != 6 || isSubmitting)
                        .tint(.green)
                    } header: {
                        Text("Invite Code")
                    } footer: {
                        Text("Ask your friend or circle administrator for their 6-character alphanumeric invite code.")
                    }
                } else {
                    // MARK: - Create New Circle
                    Section {
                        TextField("Circle Name (e.g. Family Salah)", text: $circleNameInput)

                        Button {
                            submitCreate()
                        } label: {
                            HStack {
                                Spacer()
                                if isSubmitting {
                                    ProgressView()
                                } else {
                                    Label("Create & Generate Invite Code", systemImage: "sparkles")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(circleNameInput.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                        .tint(.green)
                    } header: {
                        Text("Circle Details")
                    } footer: {
                        Text("You will receive a unique 6-character code that you can share with up to 10 friends and family members.")
                    }
                }

                if let error = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(selectedTab == 0 ? "Join Circle" : "Create Circle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func submitJoin() {
        self.isSubmitting = true
        self.errorMessage = nil

        Task {
            do {
                let circle = try await MockCircleService.shared.joinCircle(
                    inviteCode: inviteCodeInput,
                    memberName: yourNameInput
                )
                await MainActor.run {
                    self.isSubmitting = false
                    onCircleCreatedOrJoined?(circle)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func submitCreate() {
        self.isSubmitting = true
        self.errorMessage = nil

        Task {
            do {
                let circle = try await MockCircleService.shared.createCircle(
                    name: circleNameInput,
                    creatorName: yourNameInput
                )
                await MainActor.run {
                    self.isSubmitting = false
                    onCircleCreatedOrJoined?(circle)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSubmitting = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
