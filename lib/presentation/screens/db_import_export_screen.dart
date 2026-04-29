import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/injection.dart';
import '../cubits/db_import_export_cubit.dart';
import '../cubits/db_import_export_state.dart';

@RoutePage()
class DbImportExportScreen extends StatelessWidget {
  const DbImportExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DbImportExportCubit>(),
      child: const _DbImportExportView(),
    );
  }
}

class _DbImportExportView extends StatelessWidget {
  const _DbImportExportView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: BlocConsumer<DbImportExportCubit, DbImportExportState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoBanner(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      icon: Icons.upload_rounded,
                      title: 'Export Data',
                      subtitle: 'Save your data as a backup file',
                      color: const Color(0xFF1E40AF),
                    ),
                    const SizedBox(height: 12),
                    _buildExportCards(context, state),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      icon: Icons.download_rounded,
                      title: 'Import Data',
                      subtitle: 'Restore data from a backup file',
                      color: const Color(0xFF059669),
                    ),
                    const SizedBox(height: 12),
                    _buildImportCards(context, state),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      icon: Icons.history_rounded,
                      title: 'Saved Backups',
                      subtitle: 'Recent backups in app storage',
                      color: const Color(0xFF9333EA),
                    ),
                    const SizedBox(height: 12),
                    _buildSavedBackupsList(context),
                    const SizedBox(height: 24),
                    _buildWarningCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Full-screen loading overlay
              if (state is DbImportExportLoading) _buildLoadingOverlay(state.message),
            ],
          );
        },
      ),
    );
  }

  // ─── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('DB Import / Export'),
      backgroundColor: const Color(0xFF1E40AF),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  // ─── State Listener ─────────────────────────────────────────────────────────

  void _handleStateChanges(BuildContext context, DbImportExportState state) {
    if (state is DbFileSelected) {
      _showImportModeDialog(context, state.filePath, state.fileType);
    } else if (state is DbExportSuccess) {
      _showSuccessSnackbar(context, 'Exported as .${state.format} file!');
      context.read<DbImportExportCubit>().reset();
    } else if (state is DbDownloadSuccess) {
      _showSuccessSnackbar(context, 'Downloaded to Downloads folder!');
      context.read<DbImportExportCubit>().reset();
    } else if (state is DbImportSuccess) {
      _showImportSuccessDialog(context);
    } else if (state is DbImportExportError) {
      _showErrorSnackbar(context, state.message);
      context.read<DbImportExportCubit>().reset();
    }
  }

  // ─── Import Mode Dialog ──────────────────────────────────────────────────────

  void _showImportModeDialog(BuildContext context, String filePath, String fileType) {
    final cubit = context.read<DbImportExportCubit>();
    bool shouldBackup = true; // By default checked

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.download_rounded, color: Color(0xFF1E40AF), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Choose Import Mode',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Checkbox for Auto-Backup
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: CheckboxListTile(
                      value: shouldBackup,
                      onChanged: (val) {
                        setState(() {
                          shouldBackup = val ?? true;
                        });
                      },
                      title: const Text(
                        'Take a backup before importing',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Recommended to prevent accidental data loss.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      dense: true,
                      activeColor: const Color(0xFF1E40AF),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Full Replace
                  _buildModeOption(
                    icon: Icons.autorenew_rounded,
                    iconColor: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                    title: 'Full Replace',
                    description: 'Backup ka data aayega, existing data pura delete ho jaayega.\n'
                        'App ka current data GAYA samjho.',
                    cautionText: '⚠️  Existing data permanently delete hoga',
                    cautionColor: const Color(0xFFDC2626),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      if (fileType == 'db') {
                        cubit.importDatabase(filePath, backupFirst: shouldBackup);
                      } else {
                        cubit.importFromJson(filePath, backupFirst: shouldBackup);
                      }
                    },
                    buttonText: 'Full Replace',
                    buttonColor: const Color(0xFFDC2626),
                  ),

                  const SizedBox(height: 12),

                  // Option 2: Merge
                  _buildModeOption(
                    icon: Icons.merge_rounded,
                    iconColor: const Color(0xFF059669),
                    bgColor: const Color(0xFFECFDF5),
                    title: 'Merge',
                    description: 'Backup ka naya data add ho jaayega, existing data safe rahega.\n'
                        'Duplicate records automatically skip ho jaayenge.',
                    cautionText: '⏱️  Large backups mein time lag sakta hai',
                    cautionColor: const Color(0xFF92400E),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      if (fileType == 'db') {
                        cubit.mergeDatabase(filePath, backupFirst: shouldBackup);
                      } else {
                        cubit.mergeFromJson(filePath, backupFirst: shouldBackup);
                      }
                    },
                    buttonText: 'Merge',
                    buttonColor: const Color(0xFF059669),
                  ),

                  const SizedBox(height: 16),

                  // Cancel
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        cubit.reset();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String cautionText,
    required Color cautionColor,
    required VoidCallback onTap,
    required String buttonText,
    required Color buttonColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: buttonColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cautionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cautionText,
              style: TextStyle(fontSize: 11, color: cautionColor, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Info Banner ─────────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup & Restore',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Export your database to keep a safe backup. Import it anytime to restore all products, bills, and data.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Export Cards ────────────────────────────────────────────────────────────

  Widget _buildExportCards(BuildContext context, DbImportExportState state) {
    final isLoading = state is DbImportExportLoading;
    return Column(
      children: [
        _buildExportActionCard(
          icon: Icons.storage_rounded,
          iconColor: const Color(0xFF1E40AF),
          bgColor: const Color(0xFFEFF6FF),
          title: 'Backup as .db File',
          description:
              'Full SQLite backup — perfect for complete restore. Recommended for backups.',
          badgeText: 'RECOMMENDED',
          badgeColor: const Color(0xFF1E40AF),
          primaryColor: const Color(0xFF1E40AF),
          isLoading: isLoading,
          onDownloadPressed: () => context.read<DbImportExportCubit>().downloadDatabaseToDevice(),
          onSharePressed: () => context.read<DbImportExportCubit>().exportDatabase(),
        ),
        const SizedBox(height: 12),
        _buildExportActionCard(
          icon: Icons.data_object_rounded,
          iconColor: const Color(0xFF0EA5E9),
          bgColor: const Color(0xFFE0F2FE),
          title: 'Backup as JSON',
          description: 'Human-readable format. Useful for viewing data or sharing.',
          badgeText: 'JSON',
          badgeColor: const Color(0xFF0EA5E9),
          primaryColor: const Color(0xFF0EA5E9),
          isLoading: isLoading,
          onDownloadPressed: () => context.read<DbImportExportCubit>().downloadAsJsonToDevice(),
          onSharePressed: () => context.read<DbImportExportCubit>().exportAsJson(),
        ),
        const SizedBox(height: 12),
        _buildExportActionCard(
          icon: Icons.date_range_rounded,
          iconColor: const Color(0xFFD97706),
          bgColor: const Color(0xFFFEF3C7),
          title: 'Timeline Backup (.db)',
          description: 'Select start and end dates to backup data for a specific period.',
          badgeText: 'DATE WISE',
          badgeColor: const Color(0xFFD97706),
          primaryColor: const Color(0xFFD97706),
          isLoading: isLoading,
          onDownloadPressed: () => _pickDateRangeAndExport(context, isJson: false, isDownload: true),
          onSharePressed: () => _pickDateRangeAndExport(context, isJson: false, isDownload: false),
        ),
        const SizedBox(height: 12),
        _buildExportActionCard(
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          title: 'Timeline Backup (JSON)',
          description: 'Select start and end dates to backup JSON data for a specific period.',
          badgeText: 'DATE WISE',
          badgeColor: const Color(0xFF059669),
          primaryColor: const Color(0xFF059669),
          isLoading: isLoading,
          onDownloadPressed: () => _pickDateRangeAndExport(context, isJson: true, isDownload: true),
          onSharePressed: () => _pickDateRangeAndExport(context, isJson: true, isDownload: false),
        ),
      ],
    );
  }

  Future<void> _pickDateRangeAndExport(BuildContext context, {required bool isJson, required bool isDownload}) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E40AF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final cubit = context.read<DbImportExportCubit>();
      if (isJson) {
        if (isDownload) {
          cubit.downloadAsJsonByDateToDevice(picked.start, picked.end);
        } else {
          cubit.exportAsJsonByDate(picked.start, picked.end);
        }
      } else {
        if (isDownload) {
          cubit.downloadDatabaseByDateToDevice(picked.start, picked.end);
        } else {
          cubit.exportDatabaseByDate(picked.start, picked.end);
        }
      }
    }
  }

  Widget _buildExportActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required Color primaryColor,
    required bool isLoading,
    required VoidCallback onDownloadPressed,
    required VoidCallback onSharePressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : onSharePressed,
                  icon: Icon(Icons.share_rounded, size: 18, color: primaryColor),
                  label: Text('Share', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: primaryColor.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : onDownloadPressed,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Import Cards ────────────────────────────────────────────────────────────


  Widget _buildImportCards(BuildContext context, DbImportExportState state) {
    final isLoading = state is DbImportExportLoading;
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.storage_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          title: 'Import .db File',
          description: 'Restore from a .db backup. Choose between Full Replace or Merge.',
          badgeText: '.db',
          badgeColor: const Color(0xFF059669),
          buttonText: 'Select .db File',
          buttonColor: const Color(0xFF059669),
          isLoading: isLoading,
          onPressed: () => context.read<DbImportExportCubit>().pickDbFile(),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.data_object_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          title: 'Import JSON File',
          description: 'Restore from a .json backup. Choose between Full Replace or Merge.',
          badgeText: 'JSON',
          badgeColor: const Color(0xFF7C3AED),
          buttonText: 'Select JSON File',
          buttonColor: const Color(0xFF7C3AED),
          isLoading: isLoading,
          onPressed: () => context.read<DbImportExportCubit>().pickJsonFile(),
        ),
      ],
    );
  }

  // ─── Action Card ─────────────────────────────────────────────────────────────

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    required String badgeText,
    required Color badgeColor,
    required String buttonText,
    required Color buttonColor,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Saved Backups List ──────────────────────────────────────────────────────

  Widget _buildSavedBackupsList(BuildContext context) {
    final cubit = context.read<DbImportExportCubit>();
    final backups = cubit.savedBackups;

    if (backups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.history_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No saved backups found',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: backups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final file = backups[index];
        final fileName = file.path.split('/').last;
        final isDb = fileName.endsWith('.db');
        final size = (file.lengthSync() / 1024).toStringAsFixed(1); // KB
        final date = file.lastModifiedSync();
        final dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDb ? const Color(0xFFECFDF5) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isDb ? Icons.storage_rounded : Icons.data_object_rounded,
                  color: isDb ? const Color(0xFF059669) : const Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • $size KB',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Color(0xFF1E40AF)),
                tooltip: 'Import this backup',
                onPressed: () => cubit.selectBackupFromList(file.path),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                tooltip: 'Delete',
                onPressed: () => _confirmDeleteBackup(context, file.path),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteBackup(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Backup?'),
        content: const Text('Are you sure you want to delete this backup file? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DbImportExportCubit>().deleteBackup(filePath);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Warning Card ────────────────────────────────────────────────────────────

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Import se pehle current data ka backup zaroor lein.\n'
              'Full Replace mode mein existing data permanently delete ho jaata hai.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Loading Overlay ─────────────────────────────────────────────────────────

  Widget _buildLoadingOverlay(String message) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF1E40AF)),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Snackbars & Dialogs ─────────────────────────────────────────────────────

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showImportSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Import Successful!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Data restore ho gaya. Please restart the app for all changes to take effect.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<DbImportExportCubit>().reset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }
}
