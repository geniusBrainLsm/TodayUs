import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config/api_endpoints.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/user_profile_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _scaleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  RobotAppearance? _activeRobot;

  @override
  void initState() {
    super.initState();
    _loadRobotAppearance();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadRobotAppearance() async {
    final appearance = await UserProfileStore.loadActiveRobot();
    if (!mounted) return;
    setState(() {
      _activeRobot = appearance;
    });
  }

  Future<void> _startAnimations() async {
    _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await _checkForOAuth2Token();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _navigateToNextScreen();
  }

  Future<void> _checkForOAuth2Token() async {
    try {
      if (!Uri.base.hasQuery) return;
      final uri = Uri.base;
      final token = uri.queryParameters['token'];
      final error = uri.queryParameters['error'];

      if (error != null) {
        debugPrint('OAuth2 error: ${Uri.decodeComponent(error)}');
        return;
      }

      if (token != null) {
        try {
          await AuthService.saveToken(token);
          debugPrint('OAuth2 token saved successfully');
        } catch (e) {
          debugPrint('Error saving OAuth2 token: $e');
        }
      }
    } catch (e) {
      debugPrint('URL parameter check failed: $e');
    }
  }

  Future<void> _navigateToNextScreen() async {
    try {
      final token = await ApiService.getAuthToken();

      if (token != null && token.isNotEmpty) {
        final nextRoute = await _checkUserOnboardingStatus(token);
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(nextRoute);
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  Future<String> _checkUserOnboardingStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        await UserProfileStore.saveUserSnapshot(responseData);
        return _determineNextRoute();
      } else {
        await ApiService.clearAuthToken();
        return '/login';
      }
    } catch (e) {
      debugPrint('Onboarding route check failed: $e');
      return '/login';
    }
  }

  Future<String> _determineNextRoute() async {
    try {
      final response = await ApiService.get(ApiEndpoints.onboardingStatus);
      if (ApiService.isSuccessful(response.statusCode)) {
        final data = ApiService.parseResponse(response) ?? {};
        final nextStep = data['nextStep']?.toString() ?? 'home';
        switch (nextStep) {
          case 'nickname':
            return '/nickname-input';
          case 'couple_connection':
            return '/couple-connection';
          case 'anniversary_setup':
            return '/anniversary-setup';
          default:
            return '/home';
        }
      }
    } catch (e) {
      debugPrint('Failed to load onboarding status: $e');
    }
    return '/home';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(75),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(75),
                      child: _buildSplashRobotImage(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSplashRobotImage() {
    final primaryUrl = _activeRobot?.splashImageUrl ?? '';
    final fallbackUrl = _activeRobot?.imageUrl ?? '';
    final imageUrl = primaryUrl.isNotEmpty ? primaryUrl : fallbackUrl;

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackSplashIcon(),
      );
    }
    return _fallbackSplashIcon();
  }

  Widget _fallbackSplashIcon() {
    return Icon(
      Icons.smart_toy,
      size: 75,
      color: Colors.grey[400],
    );
  }
}
