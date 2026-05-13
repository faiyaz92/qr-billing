import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_based_billing/presentation/cubits/home_cubit.dart';
import 'package:qr_based_billing/presentation/cubits/home_state.dart';

void main() {
  late HomeCubit cubit;

  setUp(() {
    cubit = HomeCubit();
  });

  tearDown(() {
    cubit.close();
  });

  group('HomeCubit', () {
    test('initial state index is 0', () {
      expect(cubit.state.index, 0);
    });

    blocTest<HomeCubit, HomeState>(
      'setTab updates index correctly',
      build: () => cubit,
      act: (cubit) => cubit.setTab(2),
      expect: () => [
        isA<HomeState>().having((s) => s.index, 'index', 2),
      ],
    );
  });
}
