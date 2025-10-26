
// ignore_for_file: deprecated_member_use, unused_import

import 'package:absensi/screens/home_screen.dart';
import 'package:absensi/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  late AnimationController _animController;
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    
    // Main animation
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Float animation for background elements
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _floatAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    
    _animController.forward();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username dan password harus diisi';
      });
      return;
    }

    final success = await AuthService.login(username, password);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Username atau password salah';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E293B), // Slate-800
                  const Color(0xFF0F172A), // Slate-900
                  const Color(0xFF020617),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Floating circles background
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) {
                return Positioned(
                  left: (index * 100.0) % MediaQuery.of(context).size.width,
                  top: (index * 150.0) % MediaQuery.of(context).size.height + 
                       _floatAnimation.value * (index % 2 == 0 ? 1 : -1),
                  child: Opacity(
                    opacity: 0.1,
                    child: Container(
                      width: 100 + (index * 20.0),
                      height: 100 + (index * 20.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: ResponsiveUtils.getResponsivePadding(context),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: ResponsiveUtils.isDesktop(context) ? 500 : double.infinity,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated logo with glow effect
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, 28)),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 30 * _pulseAnimation.value,
                                          spreadRadius: 10 * _pulseAnimation.value,
                                        ),
                                        BoxShadow(
                                          color: const Color.fromARGB(255, 125, 60, 229).withOpacity(0.3),
                                          blurRadius: 40,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: ResponsiveUtils.getIconSize(context, 120),
                                      height: ResponsiveUtils.getIconSize(context, 120),
                                      errorBuilder: (context, error, stackTrace) =>
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                LinearGradient(
                                                  colors: [
                                                    Colors.blue.shade600,
                                                    Colors.purple.shade600,
                                                  ],
                                                ).createShader(bounds),
                                            child: Icon(
                                              Icons.fingerprint_rounded,
                                              size: ResponsiveUtils.getIconSize(context, 120),
                                              color: Colors.white,
                                            ),
                                          ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, 40)),

                            // Title with gradient
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.8),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                'Selamat Datang',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getTitleFontSize(context, 36),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, 12)),
                            Text(
                              'Masuk untuk melanjutkan',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, 16),
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, 50)),

                            // Glassmorphism card
                            Container(
                              width: double.infinity,
                              padding: ResponsiveUtils.getResponsivePadding(context),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: ResponsiveUtils.getBorderRadius(context),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Username field with glass effect
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: ResponsiveUtils.getBorderRadius(context),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _usernameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.person_rounded,
                                          color: Colors.white,
                                          size: ResponsiveUtils.getIconSize(context, 24),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.getSpacing(context, 20),
                                          vertical: ResponsiveUtils.getSpacing(context, 18),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),

                                  // Password field with glass effect
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: ResponsiveUtils.getBorderRadius(context),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_rounded,
                                          color: Colors.white,
                                          size: ResponsiveUtils.getIconSize(context, 24),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_rounded
                                                : Icons.visibility_rounded,
                                            color: Colors.white,
                                            size: ResponsiveUtils.getIconSize(context, 24),
                                          ),
                                          onPressed: () {
                                            setState(() =>
                                                _obscurePassword = !_obscurePassword);
                                          },
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: ResponsiveUtils.getSpacing(context, 20),
                                          vertical: ResponsiveUtils.getSpacing(context, 18),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Error message with slide animation
                                  if (_errorMessage.isNotEmpty) ...[
                                    SizedBox(height: ResponsiveUtils.getSpacing(context, 20)),
                                    Container(
                                      padding: ResponsiveUtils.getResponsivePadding(context).copyWith(top: 14, bottom: 14),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.15),
                                        borderRadius: ResponsiveUtils.getBorderRadius(context),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: Colors.white,
                                            size: ResponsiveUtils.getIconSize(context, 22),
                                          ),
                                          SizedBox(width: ResponsiveUtils.getSpacing(context, 12)),
                                          Expanded(
                                            child: Text(
                                              _errorMessage,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: ResponsiveUtils.getFontSize(context, 14),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  SizedBox(height: ResponsiveUtils.getSpacing(context, 30)),

                                  // Gradient login button
                                  Container(
                                    width: double.infinity,
                                    height: ResponsiveUtils.getButtonHeight(context),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.white.withOpacity(0.9),
                                        ],
                                      ),
                                      borderRadius: ResponsiveUtils.getBorderRadius(context),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: ResponsiveUtils.getBorderRadius(context),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: ResponsiveUtils.getIconSize(context, 26),
                                              height: ResponsiveUtils.getIconSize(context, 26),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors.purple.shade700,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.purple.shade700,
                                                          Colors.blue.shade700,
                                                        ],
                                                      ).createShader(bounds),
                                                  child: Text(
                                                    'Masuk Sekarang',
                                                    style: TextStyle(
                                                      fontSize: ResponsiveUtils.getFontSize(context, 18),
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: ResponsiveUtils.getSpacing(context, 10)),
                                                ShaderMask(
                                                  shaderCallback: (bounds) =>
                                                      LinearGradient(
                                                        colors: [
                                                          Colors.purple.shade700,
                                                          Colors.blue.shade700,
                                                        ],
                                                      ).createShader(bounds),
                                                  child: Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: ResponsiveUtils.getIconSize(context, 24),
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveUtils.getSpacing(context, 40)),

                            // Footer with fade effect
                            Column(
                              children: [
                                Text(
                                  'PT Jasakula Purwa Luhur',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getFontSize(context, 15),
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(height: ResponsiveUtils.getSpacing(context, 8)),
                                Text(
                                  '© 2025 Sistem Absensi',
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.getFontSize(context, 13),
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}