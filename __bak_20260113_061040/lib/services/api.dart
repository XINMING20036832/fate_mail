import 'package:http/http.dart' as http;

/// 这里是你未来对接腾讯云后端的位置。
/// 现在 starter 默认不调用网络，仅保留结构。
class ApiService {
  // TODO: 改成你的后端 https://your-domain.com
  static String baseUrl = 'https://example.com';

  static Future<void> ping() async {
    // Example
    // await http.get(Uri.parse('$baseUrl/ping'));
  }

  static Future<void> buyStamps({required int count}) async {
    // TODO: 走 Google Play Billing 后，服务器校验成功再加邮票
  }

  static Future<void> createRequest() async {}
  static Future<void> acceptRequest() async {}
  static Future<void> rejectRequest() async {}
  static Future<void> sendMail() async {}
  static Future<void> report() async {}
  static Future<void> blockUser() async {}
}
