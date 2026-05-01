import 'package:flutter/material.dart';
import 'dart:async';
import '../login_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'main_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  final List<String> _greetings = ['Hello', 'Hola', 'Bonjour', 'Muli bwanji', 'Welcome'];
  int _currentIndex = 0;
  Timer? _timer;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    
    // Change text every 800ms
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_currentIndex < _greetings.length - 1) {
        setState(() {
          _currentIndex++;
        });
      }
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 4500));
    
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final useBiometric = prefs.getBool('use_biometric') ?? false;

    if (useBiometric) {
      try {
        final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
        final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

        if (canAuthenticate) {
          final bool didAuthenticate = await auth.authenticate(
            localizedReason: 'Please authenticate to access your dashboard',
            biometricOnly: false,
          );

          if (didAuthenticate) {
            _navigateTo(const MainLayout());
            return;
          }
        }
      } catch (e) {
        print('Biometric error: $e');
      }
    }
    
    // Fallback to login screen
    _navigateTo(const LoginScreen());
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Match the dark theme
      body: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _greetings[_currentIndex],
            key: ValueKey<int>(_currentIndex),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF9900),
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }
}
