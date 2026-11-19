//
//  AgitationAlerts.swift
//  Darkroom
//
//  Keeps a run of local notifications scheduled for the agitation prompts ahead, so
//  the phone can tell you what to do with the screen off or the app away.
//

import Foundation
import UserNotifications

enum AgitationAlerts {
    private static var pending: [String] = []

    static func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @MainActor
    static func schedule(_ alerts: [(title: String, detail: String, seconds: TimeInterval)]) {
        cancel()
        guard !alerts.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        let identifiers = alerts.indices.map { _ in "darkroom-agitation-\(UUID().uuidString)" }
        pending = identifiers

        for (index, alert) in alerts.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = alert.title
            content.body = alert.detail
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: max(1, alert.seconds),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifiers[index],
                content: content,
                trigger: trigger
            )
            center.add(request, withCompletionHandler: nil)
        }
    }

    static func cancel() {
        guard !pending.isEmpty else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: pending)
        pending = []
    }
}
