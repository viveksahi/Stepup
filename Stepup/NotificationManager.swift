import Foundation
import UserNotifications

struct NotificationManager {
    func requestNotificationPermissions(stepCount: Int, completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notifications permission granted, scheduling daily notification")
                    scheduleDailyStepNotification(stepCount: stepCount)
                } else {
                    if let error = error {
                        print("Notification permission error: \(error)")
                    } else {
                        print("Notification permission denied by user")
                    }
                }
                // Always call completion with the permission result
                completion(granted)
            }
        }
    }

    func scheduleDailyStepNotification(stepCount: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Daily Step Count"
        content.body = "Click to check your step count for the day"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = 21  // 9 PM
        dateComponents.minute = 2

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "DailyStepCount", content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
}
