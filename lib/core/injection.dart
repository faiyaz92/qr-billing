import 'package:get_it/get_it.dart';
import 'services/i_encryption_service.dart';
import 'services/encryption_service.dart';
import 'services/i_print_service.dart';
import 'services/print_service.dart';
import 'services/i_thermal_printer_service.dart';
import 'services/thermal_printer_service.dart';
import 'services/i_settings_service.dart';
import 'services/print_manager.dart';
import 'services/settings_service.dart';
import 'services/i_scan_service.dart';
import 'services/scan_service.dart';
import 'services/i_qr_generator_service.dart';
import 'services/qr_generator_service_impl.dart';
import '../domain/repositories/i_product_repository.dart';
import '../domain/repositories/i_bill_repository.dart';
import '../data/repositories/product_repository_impl.dart';
import '../data/repositories/bill_repository_impl.dart';
import '../data/database_helper.dart';
import '../presentation/cubits/settings_cubit.dart';
import '../presentation/cubits/analytics_cubit.dart';
import '../presentation/cubits/daily_sales_cubit.dart';
import '../presentation/cubits/add_product_cubit.dart';
import '../presentation/cubits/quick_scan_cubit.dart';
import '../presentation/cubits/product_list_cubit.dart';
import '../presentation/cubits/home_cubit.dart';
import '../presentation/cubits/splash_cubit.dart';
import '../presentation/cubits/billing_cubit.dart';
import '../core/services/i_db_import_export_service.dart';
import '../core/services/db_import_export_service.dart';
import '../presentation/cubits/db_import_export_cubit.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerSingleton<ISettingsService>(SettingsServiceImpl());
  getIt.registerSingleton<IEncryptionService>(EncryptionServiceImpl());
  getIt.registerSingleton<IPrintService>(PrintServiceImpl());
  getIt.registerLazySingleton<IThermalPrinterService>(() => ThermalPrinterServiceImpl());
  getIt.registerSingleton<PrintManager>(PrintManager(getIt<IPrintService>(), getIt<IThermalPrinterService>(), getIt<ISettingsService>()));
  getIt.registerSingleton<IScanService>(ScanServiceImpl(getIt<IEncryptionService>(), getIt<ISettingsService>()));
  getIt.registerSingleton<IQrGeneratorService>(QrGeneratorServiceImpl(getIt<IEncryptionService>(), getIt<ISettingsService>()));

  // Repositories
  getIt.registerSingleton<IProductRepository>(ProductRepositoryImpl());
  getIt.registerSingleton<IBillRepository>(BillRepositoryImpl());
  getIt.registerSingleton<IDbImportExportService>(
    DbImportExportServiceImpl(DatabaseHelper()),
  );

  // Cubits - अब सभी dependencies automatically inject हो जाएँगी
  getIt.registerFactory<SettingsCubit>(() => SettingsCubit(getIt<ISettingsService>()));
  getIt.registerFactory<AnalyticsCubit>(() => AnalyticsCubit(getIt<IBillRepository>(), getIt<IProductRepository>()));
  getIt.registerFactory<DailySalesCubit>(() => DailySalesCubit(getIt<IBillRepository>(), getIt<ISettingsService>()));
  getIt.registerFactory<AddProductCubit>(() => AddProductCubit(getIt<IProductRepository>(), getIt<IQrGeneratorService>(), getIt<IEncryptionService>()));
  getIt.registerFactory<QuickScanCubit>(() => QuickScanCubit(getIt<IScanService>()));
  getIt.registerFactory<ProductListCubit>(() => ProductListCubit(getIt<IProductRepository>(), getIt<PrintManager>()));
  getIt.registerFactory<HomeCubit>(() => HomeCubit());
  getIt.registerFactory<SplashCubit>(() => SplashCubit());
  getIt.registerFactory<DbImportExportCubit>(
    () => DbImportExportCubit(getIt<IDbImportExportService>()),
  );

  // ✅ BillingCubit भी getIt में register करें
  getIt.registerFactory<BillingCubit>(() => BillingCubit(
    scanService: getIt<IScanService>(),
    printManager: getIt<PrintManager>(),
    encryptionService: getIt<IEncryptionService>(),
    settingsService: getIt<ISettingsService>(),
    billRepository: getIt<IBillRepository>(),
  ));
}