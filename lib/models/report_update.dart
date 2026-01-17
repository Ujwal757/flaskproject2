import 'report.dart';

class ReportUpdate {
  final String id;
  final String reportId;
  final String workerId;
  final String? workerName;
  final ReportStatus status;
  final String message;
  final DateTime timestamp;
  final String? afterImageUrl;

  ReportUpdate({
    required this.id,
    required this.reportId,
    required this.workerId,
    this.workerName,
    required this.status,
    required this.message,
    required this.timestamp,
    this.afterImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportId': reportId,
      'workerId': workerId,
      'workerName': workerName,
      'status': status.name,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'afterImageUrl': afterImageUrl,
    };
  }

  factory ReportUpdate.fromMap(Map<String, dynamic> map) {
    return ReportUpdate(
      id: map['id'] ?? '',
      reportId: map['reportId'] ?? '',
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      message: map['message'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      afterImageUrl: map['afterImageUrl'],
    );
  }
}

