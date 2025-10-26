class Employee {
  final int? id;
  final String name;
  final String photoPath;
  final String faceHash; // simplified representation
  final String department;
  final String contact;

  Employee({
    this.id,
    required this.name,
    required this.photoPath,
    required this.faceHash,
    this.department = '',
    this.contact = '',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'photoPath': photoPath,
        'faceHash': faceHash,
        'department': department,
        'contact': contact,
      };

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
        id: m['id'] as int?,
        name: m['name'] as String,
        photoPath: m['photoPath'] as String,
        faceHash: m['faceHash'] as String,
        department: m['department'] as String? ?? '',
        contact: m['contact'] as String? ?? '',
      );
}
