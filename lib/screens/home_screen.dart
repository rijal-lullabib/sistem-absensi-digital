// ignore_for_file: deprecated_member_use, use_build_context_synchronously, dead_code, unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'attendance_screen.dart';
import 'log_screen_fixed.dart';
import 'managemen_screen.dart';
import '../services/auth_service.dart';
import '../utils/responsive_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late List<AnimationController> _cardControllers;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  
  final List<Particle> _particles = [];
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 30; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 4 + 2,
          speedX: (random.nextDouble() - 0.5) * 0.002,
          speedY: (random.nextDouble() - 0.5) * 0.002,
          opacity: random.nextDouble() * 0.5 + 0.2,
        ),
      );
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _particleController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _rotateController,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();

    Future.delayed(const Duration(milliseconds: 400), () {
      for (int i = 0; i < _cardControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 200), () {
          if (mounted) _cardControllers[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Elegant gradient background
          Container(
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
          ),

          // Subtle pattern overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                  Colors.white.withOpacity(0.01),
                ],
              ),
            ),
          ),
          
          // Animated particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _particleController.value),
                size: Size.infinite,
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header Section
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      child: Column(
                        children: [
                          // Elegant logo
                          Container(
                            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 24)),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Container(
                              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 20)),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.business_center_rounded,
                                size: ResponsiveUtils.getIconSize(context, 48),
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),

                          // Professional title
                          Text(
                            'Sistem Absensi',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getTitleFontSize(context, 32),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getSpacing(context, 20),
                              vertical: ResponsiveUtils.getSpacing(context, 10),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'PT Jasakula Purwa Luhur',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 14),
                                color: Colors.white,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Glassmorphism Menu Cards
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      margin: ResponsiveUtils.getResponsiveMargin(context),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: ResponsiveUtils.getBorderRadius(context),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.getSpacing(context, 24),
                          ResponsiveUtils.getSpacing(context, 32),
                          ResponsiveUtils.getSpacing(context, 24),
                          ResponsiveUtils.getSpacing(context, 24),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildElegantMenuCard(
                                context,
                                controller: _cardControllers[0],
                                index: 0,
                                icon: Icons.people_alt_rounded,
                                title: 'Management Pegawai',
                                subtitle: 'Kelola data karyawan',
                                primaryColor: const Color(0xFF6366F1),
                                onTap: () => Navigator.of(context).push(_createRoute(const ManagemenScreen())),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
                              _buildElegantMenuCard(
                                context,
                                controller: _cardControllers[1],
                                index: 1,
                                icon: Icons.camera_alt_rounded,
                                title: 'Absensi Sekarang',
                                subtitle: 'Scan wajah untuk absensi',
                                primaryColor: const Color(0xFF10B981),
                                onTap: () => Navigator.of(context).push(_createRoute(const AttendanceScreen())),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, 16)),
                              _buildElegantMenuCard(
                                context,
                                controller: _cardControllers[2],
                                index: 2,
                                icon: Icons.history_rounded,
                                title: 'Riwayat Absensi',
                                subtitle: 'Lihat data kehadiran',
                                primaryColor: const Color(0xFF6366F1),
                                onTap: () => Navigator.of(context).push(_createRoute(const LogScreen())),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, 32)),
                              // Elegant logout button
                              Container(
                                width: double.infinity,
                                height: ResponsiveUtils.getButtonHeight(context),
                                decoration: BoxDecoration(
                                  borderRadius: ResponsiveUtils.getBorderRadius(context),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade500.withOpacity(0.8),
                                      Colors.red.shade700.withOpacity(0.8),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.red.shade400.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      await AuthService.logout();
                                      if (mounted) {
                                        Navigator.of(context).pushReplacementNamed('/');
                                      }
                                    },
                                    borderRadius: ResponsiveUtils.getBorderRadius(context),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.getSpacing(context, 24),
                                        vertical: ResponsiveUtils.getSpacing(context, 16),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout_rounded,
                                            color: Colors.white,
                                            size: ResponsiveUtils.getIconSize(context, 20),
                                          ),
                                          SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: ResponsiveUtils.getFontSize(context, 16),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  Widget _buildElegantMenuCard(
    BuildContext context, {
    required AnimationController controller,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));

    final fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeIn,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: ResponsiveUtils.getSpacing(context, 4)),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: ResponsiveUtils.getBorderRadius(context),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: ResponsiveUtils.getBorderRadius(context),
              child: Padding(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 12)),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: ResponsiveUtils.getBorderRadius(context),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: ResponsiveUtils.getIconSize(context, 24),
                        color: primaryColor,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getSpacing(context, 16)),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, 16),
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSpacing(context, 4)),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, 13),
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Arrow icon
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: ResponsiveUtils.getIconSize(context, 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Particle class for floating background animation
class Particle {
  double x;
  double y;
  final double size;
  final double speedX;
  final double speedY;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speedX,
    required this.speedY,
    required this.opacity,
  });

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1) x = x.clamp(0, 1);
    if (y < 0 || y > 1) y = y.clamp(0, 1);
  }
}

// Custom painter for particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();
      
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
