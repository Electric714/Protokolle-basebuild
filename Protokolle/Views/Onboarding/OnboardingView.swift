//
//  OnboardingView.swift
//  Protokolle
//
//  Created by samara on 27.05.2025.
//

import SwiftUI

struct OnboardingView: View {
        @Environment(\.dismiss) private var dismiss
        @AppStorage("SY.isOnboarding") private var isOnboarding = Preferences.isOnboarding

        var onFinish: (() -> Void)?

        var body: some View {
                SYNavigationView(.localized("Welcome"), displayMode: .inline) {
                        ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                        _header()

                                        VStack(spacing: 16) {
                                                _infoRow(
                                                        title: .localized("What Keystone Reads"),
                                                        message: .localized("Streams system log messages from a paired device. No data leaves your device unless you choose to export it."),
                                                        systemImage: "waveform"
                                                )

                                                _infoRow(
                                                        title: .localized("How It Connects"),
                                                        message: .localized("Uses your pairing file and VPN tunnel to talk to lockdownd services within iOS boundaries."),
                                                        systemImage: "lock.shield"
                                                )

                                                _infoRow(
                                                        title: .localized("Your Controls"),
                                                        message: .localized("Toggle streaming, filter by process or subsystem, and export diagnostics when you decide."),
                                                        systemImage: "slider.horizontal.3"
                                                )
                                        }

                                        VStack(alignment: .leading, spacing: 12) {
                                                Text(.localized("Be sure you trust the pairing file and network path you use. Keystone only reads data the system already exposes over a trusted pairing."))
                                                        .font(.footnote)
                                                        .foregroundStyle(.secondary)
                                                        .padding()
                                                        .background(
                                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                                        .fill(Color.secondary.opacity(0.1))
                                                        )
                                        }

                                        Button(action: completeOnboarding) {
                                                Text(.localized("Get Started"))
                                                        .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .padding(.top, 8)
                                }
                                .padding()
                        }
                        .toolbar {
                                ToolbarItem(placement: .cancellationAction) {
                                        Button(.localized("Maybe Later")) { completeOnboarding() }
                                }
                        }
                }
        }
}

private extension OnboardingView {
        func _header() -> some View {
                VStack(alignment: .leading, spacing: 8) {
                        Text(.localized("Keystone"))
                                .font(.title.bold())
                        Text(.localized("Unified observability for your iOS device."))
                                .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }

        func _infoRow(title: String, message: String, systemImage: String) -> some View {
                HStack(alignment: .top, spacing: 12) {
                        Image(systemName: systemImage)
                                .font(.title3)
                                .foregroundStyle(.tint)
                                .frame(width: 32, height: 32)
                                .background(
                                        Circle()
                                                .fill(Color.secondary.opacity(0.1))
                                )

                        VStack(alignment: .leading, spacing: 6) {
                                Text(title)
                                        .font(.headline)
                                Text(message)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                )
        }

        func completeOnboarding() {
                isOnboarding = false
                onFinish?()
                dismiss()
        }
}
