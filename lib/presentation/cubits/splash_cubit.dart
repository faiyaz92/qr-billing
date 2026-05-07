import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  SplashCubit() : super(SplashInitial());

  Future<void> completeSplash() async {
    try {
      // Small delay to show splash animation
      await Future.delayed(const Duration(seconds: 2));

      final newVersion = NewVersionPlus();
      final status = await newVersion.getVersionStatus();

      if (status != null && status.canUpdate) {
        emit(SplashUpdateRequired(
          storeUrl: status.appStoreLink,
          currentVersion: status.localVersion,
          storeVersion: status.storeVersion,
        ));
      } else {
        emit(SplashCompleted());
      }
    } catch (e) {
      // If version check fails (e.g. no internet), proceed to app
      // or handle as per requirement. For now, proceeding.
      emit(SplashCompleted());
    }
  }
}