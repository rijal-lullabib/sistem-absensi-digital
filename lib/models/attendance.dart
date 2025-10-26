// ignore_for_file: curly_braces_in_flow_control_structures

class Attendance {
  final int? id;
  final int employeeId;
  final DateTime timestamp;
  final String photoPath;
  final String type; // 'IN' or 'OUT'
  final String status; // 'ON_TIME' or 'LATE'

  Attendance({
    this.id,
    required this.employeeId,
    required this.timestamp,
    this.photoPath = '',
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'employeeId': employeeId,
    'timestamp': timestamp.toIso8601String(),
    'photoPath': photoPath,
    'type': type,
    'status': status,
  };

  factory Attendance.fromMap(Map<String, dynamic> m) => Attendance(
    id: m['id'] as int?,
    employeeId: m['employeeId'] as int,
    timestamp: DateTime.parse(m['timestamp'] as String),
    photoPath: m['photoPath'] as String? ?? '',
    type: m['type'] as String,
    status: m['status'] as String,
  );

  // Helper methods untuk menentukan type dan status secara dinamis (untuk backward compatibility)
  String getType() {
    return type;
  }

  String getStatus() {
    return status;
  }
}
