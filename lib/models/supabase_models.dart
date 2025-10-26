class AttendanceModel {
  final int id;
  final int employeeId;
  final DateTime timestamp;
  final String photoPath;
  final EmployeeModel? employee;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.timestamp,
    required this.photoPath,
    this.employee,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      employeeId: json['employee_id'],
      timestamp: DateTime.parse(json['timestamp']),
      photoPath: json['photo_path'],
      employee: json['employees'] != null
          ? EmployeeModel.fromJson(json['employees'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'timestamp': timestamp.toIso8601String(),
    'photo_path': photoPath,
  };
}

class EmployeeModel {
  final int id;
  final String name;
  final String photoPath;
  final String faceHash;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.photoPath,
    required this.faceHash,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'],
      name: json['name'],
      photoPath: json['photo_path'],
      faceHash: json['face_hash'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'photo_path': photoPath,
    'face_hash': faceHash,
  };
}
