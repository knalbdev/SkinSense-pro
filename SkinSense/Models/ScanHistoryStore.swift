//
//  ScanHistoryStore.swift
//  SkinSense
//
//  Created by Setianing Budi on 28/06/26.
//

import Foundation

@Observable
final class ScanHistoryStore {
    static let shared = ScanHistoryStore()
    private(set) var sessions: [ScanSession] = []

    private init() {}

    func add(_ session: ScanSession) {
        sessions.insert(session, at: 0)
    }

    func clear() {
        sessions.removeAll()
    }
}
