import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 3 tam tur, yavaş başla hızlan yavaşla
    _rotationAnimation = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutQuart,
      ),
    );

    // Logo başta yavaşça belirsin
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _controller.forward();

    // Animasyon bitince geçiş yap
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _navigate();
      }
    });

    // Güvenlik için max 5 saniye bekle
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _navigate();
    });
  }

  void _navigate() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user != null ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: RotationTransition(
            turns: _rotationAnimation,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/favicon-png.png',
                width: 160,
                height: 160,
              ),
            ),
          ),
        ),
      ),
    );
  }
}