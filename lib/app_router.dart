import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/add_product_screen.dart';
import 'presentation/screens/product_list_screen.dart';
import 'presentation/screens/billing_screen.dart';
import 'presentation/screens/bill_detail_screen.dart';
import 'presentation/screens/daily_sales_screen.dart';
import 'presentation/screens/product_details_screen.dart';
import 'presentation/screens/admin_product_details_screen.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/thermal_printer_screen.dart';
import 'data/models/scanned_data.dart';
import 'data/models/product.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: AddProductRoute.page),
    AutoRoute(page: ProductListRoute.page),
    AutoRoute(page: BillingRoute.page),
    AutoRoute(page: BillDetailRoute.page),
    AutoRoute(page: DailySalesRoute.page),
    AutoRoute(page: ProductDetailsRoute.page),
    AutoRoute(page: AdminProductDetailsRoute.page),
    AutoRoute(page: AnalyticsRoute.page),
    AutoRoute(page: SettingsRoute.page),
    AutoRoute(page: ThermalPrinterRoute.page),
  ];
}