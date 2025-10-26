// ignore_for_file: unused_field, deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';
import '../models/attendance.dart';
import '../models/employee.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:printing/printing.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final _searchController = TextEditingController();
  List<Attendance> _logs = [];
  List<Employee> _employees = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String _selectedFilter = 'Semua';
  String _searchQuery = '';
  int _page = 1;
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _page = 1;
    });
    _load();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMoreData()) {
        _load(loadMore: true);
      }
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Laporan Absensi',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              headerHeight: 25,
              cellHeight: 40,
              headerStyle: pw.TextStyle(
                color: PdfColors.black,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 12),
              headers: ['Nama', 'Tanggal', 'Waktu', 'Jenis', 'Status'],
              data: _logs.map((log) {
                final employee = _employees.firstWhere(
                  (e) => e.id == log.employeeId,
                  orElse: () => Employee(
                    id: 0,
                    name: 'Unknown',
                    photoPath: '',
                    faceHash: '',
                  ),
                );
                final dateTime = DateTime.parse(log.timestamp.toString());
                final type = log.getType() == 'IN' ? 'Masuk' : 'Pulang';
                final status = log.getStatus() == 'ON_TIME'
                    ? 'Tepat Waktu'
                    : 'Terlambat';

                return [
                  employee.name,
                  DateFormat('dd/MM/yyyy').format(dateTime),
                  DateFormat('HH:mm').format(dateTime),
                  type,
                  status,
                ];
              }).toList(),
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'laporan_absensi_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf',
    );
  }

  Future<void> _exportToExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Absensi'];

    // Add headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        'Nama';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value =
        'Tanggal';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value =
        'Waktu';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value =
        'Jenis';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value =
        'Status';

    // Add data
    var row = 1;
    for (var log in _logs) {
      final employee = _employees.firstWhere(
        (e) => e.id == log.employeeId,
        orElse: () =>
            Employee(id: 0, name: 'Unknown', photoPath: '', faceHash: ''),
      );
      final dateTime = DateTime.parse(log.timestamp.toString());
      final type = log.getType() == 'IN' ? 'Masuk' : 'Pulang';
      final status = log.getStatus() == 'ON_TIME' ? 'Tepat Waktu' : 'Terlambat';

      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
              .value =
          employee.name;
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = DateFormat(
        'dd/MM/yyyy',
      ).format(dateTime);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = DateFormat(
        'HH:mm',
      ).format(dateTime);
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
              .value =
          type;
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
              .value =
          status;
      row++;
    }

    // Auto-fit columns
    sheet.setColWidth(0, 20);
    sheet.setColWidth(1, 15);
    sheet.setColWidth(2, 10);
    sheet.setColWidth(3, 12);
    sheet.setColWidth(4, 15);

    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'laporan_absensi_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.xlsx';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(excel.encode()!);
    await OpenFile.open(filePath);
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Riwayat Absensi'),
          content: const Text('Pilih format export:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToPdf();
              },
              child: const Text('PDF', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exportToExcel();
              },
              child: const Text('Excel', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  bool _hasMoreData() {
    return (_page - 1) * _pageSize < _logs.length;
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
      final dataService = DataService.instance;
      final logs = await dataService.getAllAttendance();
      final emps = await dataService.getAllEmployees();

      if (mounted) {
        setState(() {
          if (!loadMore) {
            _logs = logs.reversed.toList();
            _employees = emps;
          } else {
            _page++;
            _logs = logs.reversed.toList();
          }
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        title: const Text(
          'Riwayat Absensi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            onPressed: _logs.isEmpty ? null : _showExportDialog,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade400),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedFilter == 'Semua',
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade200),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'Semua';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Hari Ini'),
                        selected: _selectedFilter == 'Hari Ini',
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade200),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'Hari Ini';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Minggu Ini'),
                        selected: _selectedFilter == 'Minggu Ini',
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade700,
                        side: BorderSide(color: Colors.blue.shade200),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = 'Minggu Ini';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade600,
                      ),
                    ),
                  )
                : _logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: Colors.blue.shade200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada riwayat absensi',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue.shade300,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _load(),
                    color: Colors.blue.shade600,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _logs.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _logs.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue.shade400,
                                ),
                              ),
                            ),
                          );
                        }

                        final log = _logs[index];
                        final employee = _employees.firstWhere(
                          (e) => e.id == log.employeeId,
                          orElse: () => Employee(
                            id: 0,
                            name: 'Unknown',
                            photoPath: '',
                            faceHash: '',
                          ),
                        );

                        final dateTime = DateTime.parse(
                          log.timestamp.toString(),
                        );
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                        ).format(dateTime);
                        final formattedTime = DateFormat(
                          'HH:mm',
                        ).format(dateTime);

                        final type = log.getType() == 'IN' ? 'Masuk' : 'Pulang';
                        final status = log.getStatus() == 'ON_TIME'
                            ? 'Tepat Waktu'
                            : 'Terlambat';
                        final isLate = log.getStatus() == 'LATE';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isLate
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isLate
                                  ? Colors.red.shade400
                                  : Colors.blue.shade500,
                              child: Text(
                                employee.name.isNotEmpty
                                    ? employee.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  employee.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLate
                                        ? Colors.red.shade50
                                        : Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isLate
                                          ? Colors.red.shade200
                                          : Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLate
                                          ? Colors.red.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '$formattedDate - $formattedTime',
                                  style: TextStyle(
                                    color: isLate
                                        ? Colors.red.shade700
                                        : Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLate
                                        ? Colors.red.shade600
                                        : Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.chevron_right,
                              color: isLate
                                  ? Colors.red.shade400
                                  : Colors.blue.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
