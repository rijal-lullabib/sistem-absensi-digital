// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/db_helper.dart'; // Pastikan path ini benar
import '../services/face_match_service.dart'; // Pastikan path ini benar
import '../models/employee.dart'; // Pastikan path ini benar
import '../utils/responsive_utils.dart';

// ========== ENUMS ==========
enum NotificationType { success, error, warning, info }

class ManagemenScreen extends StatefulWidget {
  const ManagemenScreen({super.key});

  @override
  State<ManagemenScreen> createState() => _ManagemenScreenState();
}

// ===========================================
// ========== MAIN DASHBOARD STATE ===========
// ===========================================
class _ManagemenScreenState extends State<ManagemenScreen>
    with TickerProviderStateMixin {
  // Data
  List<Employee> _employees = [];
  List<Employee> _filteredEmployees = [];
  bool _isLoading = true;

  // Controllers
  final TextEditingController _searchCtrl = TextEditingController();

  // Animations
  late AnimationController _listAnimController;
  late AnimationController _headerAnimController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchCtrl.addListener(_filterEmployees);
    _loadEmployees();
  }

  void _initializeAnimations() {
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _listAnimController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    ));
    _headerAnimController.forward();
  }

  @override
  void dispose() {
    _listAnimController.dispose();
    _headerAnimController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ========== DATA MANAGEMENT ==========
  void _filterEmployees() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredEmployees = _employees.where((employee) {
        return employee.name.toLowerCase().contains(query) ||
            employee.department.toLowerCase().contains(query) ||
            employee.contact.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadEmployees() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final employees = await DBHelper.instance.getAllEmployees();
      if (mounted) {
        setState(() {
          _employees = employees;
          _filteredEmployees = List.from(employees);
          _isLoading = false;
        });
        _listAnimController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showNotification('Gagal memuat data karyawan.', NotificationType.error);
        debugPrint('Error loading employees: $e');
      }
    }
  }

  // ========== EMPLOYEE ACTIONS (CRUD) ==========

  Future<void> _registerEmployee(
      String name, String department, String contact, File photo) async {
    try {
      final faceHash = await FaceMatchService.computeFaceHash(photo.path);

      // Cek duplikasi hash sederhana
      final isDuplicate = _employees.any((e) => e.faceHash == faceHash);
      if (isDuplicate) {
        _showNotification('Wajah ini sudah terdaftar!', NotificationType.warning);
        return;
      }

      final employee = Employee(
        name: name,
        photoPath: photo.path,
        faceHash: faceHash,
        department: department,
        contact: contact,
      );
      await DBHelper.instance.insertEmployee(employee);

      if (mounted) {
        _showNotification(
            'Pegawai ${employee.name} berhasil didaftarkan! 🎉', NotificationType.success);
        await _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        _showNotification('Gagal mendaftarkan: $e', NotificationType.error);
      }
      rethrow; // Lempar ulang error agar dialog bisa menangkap dan menampilkan loading/error
    }
  }

  Future<void> _updateEmployee(
      Employee employee, String name, String department, String contact) async {
    try {
      final updatedEmployee = Employee(
        id: employee.id,
        name: name,
        photoPath: employee.photoPath,
        faceHash: employee.faceHash,
        department: department,
        contact: contact,
      );
      await DBHelper.instance.updateEmployee(updatedEmployee);
      _showNotification('Berhasil diupdate! ✓', NotificationType.success);
      await _loadEmployees();
    } catch (e) {
      _showNotification('Gagal update: $e', NotificationType.error);
    }
  }

  Future<void> _deleteEmployee(int id) async {
    try {
      await DBHelper.instance.deleteEmployee(id);
      _showNotification('Berhasil dihapus ✓', NotificationType.success);
      await _loadEmployees();
    } catch (e) {
      _showNotification('Gagal menghapus: $e', NotificationType.error);
    }
  }

  // ========== UI HELPERS ==========
  void _showNotification(String message, NotificationType type) {
    // Implementasi _showNotification tetap sama
    final colors = {
      NotificationType.success: Colors.green.shade600,
      NotificationType.error: Colors.red.shade600,
      NotificationType.warning: Colors.orange.shade600,
      NotificationType.info: Colors.blue.shade600,
    };

    final icons = {
      NotificationType.success: Icons.check_circle_outline,
      NotificationType.error: Icons.error_outline,
      NotificationType.warning: Icons.warning_amber_rounded,
      NotificationType.info: Icons.info_outline,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icons[type], color: Colors.white, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: colors[type],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        elevation: 10,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ========== BUILD METHODS ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B), // Slate-800
              const Color(0xFF0F172A), // Slate-900
              const Color(0xFF020617), // Slate-950
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            _buildStatsCard(),
            const SizedBox(height: 20),
            Expanded(child: _buildEmployeeList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final appBarHeight = ResponsiveUtils.getAppBarHeight(context);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context, 20.0);
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);
    final padding = ResponsiveUtils.getResponsivePadding(context);

    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        title: Text(
          'Manajemen Karyawan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: appBarHeight,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Colors.white, size: ResponsiveUtils.getIconSize(context, 24.0)),
            onPressed: _loadEmployees,
          ),
          // Tombol Tambah Pegawai
          Padding(
            padding: EdgeInsets.only(right: padding.right),
            child: SizedBox(
              height: buttonHeight,
              child: ElevatedButton.icon(
                onPressed: _showRegistrationDialog,
                icon: Icon(Icons.person_add_rounded, color: const Color(0xFF6366F1), size: ResponsiveUtils.getIconSize(context, 20.0)),
                label: Text(
                  ResponsiveUtils.isMobileOrSmall(context) ? 'Tambah' : 'Tambah Pegawai',
                  style: TextStyle(color: const Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: ResponsiveUtils.getFontSize(context, 14.0)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveUtils.getBorderRadius(context),
                  ),
                  elevation: 4,
                  padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 12.0)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding.top, horizontal: padding.left),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF6366F1), const Color(0xFF1E293B)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.people_rounded,
              value: _employees.length,
              label: 'Total Pegawai',
            ),
            const VerticalDivider(
                color: Color.fromARGB(137, 40, 30, 77), thickness: 1.5, indent: 10, endIndent: 10),
            _StatItem(
              icon: Icons.check_circle_rounded,
              value: _employees.length,
              label: 'Siap Absen',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildListHeader(),
        const SizedBox(height: 15),
        _buildSearchBar(),
        const SizedBox(height: 15),
        Expanded(child: _buildEmployeeListContent()),
      ],
    );
  }

  Widget _buildListHeader() {
    final padding = ResponsiveUtils.getResponsivePadding(context);
    final iconSize = ResponsiveUtils.getIconSize(context, 28.0);
    final fontSize = ResponsiveUtils.getFontSize(context, 20.0);
    final titleFontSize = ResponsiveUtils.getTitleFontSize(context, 14.0);
    final borderRadius = ResponsiveUtils.getBorderRadius(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding.left),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_rounded, color: Colors.blue.shade400, size: iconSize),
              SizedBox(width: ResponsiveUtils.getSpacing(context, 8.0)),
              Text(
                'Daftar Pegawai',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 14.0), vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: borderRadius,
            ),
            child: Text(
              '${_filteredEmployees.length} Data',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari nama, departemen...',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade400),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterEmployees();
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          filled: true,
          fillColor: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildEmployeeListContent() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemBuilder: (context, index) => const EmployeeListSkeletonItem(),
      );
    }

    if (_employees.isEmpty) {
      return const EmptyState(
        icon: Icons.person_add_rounded,
        title: 'Data Pegawai Kosong',
        subtitle: 'Tekan "Tambah Pegawai" untuk memulai pendaftaran.',
      );
    }

    if (_filteredEmployees.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Pegawai Tidak Ditemukan',
        subtitle: 'Coba periksa kata kunci pencarian Anda.',
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadEmployees,
        color: Colors.blue.shade600,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: _filteredEmployees.length,
          itemBuilder: (context, index) {
            final employee = _filteredEmployees[index];
            return EmployeeCard(
              employee: employee,
              index: index,
              onTap: () => _showEmployeeDetailSheet(employee),
              onEdit: () => _showEditDialog(employee),
              onDelete: () => _showDeleteConfirmation(employee),
            );
          },
        ),
      ),
    );
  }

  // ========== DIALOGS & SHEETS ==========
  void _showRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => RegistrationDialog(
        onRegister: _registerEmployee,
        onNotification: _showNotification,
      ),
    ).then((result) {
      if (result == true) {
        _loadEmployees(); // Muat ulang data jika pendaftaran berhasil
      }
    });
  }

  void _showEmployeeDetailSheet(Employee employee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EmployeeDetailSheet(
        employee: employee,
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(employee);
        },
        onDelete: () {
          Navigator.pop(context);
          _showDeleteConfirmation(employee);
        },
      ),
    );
  }

  void _showEditDialog(Employee employee) {
    final nameController = TextEditingController(text: employee.name);
    final departmentController = TextEditingController(text: employee.department);
    final contactController = TextEditingController(text: employee.contact);

    showDialog(
      context: context,
      builder: (context) => EditEmployeeDialog(
        employeeName: employee.name,
        nameController: nameController,
        departmentController: departmentController,
        contactController: contactController,
        onSave: () async {
          if (nameController.text.trim().isEmpty) {
            _showNotification(
                'Nama tidak boleh kosong', NotificationType.warning);
            return;
          }
          await _updateEmployee(
            employee,
            nameController.text.trim(),
            departmentController.text.trim(),
            contactController.text.trim(),
          );
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        employeeName: employee.name,
        onConfirm: () async {
          if (employee.id != null) {
            await _deleteEmployee(employee.id!);
          } else {
            _showNotification(
                'ID Karyawan tidak ditemukan.', NotificationType.error);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ===========================================
// ========== MODIFIED COMPONENTS ============
// ===========================================

// --- STAT ITEMS (Lebih Ringkas) ---
class _StatItem extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 28,
          color: Colors.white,
        ),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// --- COMMON BUTTON ---
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        disabledBackgroundColor: color.withOpacity(0.5),
        disabledForegroundColor: Colors.white.withOpacity(0.7),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}

class PhotoPreview extends StatelessWidget {
  final File photo;
  final double size;

  const PhotoPreview({super.key, required this.photo, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        border: Border.all(color: Colors.blue.shade300, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular((size * 0.2) - 3),
        child: Image.file(photo, fit: BoxFit.cover),
      ),
    );
  }
}

// --- DIALOG PENDAFTARAN BARU (NEW) ---
class RegistrationDialog extends StatefulWidget {
  final Future<void> Function(String, String, String, File) onRegister;
  final void Function(String, NotificationType) onNotification;

  const RegistrationDialog({
    super.key,
    required this.onRegister,
    required this.onNotification,
  });

  @override
  State<RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<RegistrationDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  File? _photo;
  bool _isRegistering = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _departmentCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        widget.onNotification(
            'Izin kamera diperlukan untuk mengambil foto.', NotificationType.error);
        return;
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      setState(() => _photo = File(pickedFile.path));
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Sumber Foto', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: Colors.blue.shade600),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: Colors.orange.shade600),
              title: const Text('Ambil Foto Baru'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _submitRegistration() async {
    if (_nameCtrl.text.trim().isEmpty) {
      widget.onNotification(
          'Nama karyawan tidak boleh kosong.', NotificationType.warning);
      return;
    }
    if (_photo == null) {
      widget.onNotification(
          'Foto wajah diperlukan untuk registrasi.', NotificationType.warning);
      return;
    }

    setState(() => _isRegistering = true);
    try {
      await widget.onRegister(
        _nameCtrl.text.trim(),
        _departmentCtrl.text.trim(),
        _contactCtrl.text.trim(),
        _photo!,
      );
      if (mounted) Navigator.pop(context, true); // Sukses, tutup dialog dan refresh
    } catch (e) {
      // Error handling sudah dilakukan di parent, di sini cukup reset state
      debugPrint('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.person_add_rounded, color: Colors.blue),
          SizedBox(width: 10),
          Text('Daftar Pegawai Baru', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_photo != null) ...[
              PhotoPreview(photo: _photo!, size: 120),
              const SizedBox(height: 15),
            ],
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap*',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _departmentCtrl,
              decoration: const InputDecoration(
                labelText: 'Departemen/Posisi',
                prefixIcon: Icon(Icons.business_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Kontak (Opsional)',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ActionButton(
              icon: Icons.camera_alt_rounded,
              label: _photo == null ? 'Pilih Foto Wajah' : 'Ubah Foto Wajah',
              color: Colors.orange.shade600,
              onPressed: _isRegistering ? null : _showImageSourceDialog,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ActionButton(
          icon: _isRegistering
              ? Icons.hourglass_empty_rounded
              : Icons.check_circle_rounded,
          label: _isRegistering ? 'Proses...' : 'DAFTAR',
          color: Colors.blue.shade600,
          onPressed: _isRegistering ? null : _submitRegistration,
          isLoading: _isRegistering,
        ),
      ],
    );
  }
}

// ===========================================
// ========== UNCHANGED COMPONENTS ============
// (EmployeeCard, EmployeeListSkeletonItem, EmptyState, EmployeeDetailSheet, EditEmployeeDialog, DeleteConfirmationDialog)
// ===========================================

// --- LIST ITEMS & STATE (Unchanged) ---
class EmployeeListSkeletonItem extends StatefulWidget {
  const EmployeeListSkeletonItem({super.key});

  @override
  State<EmployeeListSkeletonItem> createState() =>
      _EmployeeListSkeletonItemState();
}

class _EmployeeListSkeletonItemState extends State<EmployeeListSkeletonItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey.shade100, Colors.white, Colors.grey.shade100],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final Employee employee;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.index,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade200,
                  image: employee.photoPath.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(employee.photoPath)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: employee.photoPath.isEmpty
                    ? Icon(Icons.person_rounded,
                        size: 30, color: Colors.blue.shade600)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      employee.department.isEmpty ? 'N/A' : employee.department,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_rounded, color: Colors.blue.shade600),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                    onPressed: onDelete,
                    tooltip: 'Hapus',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: Icon(icon, size: 80, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- BOTTOM SHEET & DIALOGS (Unchanged) ---

class EmployeeDetailSheet extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EmployeeDetailSheet({
    super.key,
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 30, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: PhotoPreview(photo: File(employee.photoPath), size: 100),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                employee.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            _DetailItem(
              icon: Icons.badge_rounded,
              label: 'ID Karyawan',
              value: employee.id.toString(),
            ),
            _DetailItem(
              icon: Icons.business_rounded,
              label: 'Departemen/Posisi',
              value: employee.department.isEmpty ? '-' : employee.department,
            ),
            _DetailItem(
              icon: Icons.phone_rounded,
              label: 'Kontak',
              value: employee.contact.isEmpty ? '-' : employee.contact,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    icon: Icons.edit_rounded,
                    label: 'Edit',
                    color: Colors.blue.shade600,
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ActionButton(
                    icon: Icons.delete_rounded,
                    label: 'Hapus',
                    color: Colors.red.shade600,
                    onPressed: onDelete,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditEmployeeDialog extends StatelessWidget {
  final String employeeName;
  final TextEditingController nameController;
  final TextEditingController departmentController;
  final TextEditingController contactController;
  final VoidCallback onSave;

  const EditEmployeeDialog({
    super.key,
    required this.employeeName,
    required this.nameController,
    required this.departmentController,
    required this.contactController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Edit Data ${employeeName.split(' ').first}',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: departmentController,
              decoration: const InputDecoration(labelText: 'Departemen/Posisi'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: 'Kontak'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String employeeName;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.employeeName,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Konfirmasi Hapus',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
      content: Text(
          'Apakah Anda yakin ingin menghapus data **$employeeName**? Aksi ini tidak dapat dibatalkan.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Hapus', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}