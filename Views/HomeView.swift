import SwiftUI

struct HomeView: View {
    @Environment(\.openURL) private var openURL
    @State private var showConnectSheet = false
    @State private var connectErrorMessage: String?
    @State private var showConnectError = false
    @State private var todayPick = TodayPick(
        displayName: "John Appleseed",
        phoneNumber: "+1 (555) 123-4567",
        lastConnectedText: "Last connected: 2 days ago"
    )

    @State private var showingPickDetails = false
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("StayConnected")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Today")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .confirmationDialog(
                            "Connect with \(todayPick.displayName)",
                            isPresented: $showConnectSheet,
                            titleVisibility: .visible
                        ) {
                            if let phone = todayPick.phoneNumber, !phone.isEmpty {
                                Button("Call") {
                                    connectVia("tel", value: phone)
                                }
                                Button("Message") {
                                    connectVia("sms", value: phone)
                                }
                            } else {
                                Button("No number available", role: .destructive) { }
                                    .disabled(true)
                            }

                            Button("Cancel", role: .cancel) { }
                        }
                        .alert("Can’t Connect", isPresented: $showConnectError) {
                            Button("OK", role: .cancel) { }
                        } message: {
                            Text(connectErrorMessage ?? "Something went wrong.")
                        }
                }
                .sheet(isPresented: $showingPickDetails) {
                    VStack(spacing: 16) {
                        Text(todayPick.displayName)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let phone = todayPick.phoneNumber {
                            Text(phone)
                                .foregroundStyle(.secondary)
                        }

                        Text(todayPick.lastConnectedText)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding()
                }

                // Today Card (placeholder for now)
                TodayCardView(pick: todayPick) {
                    lightHaptic()
                    showConnectSheet = true
                }

                Spacer()

                // Action buttons
                HStack(spacing: 14) {
                    Button(action: {
                        // TODO: Generate logic
                    }) {
                        Label("Generate", systemImage: "sparkles")
                    }
                    .buttonStyle(PrimaryPillButtonStyle())

                    Button(action: {
                        // TODO: Reset logic
                    }) {
                        Label("Reset Today", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(SecondaryPillButtonStyle())
                }
                .padding(.top, 6)

                // Footer text
                Text("Small consistent breaks build real connections.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding()
        }
    }
    private func connectVia(_ scheme: String, value: String) {
        let cleaned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            connectErrorMessage = "No phone number found for this contact."
            showConnectError = true
            return
        }

        // Build URL (tel://123..., sms://123...)
        guard let url = URL(string: "\(scheme)://\(cleaned)") else {
            connectErrorMessage = "Couldn’t create a valid link."
            showConnectError = true
            return
        }

        successHaptic()

        openURL(url)
    }
    private func lightHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func successHaptic() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
