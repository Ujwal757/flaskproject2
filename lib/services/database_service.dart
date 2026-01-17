import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../models/report.dart';
import '../models/report_update.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Database references
  DatabaseReference get _reportsRef => _database.child('reports');
  DatabaseReference get _usersRef => _database.child('users');
  DatabaseReference get _reportUpdatesRef => _database.child('reportUpdates');

  /// Upload image to Firebase Storage (for mobile)
  Future<String> uploadImage(File imageFile, String reportId) async {
    try {
      final ref = _storage.ref().child('reports/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload image bytes to Firebase Storage (for web)
  Future<String> uploadImageBytes(Uint8List imageBytes, String reportId) async {
    try {
      final ref = _storage.ref().child('reports/$reportId/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(imageBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Create a new report
  Future<void> createReport(Report report) async {
    try {
      await _reportsRef.child(report.id).set(report.toMap());
    } catch (e) {
      throw Exception('Error creating report: $e');
    }
  }

  /// Get a single report by ID
  Future<Report?> getReport(String reportId) async {
    try {
      final snapshot = await _reportsRef.child(reportId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Report.fromMap(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (e) {
      throw Exception('Error getting report: $e');
    }
  }

  /// Stream all reports
  Stream<List<Report>> streamAllReports() {
    return _reportsRef
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Report>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final reports = <Report>[];
      
      data.forEach((key, value) {
        try {
          final reportData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          reports.add(Report.fromMap(reportData));
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      // Sort by timestamp descending
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  /// Stream reports by severity (for Authority Dashboard)
  Stream<List<Report>> streamReportsBySeverity(DamageSeverity severity) {
    return _reportsRef
        .orderByChild('severity')
        .equalTo(severity.name)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Report>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final reports = <Report>[];
      
      data.forEach((key, value) {
        try {
          final reportData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          final report = Report.fromMap(reportData);
          // Filter by status
          if (report.status == ReportStatus.pending || report.status == ReportStatus.assigned) {
            reports.add(report);
          }
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      // Sort by timestamp descending
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  /// Stream reports for moderate and severe (for Authority Dashboard)
  Stream<List<Report>> streamModerateAndSevereReports() {
    return _reportsRef
        .orderByChild('severity')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Report>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final reports = <Report>[];
      
      data.forEach((key, value) {
        try {
          final reportData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          final report = Report.fromMap(reportData);
          // Filter by severity and status
          if ((report.severity == DamageSeverity.moderate || 
               report.severity == DamageSeverity.severe) &&
              (report.status == ReportStatus.pending || 
               report.status == ReportStatus.assigned)) {
            reports.add(report);
          }
        } catch (e) {
          // Skip invalid entries
        }
      });
      
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
    return _reportsRef
        .orderByChild('assignedWorkerId')
        .equalTo(workerId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Report>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final reports = <Report>[];
      
      data.forEach((key, value) {
        try {
          final reportData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          reports.add(Report.fromMap(reportData));
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      // Sort by timestamp descending
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  /// Assign a report to a worker
  Future<void> assignReportToWorker(String reportId, String workerId) async {
    try {
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
      final updates = <String, dynamic>{
        'status': status.name,
      };
      
      if (status == ReportStatus.completed) {
        updates['completedAt'] = DateTime.now().millisecondsSinceEpoch;
      }
      
      await _reportsRef.child(reportId).update(updates);
    } catch (e) {
      throw Exception('Error updating report status: $e');
    }
  }

  /// Update report with after image
  Future<void> updateReportWithAfterImage(String reportId, String afterImageUrl) async {
    try {
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
      final snapshot = await _usersRef.child(userId).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      throw Exception('Error getting user: $e');
    }
  }

  /// Stream all workers (for Authority to assign tasks)
  Stream<List<Map<String, dynamic>>> streamWorkers() {
    return _usersRef
        .orderByChild('role')
        .equalTo('worker')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Map<String, dynamic>>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final workers = <Map<String, dynamic>>[];
      
      data.forEach((key, value) {
        try {
          final workerData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          workers.add(workerData);
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      return workers;
    });
  }

  /// Add a report update (from worker)
  Future<void> addReportUpdate(ReportUpdate update) async {
    try {
      // Save the update
      await _reportUpdatesRef.child(update.id).set(update.toMap());
      
      // Update the report status
      await updateReportStatus(update.reportId, update.status);
      
      // If there's an after image, update the report
      if (update.afterImageUrl != null) {
        await _reportsRef.child(update.reportId).update({
          'afterImageUrl': update.afterImageUrl,
        });
      }
    } catch (e) {
      throw Exception('Error adding report update: $e');
    }
  }

  /// Stream updates for a specific report
  Stream<List<ReportUpdate>> streamReportUpdates(String reportId) {
    return _reportUpdatesRef
        .orderByChild('reportId')
        .equalTo(reportId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <ReportUpdate>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final updates = <ReportUpdate>[];
      
      data.forEach((key, value) {
        try {
          final updateData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          updates.add(ReportUpdate.fromMap(updateData));
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      // Sort by timestamp descending (newest first)
      updates.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return updates;
    });
  }

  /// Stream reports by user ID (for citizens to view their reports)
  Stream<List<Report>> streamUserReports(String userId) {
    return _reportsRef
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return <Report>[];
      
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final reports = <Report>[];
      
      data.forEach((key, value) {
        try {
          final reportData = Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
          reports.add(Report.fromMap(reportData));
        } catch (e) {
          // Skip invalid entries
        }
      });
      
      // Sort by timestamp descending
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }
}

