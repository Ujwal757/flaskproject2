import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../models/report.dart';
import '../models/report_update.dart';
import '../models/notification_model.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore collections
  CollectionReference get _reportsCollection =>
      _firestore.collection('reports');
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _reportUpdatesCollection =>
      _firestore.collection('reportUpdates');

  // Database references
  DatabaseReference get _reportsRef => _database.child('reports');
  DatabaseReference get _usersRef => _database.child('users');
  DatabaseReference get _reportUpdatesRef => _database.child('reportUpdates');
  DatabaseReference get _notificationsRef => _database.child('notifications');

  // Firestore collections
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Convert an image file to a base64 string
  Future<String> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      throw Exception('Error converting image to base64: $e');
    }
  }

  /// Convert image bytes to a base64 string
  String bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Upload image to base64 string (replaces Firebase Storage)
  Future<String> uploadImage(File imageFile, String reportId) async {
    print('🔵 DatabaseService: Converting image file to Base64...');
    return await imageToBase64(imageFile);
  }

  /// Upload image bytes to base64 string (replaces Firebase Storage)
  Future<String> uploadImageBytes(Uint8List imageBytes, String reportId) async {
    print('🔵 DatabaseService: Converting image bytes to Base64...');
    return bytesToBase64(imageBytes);
  }

  /// Create a new report
  Future<void> createReport(Report report) async {
    try {
      print('🔵 DatabaseService: Creating report in Firestore and RTDB...');

      // Perform writes in parallel
      final firestoreWrite = _reportsCollection
          .doc(report.id)
          .set(report.toMap());
      final rtdbWrite = _reportsRef.child(report.id).set(report.toMap());

      await Future.wait([
        firestoreWrite,
        rtdbWrite,
      ]).timeout(const Duration(seconds: 20));

      print('✅ DatabaseService: Report created successfully in both databases');
    } catch (e) {
      print('❌ DatabaseService: Error creating report: $e');
      throw Exception('Error creating report: $e');
    }
  }

  /// Get a single report by ID
  Future<Report?> getReport(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Report.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting report: $e');
    }
  }

  /// Stream a single report by ID
  Stream<Report?> streamReport(String reportId) {
    return _reportsCollection.doc(reportId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>;
      return Report.fromMap(data);
    });
  }

  /// Stream all reports
  Stream<List<Report>> streamAllReports() {
    return _reportsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Report.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();
        });
  }

  /// Stream reports by severity (for Authority Dashboard)
  Stream<List<Report>> streamReportsBySeverity(DamageSeverity severity) {
    return _reportsCollection
        .where('severity', isEqualTo: severity.name)
        .where(
          'status',
          whereIn: [ReportStatus.pending.name, ReportStatus.assigned.name],
        )
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) {
            return Report.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by timestamp descending (Firestore whereIn doesn't support order by different field without index)
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reports;
        });
  }

  /// Stream reports for moderate and severe (for Authority Dashboard)
  Stream<List<Report>> streamModerateAndSevereReports() {
    return _reportsCollection
        .where(
          'severity',
          whereIn: [DamageSeverity.moderate.name, DamageSeverity.severe.name],
        )
        .where(
          'status',
          whereIn: [ReportStatus.pending.name, ReportStatus.assigned.name],
        )
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) {
            return Report.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by severity (severe first), then timestamp
          reports.sort((a, b) {
            if (a.severity != b.severity) {
              return b.severity.index.compareTo(a.severity.index);
            }
            return b.timestamp.compareTo(a.timestamp);
          });
          return reports;
        });
  }

  /// Stream reports assigned to a worker
  Stream<List<Report>> streamWorkerReports(String workerId) {
    return _reportsCollection
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) {
            return Report.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by timestamp descending
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reports;
        });
  }

  /// Assign a report to a worker
  Future<void> assignReportToWorker(String reportId, String workerId) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'assignedWorkerId': workerId,
        'status': 'assigned',
      });
      // Keep RTDB in sync during migration
      await _reportsRef.child(reportId).update({
        'assignedWorkerId': workerId,
        'status': 'assigned',
      });
    } catch (e) {
      throw Exception('Error assigning report: $e');
    }
  }

  /// Update report status
  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      final updates = <String, dynamic>{'status': status.name};

      if (status == ReportStatus.completed) {
        updates['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      }

      await _reportsCollection.doc(reportId).update(updates);
      // Keep RTDB in sync
      await _reportsRef.child(reportId).update(updates);
    } catch (e) {
      throw Exception('Error updating report status: $e');
    }
  }

  /// Update report with after image
  Future<void> updateReportWithAfterImage(
    String reportId,
    String afterImageUrl,
  ) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'afterImageUrl': afterImageUrl,
      });
      // Keep RTDB in sync
      await _reportsRef.child(reportId).update({
        'afterImageUrl': afterImageUrl,
      });
    } catch (e) {
      throw Exception('Error updating report with after image: $e');
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      // Fallback to RTDB if not in Firestore yet
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// Stream all workers (for Authority to assign tasks)
  /// Includes predefined workers even if they haven't logged in yet
  Stream<List<Map<String, dynamic>>> streamWorkers() async* {
    // Import predefined accounts
    final predefinedWorkers = <Map<String, dynamic>>[];

    try {
      // For now, manually add predefined workers
      for (int i = 1; i <= 10; i++) {
        predefinedWorkers.add({
          'id': 'worker_${i}_fixed',
          'email': 'worker$i@roadvision.com',
          'name': 'Worker $i',
          'role': 'worker',
        });
      }
    } catch (e) {
      // If there's an error, continue with empty list
    }

    // Yield predefined workers immediately
    yield predefinedWorkers;

    // Then stream from Firestore and merge
    await for (final snapshot
        in _usersCollection.where('role', isEqualTo: 'worker').snapshots()) {
      final dbWorkers = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Merge predefined and database workers, avoiding duplicates
      final allWorkers = <String, Map<String, dynamic>>{};

      // Add predefined workers first
      for (final worker in predefinedWorkers) {
        allWorkers[worker['id']] = worker;
      }

      // Override with database workers if they exist
      for (final worker in dbWorkers) {
        allWorkers[worker['id']] = worker;
      }

      yield allWorkers.values.toList();
    }
  }

  /// Add a report update (from worker)
  Future<void> addReportUpdate(ReportUpdate update) async {
    try {
      // Save the update to Firestore
      await _reportUpdatesCollection.doc(update.id).set(update.toMap());

      // Update the report status
      await updateReportStatus(update.reportId, update.status);

      // If there's an after image, update the report
      if (update.afterImageUrl != null) {
        await _reportsCollection.doc(update.reportId).update({
          'afterImageUrl': update.afterImageUrl,
        });
        // Keep RTDB in sync
        await _reportsRef.child(update.reportId).update({
          'afterImageUrl': update.afterImageUrl,
        });
      }

      // Update RTDB in sync for updates too
      await _reportUpdatesRef.child(update.id).set(update.toMap());
    } catch (e) {
      throw Exception('Error adding report update: $e');
    }
  }

  /// Stream updates for a specific report
  Stream<List<ReportUpdate>> streamReportUpdates(String reportId) {
    return _reportUpdatesCollection
        .where('reportId', isEqualTo: reportId)
        .snapshots()
        .map((snapshot) {
          final updates = snapshot.docs.map((doc) {
            return ReportUpdate.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by timestamp descending (newest first)
          updates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return updates;
        });
  }

  /// Stream reports by user ID (for citizens to view their reports)
  Stream<List<Report>> streamUserReports(String userId) {
    return _reportsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs.map((doc) {
            return Report.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by timestamp descending
          reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reports;
        });
  }

  /// Create a notification
  Future<void> createNotification(AppNotification notification) async {
    try {
      // Save to Firestore
      await _notificationsCollection
          .doc(notification.id)
          .set(notification.toMap());
      // Sync to RTDB
      await _notificationsRef.child(notification.id).set(notification.toMap());
    } catch (e) {
      print('❌ DatabaseService: Error creating notification: $e');
    }
  }

  /// Stream notifications for a specific user
  Stream<List<AppNotification>> streamUserNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs.map((doc) {
            return AppNotification.fromMap(doc.data() as Map<String, dynamic>);
          }).toList();

          // Sort by timestamp descending
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications;
        });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
      await _notificationsRef.child(notificationId).update({'isRead': true});
    } catch (e) {
      print('❌ DatabaseService: Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
        // Also update RTDB (sequentially for now, batch is only for Firestore)
        _notificationsRef.child(doc.id).update({'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('❌ DatabaseService: Error marking all notifications as read: $e');
    }
  }

  /// Get all authority user IDs
  Future<List<String>> getAuthorityUserIds() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'authority')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('❌ DatabaseService: Error getting authority user IDs: $e');
      return [];
    }
  }
}
