// API 服务层 - 封装所有后端调用
// 使用 Dart 原生 HttpClient + 手动 Cookie 管理以支持 PHP Session
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static Cookie? _sessionCookie;

  // 创建 HttpClient（自签名证书 OK）
  static HttpClient _createClient() {
    final client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    client.connectionTimeout = const Duration(seconds: 15);
    return client;
  }

  // 初始化：从 SharedPreferences 恢复 Cookie
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('php_sessid');
    if (saved != null && saved.isNotEmpty) {
      _sessionCookie = Cookie('PHPSESSID', saved);
    }
  }

  // 保存 Cookie
  static Future<void> _saveCookie(String value) async {
    _sessionCookie = Cookie('PHPSESSID', value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('php_sessid', value);
  }

  static Future<void> _clearCookie() async {
    _sessionCookie = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('php_sessid');
  }

  // 通用 POST 调用
  static Future<Map<String, dynamic>> _post(String url, Map<String, String> body, {bool captureCookie = false}) async {
    try {
      final client = _createClient();
      final uri = Uri.parse(url);
      final request = await client.postUrl(uri);

      // 传递 Cookie
      if (_sessionCookie != null) {
        request.headers.set('Cookie', '${_sessionCookie!.name}=${_sessionCookie!.value}');
      }

      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.write(body.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'));

      final response = await request.close();

      // 捕获 Set-Cookie
      if (captureCookie) {
        final setCookie = response.headers.value('set-cookie');
        if (setCookie != null) {
          // Parse "PHPSESSID=xxx; path=/; ..."
          final parts = setCookie.split(';');
          for (final part in parts) {
            final trimmed = part.trim();
            if (trimmed.startsWith('PHPSESSID=')) {
              await _saveCookie(trimmed.substring(10));
              break;
            }
          }
        }
      }

      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        final cleanData = stringData.replaceAll('\uFEFF', '');
        if (cleanData.isNotEmpty) {
          return jsonDecode(cleanData);
        }
        return {'success': false, 'message': '空响应'};
      }
      return {'success': false, 'message': '网络错误: ${response.statusCode}'};
    } on SocketException catch (e) {
      return {'success': false, 'message': '无法连接服务器: $e'};
    } on HttpException catch (e) {
      return {'success': false, 'message': '请求异常: $e'};
    } catch (e) {
      return {'success': false, 'message': '请求失败: $e'};
    }
  }

  // ========== 1. 登录注册 ==========
  static Future<Map> login(String username, String password) async {
    final res = await _post(ApiConfig.appApi, {
      'action': 'app_login',
      'username': username,
      'password': password,
    }, captureCookie: true);
    if (res['success'] == true && res['data'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('logged_in', true);
      await prefs.setString('user_name', res['data']['name'] ?? '');
      await prefs.setString('user_role', res['data']['role'] ?? '');
      await prefs.setInt('user_id', (res['data']['id'] ?? 0) as int);
    }
    return res;
  }

  static Future<Map> register(String username, String password, String name, String phone) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_register',
      'username': username,
      'password': password,
      'name': name,
      'phone': phone,
    }, captureCookie: true);
  }

  static Future<void> logout() async {
    await _post(ApiConfig.appApi, {'action': 'app_logout'});
    await _clearCookie();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ========== 2. 统计数据 ==========
  static Future<Map> getStats() async {
    return await _post(ApiConfig.appApi, {'action': 'app_stats'});
  }

  // ========== 3. 订单/工单 ==========
  static Future<Map> getOrders({String? status, String? keyword, int page = 1}) async {
    final params = <String, String>{
      'action': 'app_orders',
      'page': page.toString(),
    };
    if (status != null) params['status'] = status;
    if (keyword != null) params['keyword'] = keyword;
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> createOrder(Map<String, dynamic> data) async {
    final params = <String, String>{'action': 'app_orders', 'sub_action': 'create'};
    data.forEach((k, v) { params[k] = v.toString(); });
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> updateOrder(int id, Map<String, dynamic> data) async {
    final params = <String, String>{'action': 'app_order_update', 'id': id.toString()};
    data.forEach((k, v) { params[k] = v.toString(); });
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> deleteOrder(int id) async {
    return await _post(ApiConfig.appApi, {'action': 'app_order_delete', 'id': id.toString()});
  }

  // ========== 4. 会员管理 ==========
  static Future<Map> getMembers({String? keyword, int page = 1}) async {
    final params = <String, String>{'action': 'app_members', 'page': page.toString()};
    if (keyword != null) params['keyword'] = keyword;
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> lookupMember(String plate) async {
    return await _post(ApiConfig.appApi, {'action': 'app_member_lookup', 'plate': plate});
  }

  static Future<Map> editMember(int id, Map<String, dynamic> data) async {
    final params = <String, String>{'action': 'app_member_edit', 'id': id.toString()};
    data.forEach((k, v) { params[k] = v.toString(); });
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> deleteMember(int id) async {
    return await _post(ApiConfig.appApi, {'action': 'app_member_delete', 'id': id.toString()});
  }

  static Future<Map> rechargeMember(int id, double amount, String note) async {
    return await _post(ApiConfig.appApi, {'action': 'app_member_recharge', 'id': id.toString(), 'amount': amount.toString(), 'note': note});
  }

  static Future<Map> deductMember(int id, double amount, String note) async {
    return await _post(ApiConfig.appApi, {'action': 'app_member_deduct', 'id': id.toString(), 'amount': amount.toString(), 'note': note});
  }

  static Future<Map> getMemberRecords(int id) async {
    return await _post(ApiConfig.appApi, {'action': 'app_member_records', 'id': id.toString()});
  }

  // ========== 5. 库存 ==========
  static Future<Map> getInventory({String? keyword, int page = 1}) async {
    final params = <String, String>{'action': 'app_inventory', 'page': page.toString()};
    if (keyword != null) params['keyword'] = keyword;
    return await _post(ApiConfig.appApi, params);
  }

  // ========== 6. 客户管理 ==========
  static Future<Map> getCustomers({String? keyword, int page = 1}) async {
    final params = <String, String>{'action': 'app_customers', 'page': page.toString()};
    if (keyword != null) params['keyword'] = keyword;
    return await _post(ApiConfig.appApi, params);
  }

  static Future<Map> getCustomerDetail(int id) async {
    return await _post(ApiConfig.appApi, {'action': 'app_customer_detail', 'id': id.toString()});
  }

  // ========== 7. 车辆详情 ==========
  static Future<Map> getVehicleDetail(String plate) async {
    return await _post(ApiConfig.appApi, {'action': 'app_vehicle_detail', 'plate': plate});
  }

  static Future<Map> updateVehicle(String plate, Map<String, dynamic> data) async {
    final params = <String, String>{'action': 'app_vehicle_update', 'plate': plate};
    data.forEach((k, v) { params[k] = v.toString(); });
    return await _post(ApiConfig.appApi, params);
  }
}
