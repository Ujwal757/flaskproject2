import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'roadvision_channel',
          'RoadVision Notifications',
          channelDescription: 'Notifications for road damage reports and tasks',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin
        .show(id, title, body, details, payload: payload)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => print('⚠️ Notification timed out'),
        );
  }

  Future<void> showSevereDamageAlert(String location) async {
    await showNotification(
      id: 1,
      title: '🔴 SEVERE DAMAGE DETECTED',
      body:
          'A severe road issue has been reported at $location. Immediate attention required!',
    );
  }

  Future<void> showTaskAssignedAlert(String reportId) async {
    await showNotification(
      id: 2,
      title: '📋 New Task Assigned',
      body: 'A new road repair task has been assigned to you. Code: $reportId',
    );
  }

  Future<void> showTaskCompletedAlert(String reportId) async {
    await showNotification(
      id: 3,
      title: '✅ Task Completed',
      body: 'Repair work for report $reportId has been finished by the worker.',
    );
  }

  Future<void> showReportSubmitted(String reportId) async {
    await showNotification(
      id: 4,
      title: '📝 Report Submitted',
      body:
          'Your road damage report (ID: $reportId) has been successfully submitted and is pending review.',
    );
  }

  Future<void> showAdminNewReport(String reportId, String severity) async {
    await showNotification(
      id: 5,
      title: '🚨 New Report: ${severity.toUpperCase()}',
      body:
          'A new $severity damage report has been submitted. Check the dashboard to assign it.',
    );
  }

  Future<void> showStatusUpdateToCitizen(String reportId, String status) async {
    String message;
    String emoji;

    switch (status.toLowerCase()) {
      case 'assigned':
        message = 'A worker has been assigned to fix this issue.';
        emoji = '👤';
        break;
      case 'in progress':
      case 'inprogress':
        message = 'A worker has started repairing the reported damage.';
        emoji = '🛠️';
        break;
      case 'completed':
        message = 'The repair work has been marked as completed by the worker.';
        emoji = '✨';
        break;
      case 'verified':
        message =
            'The repair work has been verified and the report is now closed. Thank you!';
        emoji = '✅';
        break;
      default:
        message = 'The status of your report has changed to $status.';
        emoji = 'ℹ️';
    }

    await showNotification(
      id: 6,
      title: '$emoji Status Update: $status',
      body: 'Update for report $reportId: $message',
    );
  }

  Future<void> showWorkerStartedWork(String reportId) async {
    await showNotification(
      id: 7,
      title: '🏗️ Work Started',
      body: 'Worker has started working on task $reportId.',
    );
  }

  Future<void> showVerificationAlert(String reportId) async {
    await showNotification(
      id: 8,
      title: '🔍 Work Verified',
      body:
          'Report $reportId has been verified by the authority and is now closed.',
    );
  }
}
