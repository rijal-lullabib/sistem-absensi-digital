// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../services/db_helper.dart';
import '../models/attendance.dart';
import '../utils/responsive_utils.dart';
import 'dart:async';

class AttendanceScreenNew extends StatefulWidget {
  const AttendanceScreenNew({super.key});

  @override
  State<AttendanceScreenNew> createState() => _AttendanceScreenNewState();
}

class _AttendanceScreenNewState extends State<AttendanceScreenNew>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFaceDetected = false;
  bool _isDisposed = false;
  String _status = 'Memuat kamera...';
  Timer? _debounceTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;
  bool _showFlash = false;
  
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  static const int startHour = 8;
  static const int startMinute = 0;
  static const int endHour = 17;
  static const int endMinute = 0;
  static const int toleranceMinutes = 15;
  static const int endToleranceMinutes = 15;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _pulseController.dispose();
    _flashController.dispose();
    _stopCamera();
    _faceDetector.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isCameraInitialized && !_isDisposed) {
        _initializeCamera();
      }
    }
  }

  String _determineAttendanceType(DateTime now) {
    final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final toleranceTime = startTime.add(Duration(minutes: toleranceMinutes));
    final endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);
    final endToleranceTime = endTime.add(Duration(minutes: endToleranceMinutes));

    if (now.isAfter(startTime.subtract(const Duration(seconds: 1))) && now.isBefore(toleranceTime)) {
      return 'IN';
    } else if (now.isAfter(endTime.subtract(const Duration(seconds: 1))) && now.isBefore(endToleranceTime)) {
      return 'OUT';
    } else {
      return 'INVALID';
    }
  }

  String _determineAttendanceStatus(DateTime now, String type) {
    if (type == 'OUT') return 'ON_TIME';

    final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final toleranceTime = startTime.add(Duration(minutes: toleranceMinutes));
    return now.isBefore(toleranceTime) ? 'ON_TIME' : 'LATE';
  }

  String _getStatusMessage(String type, String status) {
    if (type == 'IN') {
      return status == 'ON_TIME'
          ? 'Absen masuk berhasil. Selamat bekerja!'
          : 'Absen masuk berhasil. Anda terlambat!';
    }
    return 'Absen pulang berhasil. Hati-hati di jalan!';
  }

  Color _getStatusColor() {
    if (_status.contains('berhasil')) return const Color(0xFF1E293B);
    if (_status.contains('Memproses')) return Colors.yellowAccent;
    if (_status.contains('Gagal') || _status.contains('Error')) return Colors.redAccent;
    return Colors.white;
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    try {
      if (mounted) {
        setState(() => _status = 'Memuat kamera...');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _status = 'Tidak ada kamera tersedia');
        }
        return;
      }

      if (_isDisposed) return;

      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      
      if (_isDisposed || !mounted) {
        _cameraController?.dispose();
        return;
      }

      setState(() {
        _isCameraInitialized = true;
        _status = 'Posisikan wajah Anda di dalam bingkai';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!_isDisposed && _isCameraInitialized) {
        _startFaceDetection();
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _status = 'Error kamera: ${e.toString()}');
      }
    }
  }

  void _stopCamera() {
    try {
      _cameraController?.stopImageStream().catchError((_) {});
      _cameraController?.dispose();
      _cameraController = null;
      _isCameraInitialized = false;
    } catch (e) {
      // Error stopping camera
    }
  }

  Future<void> _startFaceDetection() async {
    if (_isDisposed || _cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _cameraController!.startImageStream((CameraImage image) async {
        if (_isProcessing || _isDisposed || _status.contains('berhasil')) return;
        _isProcessing = true;

        try {
          final inputImage = _convertCameraImage(image);
          if (inputImage == null) {
            _isProcessing = false;
            return;
          }

          final faces = await _faceDetector.processImage(inputImage);

          if (_isDisposed || !mounted) {
            _isProcessing = false;
            return;
          }

          if (faces.isNotEmpty && !_isFaceDetected && !_status.contains('berhasil')) {
            _isFaceDetected = true;

            if (mounted) {
              setState(() => _showFlash = true);
              _flashController.forward(from: 0.0).then((_) {
                if (mounted) setState(() => _showFlash = false);
              });
            }

            HapticFeedback.mediumImpact();



            final employees = await DBHelper.instance.getAllEmployees();
            if (employees.isEmpty) {
              if (mounted) {
                setState(() {
                  _status = 'Tidak ada karyawan terdaftar';
                  _isFaceDetected = false;
                });
              }
              _isProcessing = false;
              return;
            }

            _processAttendance();
          } else if (faces.isEmpty && _isFaceDetected && !_status.contains('berhasil')) {
            if (mounted) {
              setState(() {
                _isFaceDetected = false;
                _status = 'Posisikan wajah Anda di dalam bingkai';
              });
            }
          }
        } catch (e) {
          if (mounted && !_isDisposed) {
            setState(() => _status = 'Error deteksi: ${e.toString()}');
          }
        } finally {
          _isProcessing = false;
        }
      });
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _status = 'Gagal memulai deteksi: ${e.toString()}');
      }
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final InputImageRotation rotation = Platform.isAndroid
          ? InputImageRotation.rotation90deg
          : InputImageRotation.rotation0deg;

      final InputImageFormat format = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      return inputImage;
    } catch (e) {
      // Error converting image
      return null;
    }
  }

  Future<void> _processAttendance() async {
    if (_debounceTimer?.isActive ?? false) return;

    _debounceTimer = Timer(const Duration(seconds: 2), () async {
      if (_isDisposed || !mounted) return;

      setState(() => _status = 'Memproses absensi...');

      try {
        final now = DateTime.now();
        final type = _determineAttendanceType(now);

        if (type == 'INVALID') {
          if (mounted && !_isDisposed) {
            _showTimeRestrictionDialog();
          }
          return;
        }

        final status = _determineAttendanceStatus(now, type);

        final employees = await DBHelper.instance.getAllEmployees();
        if (employees.isEmpty) {
          if (mounted) {
            setState(() => _status = 'Tidak ada karyawan terdaftar');
          }
          return;
        }

        final attendance = Attendance(
          employeeId: employees.first.id!,
          timestamp: now,
          photoPath: '',
          type: type,
          status: status,
        );

        await DBHelper.instance.insertAttendance(attendance);
        HapticFeedback.heavyImpact();

        if (mounted && !_isDisposed) {
          setState(() => _status = _getStatusMessage(type, status));
        }

        // Show success dialog
        await _showSuccessDialog(type, status);

        if (mounted && !_isDisposed) {
          setState(() {
            _status = 'Posisikan wajah Anda di dalam bingkai';
            _isFaceDetected = false;
          });
        }
      } catch (e) {
        if (mounted && !_isDisposed) {
          setState(() => _status = 'Gagal absensi: ${e.toString()}');
        }
        await Future.delayed(const Duration(seconds: 2));
        if (mounted && !_isDisposed) {
          setState(() {
            _status = 'Posisikan wajah Anda di dalam bingkai';
            _isFaceDetected = false;
          });
        }
      }
    });
  }

  void _showTimeRestrictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFDBEAFE),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF97316),
                        const Color(0xFFEA580C),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Waktu Absensi Tidak Valid',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Absensi hanya bisa dilakukan pada:',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, color: const Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Absen Masuk: 08:00-08:15',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: const Color(0xFF1D4ED8), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Absen Pulang: 17:00-17:15',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    Navigator.of(context).pop(); // Kembali ke home_screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Future<void> _showSuccessDialog(String type, String status) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFFDBEAFE),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        type == 'IN' ? (status == 'ON_TIME' ? const Color(0xFF10B981) : const Color(0xFFF97316)) : const Color(0xFF6366F1),
                        type == 'IN' ? (status == 'ON_TIME' ? const Color(0xFF059669) : const Color(0xFFEA580C)) : const Color(0xFF4F46E5),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'IN' ? Icons.login_rounded : Icons.logout_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  type == 'IN' ? 'Absen Masuk Berhasil' : 'Absen Pulang Berhasil',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type == 'IN'
                      ? (status == 'ON_TIME' ? 'Selamat bekerja!' : 'Anda terlambat hari ini.')
                      : 'Hati-hati di jalan!',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B), // Slate-800
        title: Text(
          'Face Detection Absensi',
          style: TextStyle(color: Colors.white, fontSize: ResponsiveUtils.getTitleFontSize(context, 20.0)),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: ResponsiveUtils.getIconSize(context, 24.0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_isCameraInitialized && !_isDisposed)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _isFaceDetected ? _pulseAnimation.value : 1.0,
                      child: CustomPaint(
                        painter: FaceFramePainter(isDetected: _isFaceDetected),
                        child: Container(),
                      ),
                    ),
                  ),
                ),

                if (_showFlash)
                  AnimatedBuilder(
                    animation: _flashAnimation,
                    builder: (context, child) => Container(
                      color: Colors.white.withOpacity(_flashAnimation.value * 0.3),
                    ),
                  ),

                Positioned(
                  bottom: ResponsiveUtils.getScreenHeight(context) * 0.06,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsivePadding(context).left,
                      vertical: 12,
                    ),
                    color: Colors.black54,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_status.contains('berhasil'))
                          Icon(
                            Icons.check_circle,
                            color: const Color.fromARGB(255, 78, 20, 193),
                            size: ResponsiveUtils.getIconSize(context, 24.0),
                          )
                        else if (_status.contains('Memproses'))
                          SizedBox(
                            width: ResponsiveUtils.getIconSize(context, 20.0),
                            height: ResponsiveUtils.getIconSize(context, 20.0),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellowAccent,
                              ),
                            ),
                          ),
                        SizedBox(width: ResponsiveUtils.getSpacing(context, 8.0)),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontSize: _status.contains('berhasil') ? ResponsiveUtils.getFontSize(context, 18.0) : ResponsiveUtils.getFontSize(context, 16.0),
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: ResponsiveUtils.getScreenHeight(context) * 0.02,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.getResponsivePadding(context).left,
                      vertical: 12,
                    ),
                    color: Colors.black54,
                    child: Column(
                      children: [
                        Text(
                          'Jam Kerja: 08:00 - 17:00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: ResponsiveUtils.getFontSize(context, 14.0),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: ResponsiveUtils.getSpacing(context, 4.0)),
                        Text(
                          'Toleransi Keterlambatan: 15 menit',
                          style: TextStyle(color: Colors.white70, fontSize: ResponsiveUtils.getFontSize(context, 12.0)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class FaceFramePainter extends CustomPainter {
  final bool isDetected;

  FaceFramePainter({required this.isDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = isDetected ? Colors.greenAccent : Colors.white.withOpacity(0.8);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = isDetected
          ? Colors.green.withOpacity(0.7)
          : Colors.white.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 12);

    final frameSize = Size(size.width * 0.7, size.height * 0.4);
    final left = (size.width - frameSize.width) / 2;
    final top = (size.height - frameSize.height) / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameSize.width, frameSize.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, glowPaint);
    canvas.drawRRect(rect, paint);

    const cornerSize = 20.0;
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = isDetected ? Colors.greenAccent : Colors.white.withOpacity(0.9);

    final cornerGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = isDetected
          ? const Color.fromARGB(255, 138, 34, 230).withOpacity(0.6)
          : Colors.white.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    _drawCorner(canvas, left, top, cornerSize, cornerGlowPaint, cornerPaint, 0);
    _drawCorner(canvas, left + frameSize.width, top, cornerSize,
        cornerGlowPaint, cornerPaint, 1);
    _drawCorner(canvas, left, top + frameSize.height, cornerSize,
        cornerGlowPaint, cornerPaint, 2);
    _drawCorner(canvas, left + frameSize.width, top + frameSize.height,
        cornerSize, cornerGlowPaint, cornerPaint, 3);
  }

  void _drawCorner(Canvas canvas, double x, double y, double size,
      Paint glowPaint, Paint paint, int corner) {
    final paths = [
      [Offset(x, y + size), Offset(x, y), Offset(x + size, y)],
      [Offset(x - size, y), Offset(x, y), Offset(x, y + size)],
      [Offset(x, y - size), Offset(x, y), Offset(x + size, y)],
      [Offset(x - size, y), Offset(x, y), Offset(x, y - size)],
    ];

    canvas.drawLine(paths[corner][0], paths[corner][1], glowPaint);
    canvas.drawLine(paths[corner][1], paths[corner][2], glowPaint);
    canvas.drawLine(paths[corner][0], paths[corner][1], paint);
    canvas.drawLine(paths[corner][1], paths[corner][2], paint);
  }

  @override
  bool shouldRepaint(FaceFramePainter oldDelegate) {
    return oldDelegate.isDetected != isDetected;
  }
}