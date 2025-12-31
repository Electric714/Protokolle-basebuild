//
//  DebugSessionContext.swift
//  Protokolle
//
//  Created by OpenAI ChatGPT on 2025-05-28.
//

import Foundation

struct DebugSessionExportRequest {
        let filterToTarget: Bool
        let targetBundleID: String
}

struct DebugSessionSummary: Codable {
        struct PreferencesSummary: Codable {
                let refreshSpeed: Double
                let bufferLimit: Int
                let entryFilter: EntryFilter?
                let filterToTarget: Bool
                let targetBundleID: String
        }

        let createdAt: Date
        let appVersion: String
        let appBuild: String
        let deviceName: String
        let systemVersion: String
        let targetBundleID: String
        let filterToTarget: Bool
        let preferences: PreferencesSummary
}
