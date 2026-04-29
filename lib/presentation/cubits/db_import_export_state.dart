import 'package:equatable/equatable.dart';

abstract class DbImportExportState extends Equatable {
  const DbImportExportState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state
class DbImportExportInitial extends DbImportExportState {
  final int timestamp;
  DbImportExportInitial({int? timestamp}) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [timestamp];
}

/// Loading — export or import in progress
class DbImportExportLoading extends DbImportExportState {
  final String message;
  const DbImportExportLoading({this.message = 'Processing...'});

  @override
  List<Object?> get props => [message];
}

/// File picked — screen should now show Full Replace vs Merge dialog
class DbFileSelected extends DbImportExportState {
  final String filePath;
  final String fileType; // 'db' or 'json'
  const DbFileSelected({required this.filePath, required this.fileType});

  @override
  List<Object?> get props => [filePath, fileType];
}

/// Export completed successfully (Shared)
class DbExportSuccess extends DbImportExportState {
  final String filePath;
  final String format; // 'db' or 'json'
  const DbExportSuccess({required this.filePath, required this.format});

  @override
  List<Object?> get props => [filePath, format];
}

/// Download completed successfully (Saved to device)
class DbDownloadSuccess extends DbImportExportState {
  final String filePath;
  final String format; // 'db' or 'json'
  const DbDownloadSuccess({required this.filePath, required this.format});

  @override
  List<Object?> get props => [filePath, format];
}

/// Import completed successfully
class DbImportSuccess extends DbImportExportState {
  const DbImportSuccess();
}

/// Error state
class DbImportExportError extends DbImportExportState {
  final String message;
  const DbImportExportError({required this.message});

  @override
  List<Object?> get props => [message];
}
