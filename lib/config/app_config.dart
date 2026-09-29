import 'dart:io';

class AppConfig {
  static String get serverBaseUrl {
    if (Platform.isAndroid) {
      //return 'http://10.0.2.2:8080';
      return 'http://192.168.1.7:8080';
    }

    if (Platform.isIOS) {
      //return 'http://localhost:8080';
      return 'http://192.168.1.7:8080';
    }

    //return 'http://localhost:8080';
    return 'http://192.168.1.7:8080';
  }

  static String get apiBaseUrl => '$serverBaseUrl/api';

  static String getImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return '$serverBaseUrl$path';
  }
}
