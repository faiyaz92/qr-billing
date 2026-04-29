import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_based_billing/app_router.dart';
import '../../core/injection.dart';
import '../cubits/home_cubit.dart';
import '../cubits/home_state.dart';
import '../cubits/quick_scan_cubit.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  void _playBeep() async {
    // Audio removed
  }

  void _showQuickScanDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider(
        create: (context) => getIt<QuickScanCubit>(),
        child: AlertDialog(
          title: const Text('Quick Scan Product'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: BlocConsumer<QuickScanCubit, QuickScanState>(
              listener: (context, state) {
                if (state is QuickScanSuccess) {
                  Navigator.of(dialogContext).pop(); // Close dialog
                  _playBeep();
                  context.router.push(ProductDetailsRoute(scannedData: state.scannedData));
                } else if (state is QuickScanError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                  Navigator.of(dialogContext).pop(); // Close dialog
                }
              },
              builder: (context, state) {
                if (state is QuickScanLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return Column(
                  children: [
                    const Text('Scan a product QR code'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: MobileScanner(
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            final String? code = barcode.rawValue;
                            if (code != null) {
                              context.read<QuickScanCubit>().quickScanProduct(code);
                              break;
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>()..loadHome(),
      child: BlocBuilder<HomeCubit, HomeState>(
        buildWhen: (previous, current) => current is HomeLoaded,
        builder: (context, state) {
          return Scaffold(
            body: Column(
              children: [
                // Top App Bar with Gradient
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF1E40AF), // Deep Blue
                        Color(0xFF06B6D4), // Teal
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Text(
                            'QR Billing Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {}, // Settings
                            icon: const Icon(Icons.settings, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Welcome Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF1E40AF), // Deep Blue
                        Color(0xFF06B6D4), // Teal
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Manage your products and billing efficiently with our professional tools',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dashboard Grid
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFF8FAFC), // Light background
                          Color(0xFFF1F5F9), // Slightly darker
                        ],
                      ),
                    ),
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildDashboardCard(
                          title: 'Start Billing',
                          subtitle: 'Scan & Bill',
                          icon: Icons.shopping_cart,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          onTap: () => context.router.push(BillingRoute()),
                        ),
                        _buildDashboardCard(
                          title: 'Quick Scan',
                          subtitle: 'Fast Product Scan',
                          icon: Icons.qr_code_scanner,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                          ),
                          onTap: _showQuickScanDialog,
                        ),
                        _buildDashboardCard(
                          title: 'Product Management',
                          subtitle: 'Manage Products',
                          icon: Icons.inventory_2,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                          ),
                          onTap: () => context.router.push(const ProductListRoute()),
                        ),
                        _buildDashboardCard(
                          title: 'Daily Sales',
                          subtitle: 'View Reports',
                          icon: Icons.analytics,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)],
                          ),
                          onTap: () => context.router.push(const DailySalesRoute()),
                        ),
                        _buildDashboardCard(
                          title: 'Settings',
                          subtitle: 'App Preferences',
                          icon: Icons.settings,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
                          ),
                          onTap: () => context.router.push(const SettingsRoute()),
                        ),
                        _buildDashboardCard(
                          title: 'Analytics',
                          subtitle: 'Business Insights',
                          icon: Icons.bar_chart,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                          ),
                          onTap: () => context.router.push(const AnalyticsRoute()),
                        ),
                        _buildDashboardCard(
                          title: 'DB Import/Export',
                          subtitle: 'Backup & Restore',
                          icon: Icons.import_export_rounded,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                          ),
                          onTap: () => context.router.push(const DbImportExportRoute()),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 140,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon at top
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              // Text at bottom
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
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