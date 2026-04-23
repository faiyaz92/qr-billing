import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_based_billing/app_router.dart';
import 'core/injection.dart';
import 'presentation/cubits/settings_cubit.dart';
import 'presentation/cubits/billing_cubit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
        BlocProvider(create: (_) => getIt<BillingCubit>()), // ✅ अब getIt से मिलेगा
      ],
      child: MaterialApp.router(
        title: 'QR-Based Billing',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerDelegate: _appRouter.delegate(),
        routeInformationParser: _appRouter.defaultRouteParser(),
      ),
    );
  }
}
