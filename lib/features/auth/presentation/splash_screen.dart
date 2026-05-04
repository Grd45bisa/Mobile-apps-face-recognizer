import 'package:flutter/material.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../../shared/services/auth_service.dart';
import '../../../shared/services/realtime_sync_service.dart';
import '../../../shared/store/app_store.dart';
import '../../../shared/theme/app_colors.dart';
import '../../main_nav/main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Beri waktu splash tampil sebentar supaya tidak terlalu kilat
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    if (AuthService.instance.isSignedIn) {
      final uid = AuthService.instance.currentUserId;
      AppStore.instance.loadFromCloud().then((_) {
        NotificationProvider.instance.refresh();
      });
      if (uid != null) RealtimeSyncService.instance.subscribe(uid);
      _navigate(const MainScreen());
    } else {
      _navigate(const LoginScreen());
    }
  }

  void _navigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (ctx, a1, a2) => screen,
        transitionsBuilder: (ctx, anim, a2, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLogo(),
              const SizedBox(height: 48),
              _buildLoader(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.face_retouching_natural_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'FaceWork Tracker',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sistem Absensi Karyawan',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Memuat...',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
