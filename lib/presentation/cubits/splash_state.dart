abstract class SplashState {}

class SplashInitial extends SplashState {}

class SplashCompleted extends SplashState {}

class SplashUpdateRequired extends SplashState {
  final String storeUrl;
  final String currentVersion;
  final String storeVersion;

  SplashUpdateRequired({
    required this.storeUrl,
    required this.currentVersion,
    required this.storeVersion,
  });
}