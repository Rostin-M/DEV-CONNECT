class ImageConstants {
  
  ImageConstants._();

  static String getDefaultAvatar(String? userName, {int size = 150}) {
    final name = Uri.encodeComponent(userName ?? 'User');
    return 'https://ui-avatars.com/api/?name=$name&background=random&size=$size&bold=true';
  }

  static const String defaultProjectImage =
      'https://ui-avatars.com/api/?name=No+Image&background=e0e0e0&color=666&size=600';

  static const String appLogo = 'assets/icon/app_icon.png';

  static const String imagePlaceholder = 'assets/images/placeholder.png';
}
