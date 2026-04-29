import 'dart:io';

/// Abstract interface for Database Import/Export operations
abstract class IDbImportExportService {
  /// Export entire database as a raw SQLite .db file
  Future<String> exportDatabase();

  /// Export all data as JSON format
  Future<String> exportAsJson();

  /// Export entire database as a raw SQLite .db file within a specific date range
  Future<String> exportDatabaseByDateRange(DateTime start, DateTime end);

  /// Export all data as JSON format within a specific date range
  Future<String> exportAsJsonByDateRange(DateTime start, DateTime end);

  /// Create a timestamped auto-backup before import (prevents data loss)
  Future<String> createAutoBackup();

  /// Full Replace: replaces entire DB with the .db backup file
  Future<void> importDatabase(String filePath);

  /// Full Replace: replaces entire DB from JSON backup
  Future<void> importFromJson(String filePath);

  /// Merge: adds new records from .db backup, skips duplicates
  Future<void> mergeDatabase(String filePath);

  /// Merge: adds new records from JSON backup, skips duplicates
  Future<void> mergeFromJson(String filePath);

  /// Get list of backup files from app private storage
  Future<List<File>> getSavedBackups();
  
  /// Delete a specific backup file
  Future<void> deleteBackup(String filePath);
}
