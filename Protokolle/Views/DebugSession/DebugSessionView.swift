//
//  DebugSessionView.swift
//  Protokolle
//
//  Created by OpenAI ChatGPT on 2025-05-28.
//

import SwiftUI
import IDeviceSwift

struct DebugSessionView: View {
        @AppStorage("SY.targetBundleID") private var targetBundleID = Preferences.targetBundleID
        @AppStorage("SY.filterToTarget") private var filterToTarget = Preferences.filterToTarget

        @State private var socketReachable = false
        @State private var hasPairingFile = FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile())
        @State private var lastHeartbeat = Date()
        @State private var isStreaming = false
        @State private var isImportingPairing = false

        private var targetPlaceholder: String {
                "com.example.app"
        }

        var body: some View {
                SYNavigationView(.localized("Debug Session"), displayMode: .large) {
                        Form {
                                connectionSection
                                heartbeatSection
                                streamingSection
                                targetSection
                                exportSection
                        }
                        .onAppear(perform: refreshConnectionStatus)
                        .onReceive(NotificationCenter.default.publisher(for: .heartbeat)) { _ in
                                lastHeartbeat = Date()
                                refreshConnectionStatus()
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .isStreamingDidChange)) { notification in
                                if let isOn = notification.object as? Bool {
                                        isStreaming = isOn
                                }
                        }
                        .sheet(isPresented: $isImportingPairing) {
                                FileImporterRepresentableView(
                                        allowedContentTypes: [.xmlPropertyList, .plist, .mobiledevicepairing],
                                        onDocumentsPicked: { urls in
                                                guard let selected = urls.first else { return }
                                                movePairing(selected)
                                                hasPairingFile = true
                                                refreshConnectionStatus()
                                        }
                                )
                                .ignoresSafeArea()
                        }
                }
        }
}

private extension DebugSessionView {
        var connectionSection: some View {
                Section {
                        statusRow(
                                title: .localized("Tunnel"),
                                value: socketReachable ? .localized("Reachable") : .localized("Not Reachable"),
                                systemImage: socketReachable ? "checkmark.circle.fill" : "xmark.circle.fill",
                                tint: socketReachable ? .green : .red
                        )

                        statusRow(
                                title: .localized("Pairing File"),
                                value: hasPairingFile ? .localized("Imported") : .localized("Missing"),
                                systemImage: hasPairingFile ? "lock.fill" : "lock.slash",
                                tint: hasPairingFile ? .green : .orange
                        )

                        Button(.localized("Import Pairing File"), systemImage: "square.and.arrow.down") {
                                isImportingPairing = true
                        }
                        .buttonStyle(.borderless)
                        .disabled(isStreaming)
                        .tint(.accentColor)
                } header: {
                        Text(.localized("Connection"))
                } footer: {
                        Text(.localized("Protokolle relies on loopback VPN routing and a valid pairing record to reach the device services."))
                }
        }

        var heartbeatSection: some View {
                Section {
                        statusRow(
                                title: .localized("Last Ping"),
                                value: RelativeDateTimeFormatter().localizedString(for: lastHeartbeat, relativeTo: Date()),
                                systemImage: "waveform.path.ecg",
                                tint: .blue
                        )

                        HStack {
                                Button(.localized("Connect"), systemImage: "bolt.horizontal.fill") {
                                        HeartbeatManager.shared.start(true)
                                        refreshConnectionStatus()
                                }
                                .buttonStyle(.borderedProminent)

                                Button(.localized("Disconnect"), systemImage: "bolt.slash.fill") {
                                        HeartbeatManager.shared.start(false)
                                        refreshConnectionStatus()
                                }
                                .buttonStyle(.bordered)
                        }
                } header: {
                        Text(.localized("Heartbeat"))
                } footer: {
                        Text(.localized("A healthy heartbeat keeps the socket ready for log streaming."))
                }
        }

        var streamingSection: some View {
                Section {
                        statusRow(
                                title: .localized("Stream"),
                                value: isStreaming ? .localized("Running") : .localized("Stopped"),
                                systemImage: isStreaming ? "dot.radiowaves.left.and.right" : "pause.circle",
                                tint: isStreaming ? .green : .secondary
                        )

                        HStack {
                                Button(isStreaming ? .localized("Stop Logs") : .localized("Start Logs"), systemImage: isStreaming ? "stop.fill" : "play.fill") {
                                        NotificationCenter.default.post(
                                                name: .debugSessionToggleStream,
                                                object: !isStreaming
                                        )
                                }
                                .buttonStyle(.borderedProminent)

                                Button(.localized("View Stream"), systemImage: "text.alignleft") {
                                        NotificationCenter.default.post(
                                                name: .debugSessionToggleStream,
                                                object: true
                                        )
                                }
                                .buttonStyle(.bordered)
                        }
                } header: {
                        Text(.localized("Syslog Streaming"))
                } footer: {
                        Text(.localized("Stream controls reuse the existing log viewer; start here, then swipe back to see live output."))
                }
        }

        var targetSection: some View {
                Section {
                        TextField(targetPlaceholder, text: $targetBundleID)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)

                        Toggle(.localized("Filter to Target"), isOn: $filterToTarget)
                } header: {
                        Text(.localized("Target App"))
                } footer: {
                        Text(.localized("Enter the bundle identifier to highlight and filter logs for a specific app."))
                }
        }

        var exportSection: some View {
                Section {
                        Button(.localized("Export Debug Bundle"), systemImage: "archivebox.fill") {
                                let request = DebugSessionExportRequest(
                                        filterToTarget: filterToTarget,
                                        targetBundleID: targetBundleID
                                )

                                NotificationCenter.default.post(
                                        name: .debugSessionExportBundle,
                                        object: request
                                )
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(targetBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && filterToTarget)

                        Text(.localized("Exports include filtered logs, preferences, and the target information in the Exports directory."))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                } header: {
                        Text(.localized("Bug Bundle"))
                }
        }

        func statusRow(title: String, value: String, systemImage: String, tint: Color) -> some View {
                HStack {
                        Label(title, systemImage: systemImage)
                                .labelStyle(.titleAndIcon)
                                .foregroundStyle(tint)
                        Spacer()
                        Text(value)
                                .foregroundStyle(.secondary)
                }
        }

        func refreshConnectionStatus() {
                let socket = HeartbeatManager.shared.checkSocketConnection()
                socketReachable = socket.isConnected
                hasPairingFile = FileManager.default.fileExists(atPath: HeartbeatManager.pairingFile())
        }

        func movePairing(_ url: URL) {
                let fileManager = FileManager.default
                let destination = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")

                try? fileManager.removeItem(at: destination)
                try? fileManager.copyItem(at: url, to: destination)

                HeartbeatManager.shared.start(true)
        }
}
