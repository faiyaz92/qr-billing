import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_based_billing/presentation/cubits/splash_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/splash_state.dart';

void main() {
  late SplashCubit cubit;

  setUp(() {
    cubit = SplashCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('SplashCubit', () {
    blocTest<SplashCubit, SplashState>(
      'completeSplash emits SplashCompleted after delay',
      build: () => cubit,
      act: (cubit) => cubit.completeSplash(),
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<SplashCompleted>(),
      ],
    );
  });
}
