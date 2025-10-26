// ignore_for_file: unused_import, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../services/db_helper.dart';
import '../models/attendance.dart';
import '../models/employee.dart';
import '../utils/responsive_utils.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _timeFormat = DateFormat('HH:mm');

  List<Attendance> _logs = [];
  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  int _page = 1;
  static const int _pageSize = 20;
  DateTime _selectedDate = DateTime.now();
  bool _isGridView = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _fabController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fabAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _fabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _load({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _page = 1;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final startIndex = (_page - 1) * _pageSize;
      final logs = await DBHelper.instance.getAllAttendance();
      final emps = await DBHelper.instance.getAllEmployees();

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _logs = [];
          }
          _logs.addAll(logs.reversed.skip(startIndex).take(_pageSize));
          _employees = emps;
          _isLoading = false;
          _isLoadingMore = false;
          if (logs.length > startIndex + _pageSize) {
            _page++;
          }
        });
        
        _fadeController.forward();
        _slideController.forward();
        _fabController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        _showSnackBar('Error: $e', const Color(0xFFEF4444));
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 33, 11, 48).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                color == const Color(0xFFEF4444) ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  String _empName(int id) {
    return _employees
        .firstWhere(
          (e) => e.id == id,
          orElse: () => Employee(
            id: 0,
            name: 'Unknown',
            photoPath: '',
            faceHash: '',
          ),
        )
        .name;
  }

  List<Attendance> _getFilteredLogs() {
    var filtered = List<Attendance>.from(_logs);

    switch (_selectedFilter) {
      case 'Hari Ini':
        filtered = filtered.where((log) {
          final logDate = log.timestamp;
          return logDate.year == _selectedDate.year &&
              logDate.month == _selectedDate.month &&
              logDate.day == _selectedDate.day;
        }).toList();
        break;
      case 'Minggu Ini':
        final weekStart = _selectedDate.subtract(
          Duration(days: _selectedDate.weekday - 1),
        );
        final weekEnd = weekStart.add(const Duration(days: 6));
        filtered = filtered.where((log) {
          final logDate = log.timestamp;
          return logDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              logDate.isBefore(weekEnd.add(const Duration(days: 1)));
        }).toList();
        break;
      case 'Bulan Ini':
        filtered = filtered.where((log) {
          return log.timestamp.year == _selectedDate.year &&
              log.timestamp.month == _selectedDate.month;
        }).toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((log) {
        final empName = _empName(log.employeeId).toLowerCase();
        return empName.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  Color _getTimeColor(Attendance log) {
    if (log.type == 'OUT') return const Color(0xFF8B5CF6);
    if (log.status == 'ON_TIME') return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  IconData _getTimeIcon(Attendance log) {
    if (log.type == 'OUT') return Icons.logout_rounded;
    if (log.status == 'ON_TIME') return Icons.verified_rounded;
    return Icons.warning_amber_rounded;
  }

  String _getStatusText(Attendance log) {
    if (log.type == 'OUT') return 'Absen Keluar';
    if (log.status == 'ON_TIME') return 'Tepat Waktu';
    return 'Terlambat';
  }

  void _showLogDetail(Attendance log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getTimeColor(log).withOpacity(0.08),
              Colors.white,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 6,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Hero(
                      tag: 'icon_${log.id}',
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getTimeColor(log),
                              _getTimeColor(log).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: _getTimeColor(log).withOpacity(0.5),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getTimeIcon(log),
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Absensi',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getTimeColor(log).withOpacity(0.15),
                                  _getTimeColor(log).withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(log),
                              style: TextStyle(
                                color: _getTimeColor(log),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildGlassDetailCard([
                  _buildDetailRow(
                    Icons.person_rounded,
                    'Nama Karyawan',
                    _empName(log.employeeId),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    Icons.calendar_today_rounded,
                    'Tanggal',
                    DateFormat('EEEE, dd MMMM yyyy').format(log.timestamp),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Waktu',
                    DateFormat('HH:mm:ss').format(log.timestamp),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    Icons.label_rounded,
                    'Tipe Absensi',
                    log.type == 'IN' ? 'Absen Masuk' : 'Absen Keluar',
                  ),
                ]),
                if (log.photoPath.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Foto Absensi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'photo_${log.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.file(
                        File(log.photoPath),
                        fit: BoxFit.cover,
                        height: 300,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[200]!, Colors.grey[100]!],
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_rounded, size: 80, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text(
                                'Foto tidak tersedia',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDetailCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: Colors.blue.shade700),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _exportToExcel() async {
    try {
      final filteredLogs = _getFilteredLogs();
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Riwayat Absensi'];

      sheet.appendRow(['Nama Karyawan', 'Tanggal', 'Waktu', 'Type', 'Status']);

      for (final log in filteredLogs) {
        sheet.appendRow([
          _empName(log.employeeId),
          _dateFormat.format(log.timestamp),
          _timeFormat.format(log.timestamp),
          log.type == 'IN' ? 'Absen Masuk' : 'Absen Keluar',
          _getStatusText(log),
        ]);
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'riwayat_absensi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(excelFile.encode()!);
      await OpenFile.open(file.path);

      _showSnackBar('✅ File Excel berhasil disimpan', const Color(0xFF10B981));
    } catch (e) {
      _showSnackBar('❌ Gagal export Excel: $e', const Color(0xFFEF4444));
    }
  }

  Future<void> _exportToPDF() async {
    try {
      final filteredLogs = _getFilteredLogs();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Riwayat Absensi',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Nama', 'Tanggal', 'Waktu', 'Type', 'Status'],
                data: filteredLogs
                    .map((log) => [
                          _empName(log.employeeId),
                          _dateFormat.format(log.timestamp),
                          _timeFormat.format(log.timestamp),
                          log.type == 'IN' ? 'Masuk' : 'Keluar',
                          _getStatusText(log),
                        ])
                    .toList(),
              ),
            ];
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'riwayat_absensi_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      _showSnackBar('✅ File PDF berhasil disimpan', const Color(0xFF10B981));
    } catch (e) {
      _showSnackBar('❌ Gagal export PDF: $e', const Color(0xFFEF4444));
    }
  }

  void _showDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate != null && pickedDate != _selectedDate) {
        setState(() => _selectedDate = pickedDate);
        _load();
      }
    });
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1.0 + (value * 0.05),
          child: FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _selectedFilter = label);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF6366F1),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
                width: 2,
              ),
            ),
            elevation: isSelected ? 8 : 0,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(Attendance log) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 6,
            shadowColor: _getTimeColor(log).withOpacity(0.4),
            child: InkWell(
              onTap: () => _showLogDetail(log),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _getTimeColor(log).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _getTimeColor(log).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Hero(
                      tag: 'icon_${log.id}',
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getTimeColor(log),
                              _getTimeColor(log).withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getTimeColor(log).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getTimeIcon(log),
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                        Text(
                          _empName(log.employeeId),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getTimeColor(log).withOpacity(0.15),
                            _getTimeColor(log).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _getStatusText(log),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTimeColor(log),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 15, color: Colors.grey.shade600),
                        const SizedBox(width: 5),
                        Text(
                          _timeFormat.format(log.timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1E293B), // Slate-800
                  const Color(0xFF0F172A), // Slate-900
                  const Color(0xFF020617), // Slate-950
              ],
            ),
          ),
        ),
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: -0.5,
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() => _isGridView = !_isGridView);
                },
                tooltip: _isGridView ? 'List View' : 'Grid View',
              ),
            ),
          ),
          ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                onPressed: filteredLogs.isEmpty ? null : _showExportDialog,
                tooltip: 'Export',
              ),
            ),
          ),
          ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.calendar_today_outlined, color: Colors.white),
                onPressed: _showDatePicker,
                tooltip: 'Pilih Tanggal',
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E293B), // Slate-800
              const Color(0xFF0F172A), // Slate-900
              const Color(0xFF020617), // Slate-950
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Statistics Cards
              if (!_isLoading && _logs.isNotEmpty)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    height: 120,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: 4,
                      separatorBuilder: (context, index) => const SizedBox(width: 5),
                      itemBuilder: (context, index) {
                        switch (index) {
                          case 0:
                            return _buildStatCard(
                              'Total',
                              '${filteredLogs.length}',
                              Icons.assignment_turned_in_rounded,
                              const Color(0xFF6366F1),
                            );
                          case 1:
                            return _buildStatCard(
                              'Tepat Waktu',
                              '${filteredLogs.where((log) => log.status == 'ON_TIME').length}',
                              Icons.verified_rounded,
                              const Color(0xFF10B981),
                            );
                          case 2:
                            return _buildStatCard(
                              'Terlambat',
                              '${filteredLogs.where((log) => log.status == 'LATE').length}',
                              Icons.warning_amber_rounded,
                              const Color(0xFFEF4444),
                            );
                          case 3:
                            return _buildStatCard(
                              'Keluar',
                              '${filteredLogs.where((log) => log.type == 'OUT').length}',
                              Icons.logout_rounded,
                              const Color(0xFF8B5CF6),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),

              // Search and Filters
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari nama karyawan...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: const Color(0xFF6366F1),
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear_rounded, color: Colors.grey.shade400),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Semua'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Hari Ini'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Minggu Ini'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Bulan Ini'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Logs List or Grid
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: const Duration(milliseconds: 1500),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 6.28,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF6366F1),
                                          const Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.sync_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Memuat data...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredLogs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF6366F1).withOpacity(0.1),
                                        const Color(0xFF8B5CF6).withOpacity(0.05),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.inbox_rounded,
                                    size: 100,
                                    color: const Color(0xFF6366F1).withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Belum ada riwayat',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Data absensi akan muncul di sini',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: RefreshIndicator(
                                onRefresh: () => _load(),
                                color: const Color(0xFF6366F1),
                                backgroundColor: Colors.white,
                                child: _isGridView
                                    ? GridView.builder(
                                        padding: const EdgeInsets.all(16),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.85,
                                        ),
                                        itemCount: filteredLogs.length + (_isLoadingMore ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index >= filteredLogs.length) {
                                            return Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  const Color(0xFF6366F1),
                                                ),
                                              ),
                                            );
                                          }
                                          return _buildGridItem(filteredLogs[index]);
                                        },
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        itemCount: filteredLogs.length + (_isLoadingMore ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index >= filteredLogs.length) {
                                            return Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    const Color(0xFF6366F1),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final log = filteredLogs[index];
                                          return TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: Duration(milliseconds: 400 + (index * 50)),
                                            curve: Curves.easeOutBack,
                                            builder: (context, value, child) {
                                              return Transform.translate(
                                                offset: Offset(0, 20 * (1 - value)),
                                                child: Opacity(
                                                  opacity: value,
                                                  child: Card(
                                                    margin: const EdgeInsets.only(bottom: 16),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(28),
                                                    ),
                                                    elevation: 8,
                                                    shadowColor:
                                                        _getTimeColor(log).withOpacity(0.3),
                                                    child: InkWell(
                                                      onTap: () => _showLogDetail(log),
                                                      borderRadius: BorderRadius.circular(28),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(20),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              Colors.white,
                                                              _getTimeColor(log).withOpacity(0.05),
                                                            ],
                                                            begin: Alignment.topLeft,
                                                            end: Alignment.bottomRight,
                                                          ),
                                                          borderRadius: BorderRadius.circular(28),
                                                          border: Border.all(
                                                            color:
                                                                _getTimeColor(log).withOpacity(0.2),
                                                            width: 2,
                                                          ),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            Hero(
                                                              tag: 'icon_${log.id}',
                                                              child: Container(
                                                                padding: const EdgeInsets.all(16),
                                                                decoration: BoxDecoration(
                                                                  gradient: LinearGradient(
                                                                    colors: [
                                                                      _getTimeColor(log),
                                                                      _getTimeColor(log)
                                                                          .withOpacity(0.7),
                                                                    ],
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(20),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: _getTimeColor(log)
                                                                          .withOpacity(0.5),
                                                                      blurRadius: 16,
                                                                      offset: const Offset(0, 8),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Icon(
                                                                  _getTimeIcon(log),
                                                                  color: Colors.white,
                                                                  size: 32,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    _empName(log.employeeId),
                                                                    style: const TextStyle(
                                                                      fontSize: 19,
                                                                      fontWeight: FontWeight.bold,
                                                                      letterSpacing: -0.3,
                                                                      color: Colors.white,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 8),
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets.symmetric(
                                                                      horizontal: 12,
                                                                      vertical: 6,
                                                                    ),
                                                                    decoration: BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        colors: [
                                                                          _getTimeColor(log)
                                                                              .withOpacity(0.15),
                                                                          _getTimeColor(log)
                                                                              .withOpacity(0.05),
                                                                        ],
                                                                      ),
                                                                      borderRadius:
                                                                          BorderRadius.circular(14),
                                                                    ),
                                                                    child: Text(
                                                                      _getStatusText(log),
                                                                      style: TextStyle(
                                                                        fontSize: 13,
                                                                        color: _getTimeColor(log),
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 10),
                                                                  Row(
                                                                    children: [
                                                                      Icon(
                                                                        Icons.calendar_today_rounded,
                                                                        size: 16,
                                                                        color: Colors.grey.shade600,
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Text(
                                                                        _dateFormat
                                                                            .format(log.timestamp),
                                                                        style: TextStyle(
                                                                          fontSize: 13,
                                                                          color:
                                                                              Colors.grey.shade600,
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(width: 16),
                                                                      Icon(
                                                                        Icons.access_time_rounded,
                                                                        size: 16,
                                                                        color: Colors.grey.shade600,
                                                                      ),
                                                                      const SizedBox(width: 6),
                                                                      Text(
                                                                        _timeFormat
                                                                            .format(log.timestamp),
                                                                        style: TextStyle(
                                                                          fontSize: 13,
                                                                          color:
                                                                              Colors.grey.shade600,
                                                                          fontWeight: FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            Icon(
                                                              Icons.chevron_right_rounded,
                                                              color: Colors.grey.shade400,
                                                              size: 32,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 24,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFF6366F1).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF6366F1),
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.file_download_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Export Riwayat',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih format file untuk export',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToPDF();
                        },
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 24),
                        label: const Text('PDF', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFFEF4444).withOpacity(0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _exportToExcel();
                        },
                        icon: const Icon(Icons.table_chart_rounded, size: 24),
                        label: const Text('Excel', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}