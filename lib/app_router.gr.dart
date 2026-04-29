// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AddProductScreen]
class AddProductRoute extends PageRouteInfo<AddProductRouteArgs> {
  AddProductRoute({Key? key, Product? product, List<PageRouteInfo>? children})
    : super(
        AddProductRoute.name,
        args: AddProductRouteArgs(key: key, product: product),
        initialChildren: children,
      );

  static const String name = 'AddProductRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AddProductRouteArgs>(
        orElse: () => const AddProductRouteArgs(),
      );
      return AddProductScreen(key: args.key, product: args.product);
    },
  );
}

class AddProductRouteArgs {
  const AddProductRouteArgs({this.key, this.product});

  final Key? key;

  final Product? product;

  @override
  String toString() {
    return 'AddProductRouteArgs{key: $key, product: $product}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AddProductRouteArgs) return false;
    return key == other.key && product == other.product;
  }

  @override
  int get hashCode => key.hashCode ^ product.hashCode;
}

/// generated route for
/// [AdminProductDetailsScreen]
class AdminProductDetailsRoute
    extends PageRouteInfo<AdminProductDetailsRouteArgs> {
  AdminProductDetailsRoute({
    Key? key,
    required Product product,
    List<PageRouteInfo>? children,
  }) : super(
         AdminProductDetailsRoute.name,
         args: AdminProductDetailsRouteArgs(key: key, product: product),
         initialChildren: children,
       );

  static const String name = 'AdminProductDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AdminProductDetailsRouteArgs>();
      return AdminProductDetailsScreen(key: args.key, product: args.product);
    },
  );
}

class AdminProductDetailsRouteArgs {
  const AdminProductDetailsRouteArgs({this.key, required this.product});

  final Key? key;

  final Product product;

  @override
  String toString() {
    return 'AdminProductDetailsRouteArgs{key: $key, product: $product}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AdminProductDetailsRouteArgs) return false;
    return key == other.key && product == other.product;
  }

  @override
  int get hashCode => key.hashCode ^ product.hashCode;
}

/// generated route for
/// [AnalyticsScreen]
class AnalyticsRoute extends PageRouteInfo<void> {
  const AnalyticsRoute({List<PageRouteInfo>? children})
    : super(AnalyticsRoute.name, initialChildren: children);

  static const String name = 'AnalyticsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AnalyticsScreen();
    },
  );
}

/// generated route for
/// [BillDetailScreen]
class BillDetailRoute extends PageRouteInfo<void> {
  const BillDetailRoute({List<PageRouteInfo>? children})
    : super(BillDetailRoute.name, initialChildren: children);

  static const String name = 'BillDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BillDetailScreen();
    },
  );
}

/// generated route for
/// [BillingScreen]
class BillingRoute extends PageRouteInfo<BillingRouteArgs> {
  BillingRoute({Key? key, List<PageRouteInfo>? children})
    : super(
        BillingRoute.name,
        args: BillingRouteArgs(key: key),
        initialChildren: children,
      );

  static const String name = 'BillingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<BillingRouteArgs>(
        orElse: () => const BillingRouteArgs(),
      );
      return BillingScreen(key: args.key);
    },
  );
}

class BillingRouteArgs {
  const BillingRouteArgs({this.key});

  final Key? key;

  @override
  String toString() {
    return 'BillingRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BillingRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [DailySalesScreen]
class DailySalesRoute extends PageRouteInfo<void> {
  const DailySalesRoute({List<PageRouteInfo>? children})
    : super(DailySalesRoute.name, initialChildren: children);

  static const String name = 'DailySalesRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DailySalesScreen();
    },
  );
}

/// generated route for
/// [DbImportExportScreen]
class DbImportExportRoute extends PageRouteInfo<void> {
  const DbImportExportRoute({List<PageRouteInfo>? children})
    : super(DbImportExportRoute.name, initialChildren: children);

  static const String name = 'DbImportExportRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DbImportExportScreen();
    },
  );
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [ProductDetailsScreen]
class ProductDetailsRoute extends PageRouteInfo<ProductDetailsRouteArgs> {
  ProductDetailsRoute({
    Key? key,
    required ScannedData scannedData,
    List<PageRouteInfo>? children,
  }) : super(
         ProductDetailsRoute.name,
         args: ProductDetailsRouteArgs(key: key, scannedData: scannedData),
         initialChildren: children,
       );

  static const String name = 'ProductDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProductDetailsRouteArgs>();
      return ProductDetailsScreen(key: args.key, scannedData: args.scannedData);
    },
  );
}

class ProductDetailsRouteArgs {
  const ProductDetailsRouteArgs({this.key, required this.scannedData});

  final Key? key;

  final ScannedData scannedData;

  @override
  String toString() {
    return 'ProductDetailsRouteArgs{key: $key, scannedData: $scannedData}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProductDetailsRouteArgs) return false;
    return key == other.key && scannedData == other.scannedData;
  }

  @override
  int get hashCode => key.hashCode ^ scannedData.hashCode;
}

/// generated route for
/// [ProductListScreen]
class ProductListRoute extends PageRouteInfo<void> {
  const ProductListRoute({List<PageRouteInfo>? children})
    : super(ProductListRoute.name, initialChildren: children);

  static const String name = 'ProductListRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ProductListScreen();
    },
  );
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SettingsScreen();
    },
  );
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
    : super(SplashRoute.name, initialChildren: children);

  static const String name = 'SplashRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const SplashScreen();
    },
  );
}

/// generated route for
/// [ThermalPrinterScreen]
class ThermalPrinterRoute extends PageRouteInfo<void> {
  const ThermalPrinterRoute({List<PageRouteInfo>? children})
    : super(ThermalPrinterRoute.name, initialChildren: children);

  static const String name = 'ThermalPrinterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ThermalPrinterScreen();
    },
  );
}
