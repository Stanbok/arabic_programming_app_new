abstract class AppAssets {
  // Base paths
  static const String _images = 'assets/images';
  static const String _animations = 'assets/animations';
  static const String _icons = 'assets/icons';
  
  // Images
  static const String logo = '$_images/logo.png';
  static const String pythonMascot = '$_images/python_mascot.png';
  static const String noInternet = '$_images/no_internet.png';
  
  // Animations (Lottie)
  static const String splashAnimation = '$_animations/splash.json';
  static const String successAnimation = '$_animations/success.json';
  static const String failAnimation = '$_animations/fail.json';
  static const String loadingAnimation = '$_animations/loading.json';
  static const String celebrationAnimation = '$_animations/celebration.json';
  static const String starAnimation = '$_animations/star.json';
  
  // Avatars
  static List<String> get avatars => List.generate(
    12,
    (index) => '$_images/avatars/avatar_${index + 1}.png',
  );
  
  // Icons
  static const String pythonIcon = '$_icons/python.svg';
  static const String crownIcon = '$_icons/crown.svg';
  static const String fireIcon = '$_icons/fire.svg';
}
