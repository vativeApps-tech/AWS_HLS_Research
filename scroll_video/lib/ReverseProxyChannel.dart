import 'package:flutter/services.dart';

class ReverseProxyChannel {
  static const platform = MethodChannel('com.example/reverse_proxy');

  Future<String?> getProxyUrl(String videoUrl) async {
    try {
      final String? proxyUrl = await platform.invokeMethod('getProxyUrl', {'url': videoUrl});
      return proxyUrl;
    } on PlatformException catch (e) {
      print("Failed to get proxy URL: ${e.message}");
      return null;
    }
  }

}
