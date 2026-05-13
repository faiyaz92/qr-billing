import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_based_billing/app_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/injection.dart';
import '../cubits/splash_cubit.dart';
import '../cubits/splash_state.dart';

@RoutePage()
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SplashCubit>()..completeSplash(),
      child: BlocConsumer<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state is SplashCompleted) {
            context.router.replace(const HomeRoute());
          }
        },
        builder: (context, state) {
          if (state is SplashUpdateRequired) {
            return _buildUpdateScreen(context, state);
          }

          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF1E40AF), // Blue
                    Color(0xFF3B82F6), // Lighter blue
                    Color(0xFF60A5FA), // Even lighter blue
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // QR Code Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner,
                        size: 60,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // App Name
                    const Text(
                      'Qr Billing',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tagline
                    Text(
                      'Smart & Fast Billing Solution',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Loading indicator
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpdateScreen(BuildContext context, SplashUpdateRequired state) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              const Text(
                'Update Required',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'A new version of Qr Billing is available (${state.storeVersion}). Please update to continue using the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () async {
                  final Uri url = Uri.parse(state.storeUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E40AF),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'UPDATE NOW',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}