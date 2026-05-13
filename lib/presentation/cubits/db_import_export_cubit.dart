import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/i_db_import_export_service.dart';
import 'db_import_export_state.dart';

class DbImportExportCubit extends Cubit<DbImportExportState> {
  final IDbImportExportService _importExportService;
  
  List<File> savedBackups = [];

  DbImportExportCubit(this._importExportService) : super(DbImportExportInitial()) {
    loadSavedBackups();
  }

  // ─── Private Backups Management ─────────────────────────────────────────────

  Future<void> loadSavedBackups() async {
    try {
      savedBackups = await _importExportService.getSavedBackups();
      // Re-emit current state to trigger rebuild with new list
      if (state is DbImportExportInitial) {
        emit(DbImportExportInitial());
      }
    } catch (_) {}
  }

  Future<void> deleteBackup(String filePath) async {
    try {
      await _importExportService.deleteBackup(filePath);
      await loadSavedBackups();
    } catch (_) {}
  }

  void selectBackupFromList(String filePath) {
    final fileType = filePath.endsWith('.db') ? 'db' : 'json';
    emit(DbFileSelected(filePath: filePath, fileType: fileType));
  }

  // ─── Export (Share) ────────────────────────────────────────────────────────

  /// Export raw SQLite .db file and open system share sheet
  Future<void> exportDatabase() async {
    emit(const DbImportExportLoading(message: 'Preparing database...'));
    try {
      final filePath = await _importExportService.exportDatabase();
      await Share.shareXFiles([XFile(filePath)], subject: 'QR Billing DB Backup');
      emit(DbExportSuccess(filePath: filePath, format: 'db'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Export failed: $e'));
    }
  }

  /// Export all data as JSON and open system share sheet
  Future<void> exportAsJson() async {
    emit(const DbImportExportLoading(message: 'Preparing JSON...'));
    try {
      final filePath = await _importExportService.exportAsJson();
      await Share.shareXFiles([XFile(filePath)], subject: 'QR Billing JSON Backup');
      emit(DbExportSuccess(filePath: filePath, format: 'json'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Export failed: $e'));
    }
  }

  /// Export raw SQLite .db file for specific dates
  Future<void> exportDatabaseByDate(DateTime start, DateTime end) async {
    emit(const DbImportExportLoading(message: 'Preparing database...'));
    try {
      final filePath = await _importExportService.exportDatabaseByDateRange(start, end);
      await Share.shareXFiles([XFile(filePath)], subject: 'QR Billing DB Backup (Date Range)');
      emit(DbExportSuccess(filePath: filePath, format: 'db'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Export failed: $e'));
    }
  }

  /// Export JSON file for specific dates
  Future<void> exportAsJsonByDate(DateTime start, DateTime end) async {
    emit(const DbImportExportLoading(message: 'Preparing JSON...'));
    try {
      final filePath = await _importExportService.exportAsJsonByDateRange(start, end);
      await Share.shareXFiles([XFile(filePath)], subject: 'QR Billing JSON Backup (Date Range)');
      emit(DbExportSuccess(filePath: filePath, format: 'json'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Export failed: $e'));
    }
  }

  // ─── Download (Save to Device) ─────────────────────────────────────────────

  /// Save .db file directly to public Downloads folder
  Future<void> downloadDatabaseToDevice() async {
    emit(const DbImportExportLoading(message: 'Saving to Downloads...'));
    try {
      final sourcePath = await _importExportService.exportDatabase();
      final downloadPath = await _moveToDownloads(sourcePath);
      emit(DbDownloadSuccess(filePath: downloadPath, format: 'db'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Download failed: $e'));
    }
  }

  /// Save JSON file directly to public Downloads folder
  Future<void> downloadAsJsonToDevice() async {
    emit(const DbImportExportLoading(message: 'Saving to Downloads...'));
    try {
      final sourcePath = await _importExportService.exportAsJson();
      final downloadPath = await _moveToDownloads(sourcePath);
      emit(DbDownloadSuccess(filePath: downloadPath, format: 'json'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Download failed: $e'));
    }
  }

  /// Save .db file directly to public Downloads folder for specific dates
  Future<void> downloadDatabaseByDateToDevice(DateTime start, DateTime end) async {
    emit(const DbImportExportLoading(message: 'Saving to Downloads...'));
    try {
      final sourcePath = await _importExportService.exportDatabaseByDateRange(start, end);
      final downloadPath = await _moveToDownloads(sourcePath);
      emit(DbDownloadSuccess(filePath: downloadPath, format: 'db'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Download failed: $e'));
    }
  }

  /// Save JSON file directly to public Downloads folder for specific dates
  Future<void> downloadAsJsonByDateToDevice(DateTime start, DateTime end) async {
    emit(const DbImportExportLoading(message: 'Saving to Downloads...'));
    try {
      final sourcePath = await _importExportService.exportAsJsonByDateRange(start, end);
      final downloadPath = await _moveToDownloads(sourcePath);
      emit(DbDownloadSuccess(filePath: downloadPath, format: 'json'));
      await loadSavedBackups();
    } catch (e) {
      emit(DbImportExportError(message: 'Download failed: $e'));
    }
  }

  /// Download an existing local backup file to public Downloads folder
  Future<void> downloadLocalBackupToDevice(String filePath) async {
    emit(const DbImportExportLoading(message: 'Saving to Downloads...'));
    try {
      final format = filePath.endsWith('.db') ? 'db' : 'json';
      final downloadPath = await _moveToDownloads(filePath);
      emit(DbDownloadSuccess(filePath: downloadPath, format: format));
    } catch (e) {
      emit(DbImportExportError(message: 'Download failed: $e'));
    }
  }

  Future<String> _moveToDownloads(String sourcePath) async {
    if (Platform.isAndroid) {
      // Request storage permission just in case (mostly needed for Android 10 and below)
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        // Just return original path if permission denied, but still try to save if possible
      }

      final sourceFile = File(sourcePath);
      String fileName = sourcePath.split('/').last;
      
      // Append unique timestamp to prevent "File Already Exists" or "Permission Denied" on overwrite
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7); // Use last 6 digits for brevity
      final nameParts = fileName.split('.');
      if (nameParts.length > 1) {
        final ext = nameParts.removeLast();
        fileName = "${nameParts.join('.')}_$timestamp.$ext";
      } else {
        fileName = "${fileName}_$timestamp";
      }
      
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final targetPath = '${downloadDir.path}/$fileName';
          await sourceFile.copy(targetPath);
          return targetPath; 
        }
      } catch (e) {
        // Fallback
      }
    }
    return sourcePath;
  }

  // ─── Import — File Selection ─────────────────────────────────────────────────

  /// Pick a .db file → emit DbFileSelected so screen can show mode dialog
  Future<void> pickDbFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        emit(const DbImportExportError(message: 'Could not access the selected file'));
        return;
      }

      if (!filePath.endsWith('.db')) {
        emit(const DbImportExportError(message: 'Please select a valid .db backup file'));
        return;
      }

      emit(DbFileSelected(filePath: filePath, fileType: 'db'));
    } catch (e) {
      emit(DbImportExportError(message: 'File selection failed: $e'));
    }
  }

  /// Pick a .json file → emit DbFileSelected so screen can show mode dialog
  Future<void> pickJsonFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) {
        emit(const DbImportExportError(message: 'Could not access the selected file'));
        return;
      }

      if (!filePath.endsWith('.json')) {
        emit(const DbImportExportError(message: 'Please select a valid .json backup file'));
        return;
      }

      emit(DbFileSelected(filePath: filePath, fileType: 'json'));
    } catch (e) {
      emit(DbImportExportError(message: 'File selection failed: $e'));
    }
  }

  // ─── Import — Execution ──────────────────────────────────────────────────────

  Future<void> _handleAutoBackup(bool saveToDownloads) async {
    emit(const DbImportExportLoading(message: 'Creating auto-backup...'));
    // ALWAYS create a timestamped backup in App's Private Storage
    final autoBackupPath = await _importExportService.createAutoBackup();
    
    // If checkbox was checked, ALSO copy it to the public Downloads folder
    if (saveToDownloads) {
      await _moveToDownloads(autoBackupPath);
    }
  }

  /// Full Replace from .db file
  Future<void> importDatabase(String filePath, {bool backupFirst = true}) async {
    try {
      await _handleAutoBackup(backupFirst);
      
      emit(const DbImportExportLoading(message: 'Restoring database...'));
      await _importExportService.importDatabase(filePath);
      emit(const DbImportSuccess());
    } catch (e) {
      emit(DbImportExportError(message: 'Import failed: $e'));
    }
  }

  /// Full Replace from JSON file
  Future<void> importFromJson(String filePath, {bool backupFirst = true}) async {
    try {
      await _handleAutoBackup(backupFirst);

      emit(const DbImportExportLoading(message: 'Restoring from JSON...'));
      await _importExportService.importFromJson(filePath);
      emit(const DbImportSuccess());
    } catch (e) {
      emit(DbImportExportError(message: 'Import failed: $e'));
    }
  }

  /// Merge from .db file (keeps existing data, adds new records)
  Future<void> mergeDatabase(String filePath, {bool backupFirst = true}) async {
    try {
      await _handleAutoBackup(backupFirst);

      emit(const DbImportExportLoading(message: 'Merging database...'));
      await _importExportService.mergeDatabase(filePath);
      emit(const DbImportSuccess());
    } catch (e) {
      emit(DbImportExportError(message: 'Merge failed: $e'));
    }
  }

  /// Merge from JSON file (keeps existing data, adds new records)
  Future<void> mergeFromJson(String filePath, {bool backupFirst = true}) async {
    try {
      await _handleAutoBackup(backupFirst);

      emit(const DbImportExportLoading(message: 'Merging from JSON...'));
      await _importExportService.mergeFromJson(filePath);
      emit(const DbImportSuccess());
    } catch (e) {
      emit(DbImportExportError(message: 'Merge failed: $e'));
    }
  }

  /// Reset back to initial state
  void reset() {
    emit(DbImportExportInitial());
    loadSavedBackups();
  }
}
