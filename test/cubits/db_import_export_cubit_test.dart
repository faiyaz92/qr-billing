import 'dart:io';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_based_billing/presentation/cubits/db_import_export_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/db_import_export_state.dart';
import 'package:qr_based_billing/core/services/i_db_import_export_service.dart';

class MockDbImportExportService extends Mock implements IDbImportExportService {}

void main() {
  late DbImportExportCubit cubit;
  late MockDbImportExportService mockService;

  setUp(() {
    mockService = MockDbImportExportService();
    when(() => mockService.getSavedBackups()).thenAnswer((_) async => []);
    cubit = DbImportExportCubit(mockService);
  });

  tearDown(() {
    cubit.close();
  });

  group('DbImportExportCubit', () {
    blocTest<DbImportExportCubit, DbImportExportState>(
      'exportDatabase success emits Loading and then ExportSuccess',
      build: () {
        when(() => mockService.exportDatabase()).thenAnswer((_) async => 'path/to/db');
        return cubit;
      },
      act: (cubit) => cubit.exportDatabase(),
      expect: () => [
        isA<DbImportExportLoading>(),
        isA<DbExportSuccess>().having((s) => s.filePath, 'path', 'path/to/db').having((s) => s.format, 'format', 'db'),
      ],
    );

    blocTest<DbImportExportCubit, DbImportExportState>(
      'importDatabase success emits Loading and then ImportSuccess',
      build: () {
        when(() => mockService.createAutoBackup()).thenAnswer((_) async => 'backup/path');
        when(() => mockService.importDatabase(any())).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.importDatabase('path/to/import'),
      expect: () => [
        isA<DbImportExportLoading>(),
        isA<DbImportSuccess>(),
      ],
    );

    blocTest<DbImportExportCubit, DbImportExportState>(
      'selectBackupFromList emits DbFileSelected',
      build: () => cubit,
      act: (cubit) => cubit.selectBackupFromList('backup.db'),
      expect: () => [
        isA<DbFileSelected>().having((s) => s.filePath, 'path', 'backup.db').having((s) => s.fileType, 'type', 'db'),
      ],
    );

    blocTest<DbImportExportCubit, DbImportExportState>(
      'deleteBackup calls service and reloads',
      build: () {
        when(() => mockService.deleteBackup(any())).thenAnswer((_) async {});
        return cubit;
      },
      act: (cubit) => cubit.deleteBackup('file.db'),
      verify: (_) {
        verify(() => mockService.deleteBackup('file.db')).called(1);
        verify(() => mockService.getSavedBackups()).called(greaterThan(0));
      },
    );
  });
}
