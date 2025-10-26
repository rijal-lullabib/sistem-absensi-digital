import 'dart:io';
import 'package:path/path.dart';
import '../config/supabase_config.dart';
import '../models/employee.dart';
import '../models/attendance.dart';

class DataService {
  static final DataService instance = DataService._internal();
  DataService._internal();

  // Employee Methods
  Future<List<Employee>> getAllEmployees() async {
    try {
      final response = await SupabaseConfig.client
          .from('employees')
          .select()
          .order('name');

      return List<Employee>.from(
        response.map(
          (map) => Employee.fromMap({
            'id': map['id'],
            'name': map['name'],
            'photoPath': map['photo_path'],
            'faceHash': map['face_hash'],
          }),
        ),
      );
    } catch (e) {
      throw Exception('Failed to get employees: $e');
    }
  }

  Future<Employee> getEmployee(int id) async {
    try {
      final response = await SupabaseConfig.client
          .from('employees')
          .select()
          .eq('id', id)
          .single();

      return Employee.fromMap({
        'id': response['id'],
        'name': response['name'],
        'photoPath': response['photo_path'],
        'faceHash': response['face_hash'],
      });
    } catch (e) {
      throw Exception('Failed to get employee: $e');
    }
  }

  Future<void> addEmployee(Employee employee) async {
    try {
      // Upload photo if exists
      String photoPath = employee.photoPath;
      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        final fileName = basename(photoPath);
        final storagePath = 'employee-photos/$fileName';
        await SupabaseConfig.client.storage
            .from('attendance-photos')
            .upload(storagePath, File(photoPath));
        photoPath = storagePath;
      }

      await SupabaseConfig.client.from('employees').insert({
        'name': employee.name,
        'photo_path': photoPath,
        'face_hash': employee.faceHash,
      });
    } catch (e) {
      throw Exception('Failed to add employee: $e');
    }
  }

  // Attendance Methods
  Future<List<Attendance>> getAllAttendance() async {
    try {
      final response = await SupabaseConfig.client
          .from('attendance')
          .select('*, employees(name)')
          .order('timestamp', ascending: false);

      return List<Attendance>.from(
        response.map(
          (map) => Attendance(
            id: map['id'],
            employeeId: map['employee_id'],
            timestamp: DateTime.parse(map['timestamp']),
            photoPath: map['photo_path'] ?? '',
            type: map['type'] ?? 'IN', // Default to IN if not present
            status: map['status'] ?? 'ON_TIME', // Default to ON_TIME if not present
          ),
        ),
      );
    } catch (e) {
      throw Exception('Failed to get attendance records: $e');
    }
  }

  Future<void> addAttendance(Attendance attendance) async {
    try {
      // Upload photo if exists
      String photoPath = attendance.photoPath;
      if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
        final fileName =
            '${attendance.employeeId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storagePath = 'attendance-photos/$fileName';
        await SupabaseConfig.client.storage
            .from('attendance-photos')
            .upload(storagePath, File(photoPath));
        photoPath = storagePath;
      }

      await SupabaseConfig.client.from('attendance').insert({
        'employee_id': attendance.employeeId,
        'timestamp': attendance.timestamp.toIso8601String(),
        'photo_path': photoPath,
        'type': attendance.type,
        'status': attendance.status,
      });
    } catch (e) {
      throw Exception('Failed to add attendance: $e');
    }
  }

  // Helper methods for file storage
  Future<String> getFileUrl(String path) async {
    try {
      final response = await SupabaseConfig.client.storage
          .from('attendance-photos')
          .createSignedUrl(path, 3600); // URL valid for 1 hour
      return response;
    } catch (e) {
      throw Exception('Failed to get file URL: $e');
    }
  }
}
