// Removed cloud_firestore import - using Realtime Database now

enum ReportStatus {
  pending,
  assigned,
  inProgress,
  completed,
}

enum DamageSeverity {
  minor,
  moderate,
  severe,
}

enum DamageType {
  pothole,
  crack,
  none,
}

class Report {
  final String id;
  final String? imageUrl; // Optional - reports can be submitted without images
  final String? afterImageUrl;
  final String location;
  final ReportStatus status;
  final DamageSeverity severity;
  final DamageType damageType;
  final String description;
  final String? assignedWorkerId;
  final String userId;
  final DateTime timestamp;
  final DateTime? completedAt;

  Report({
    required this.id,
    this.imageUrl, // Optional
    this.afterImageUrl,
    required this.location,
    required this.status,
    required this.severity,
    required this.damageType,
    required this.description,
    this.assignedWorkerId,
    required this.userId,
    required this.timestamp,
    this.completedAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'afterImageUrl': afterImageUrl,
      'location': location,
      'status': status.name,
      'severity': severity.name,
      'damageType': damageType.name,
      'description': description,
      'assignedWorkerId': assignedWorkerId,
      'userId': userId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'completedAt': completedAt != null
          ? completedAt!.millisecondsSinceEpoch
          : null,
    };
    // Only include imageUrl if it exists
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      map['imageUrl'] = imageUrl;
    }
    return map;
  }

  // Create from Firestore document
  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      imageUrl: map['imageUrl'], // Can be null
      afterImageUrl: map['afterImageUrl'],
      location: map['location'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      severity: DamageSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => DamageSeverity.minor,
      ),
      damageType: DamageType.values.firstWhere(
        (e) => e.name == map['damageType'],
        orElse: () => DamageType.none,
      ),
      description: map['description'] ?? '',
      assignedWorkerId: map['assignedWorkerId'],
      userId: map['userId'] ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }

  // Create a copy with updated fields
  Report copyWith({
    String? id,
    String? imageUrl,
    String? afterImageUrl,
    String? location,
    ReportStatus? status,
    DamageSeverity? severity,
    DamageType? damageType,
    String? description,
    String? assignedWorkerId,
    String? userId,
    DateTime? timestamp,
    DateTime? completedAt,
  }) {
    return Report(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      afterImageUrl: afterImageUrl ?? this.afterImageUrl,
      location: location ?? this.location,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      damageType: damageType ?? this.damageType,
      description: description ?? this.description,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

