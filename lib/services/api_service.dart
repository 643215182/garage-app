// API 服务层 - 封装所有后端调用
// 使用 Dart 原生 HttpClient 以支持自签名证书
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String? _sessionId;

  // 初始化：从 SharedPreferences 恢复 session
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionId = prefs.getString('session_id');
  }

  // 保存 session
  static Future<void> _saveSession(String? id) async {
    _sessionId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString('session_id', id);
      await prefs.setString('user_id', id);
    } else {
      await prefs.remove('session_id');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_role');
    }
  }

  // 创建接受自签名证书的 HttpClient
  static HttpClient _createClient() {
    final client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true
      ..connectionTimeout = const Duration(seconds: 15);
    return client;
  }

  // 通用 POST 调用（支持自签名证书 + session_id 自动附带）
  static Future<Map<String, dynamic>> _post(String url, Map<String, String> body, {bool auth = false}) async {
    try {
      final client = _createClient();
      final request = await client.postUrl(Uri.parse(url));

      // 构建表单数据
      final formData = <String, String>[...body];
      // 如果有 session_id，自动加上
      if (auth && _sessionId != null) {
        formData['session_id'] = _sessionId!;
      }

      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      request.write(formData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&'));

      final response = await request.close();
      if (response.statusCode == 200) {
        final stringData = await response.transform(utf8.decoder).join();
        client.close();
        // 处理 PHP 返回可能带 BOM 的情况
        final cleanData = stringData.replaceAll('\uFEFF', '');
        if (cleanData.isNotEmpty) {
          return jsonDecode(cleanData);
        }
        return {'success': false, 'message': '空响应'};
      }
      client.close();
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
    });
    if (res['success'] == true && res['data'] != null) {
      final sessionId = (res['data']['id'] ?? '').toString();
      await _saveSession(sessionId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', res['data']['name'] ?? '');
      await prefs.setString('user_role', res['data']['role'] ?? '');
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
    });
  }

  static Future<void> logout() async {
    await _saveSession(null);
  }

  // ========== 2. 统计数据 ==========
  static Future<Map> getStats() async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_stats',
      if (_sessionId != null) 'session_id': _sessionId!,
    });
  }

  // ========== 3. 订单/工单 ==========
  static Future<Map> getOrders({String? status, String? keyword, int page = 1}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_orders',
      if (_sessionId != null) 'session_id': _sessionId!,
      if (status != null) 'status': status,
      if (keyword != null) 'keyword': keyword,
      'page': page.toString(),
    });
  }

  static Future<Map> updateOrder(String id, String status, {String? actualCost}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_order_update',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
      'status': status,
      if (actualCost != null) 'actual_cost': actualCost,
    });
  }

  static Future<Map> deleteOrder(String id) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_order_delete',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
    });
  }

  static Future<Map> memberPayOrder(String orderId, String memberId) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_order_member_pay',
      if (_sessionId != null) 'session_id': _sessionId!,
      'order_id': orderId,
      'member_id': memberId,
    });
  }

  // ========== 4. 会员 ==========
  static Future<Map> getMembers({String? keyword, int page = 1}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_members',
      if (_sessionId != null) 'session_id': _sessionId!,
      if (keyword != null) 'keyword': keyword,
      'page': page.toString(),
    });
  }

  static Future<Map> memberLookup(String keyword) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_lookup',
      if (_sessionId != null) 'session_id': _sessionId!,
      'keyword': keyword,
    });
  }

  static Future<Map> editMember(Map data) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_edit',
      if (_sessionId != null) 'session_id': _sessionId!,
      ...data.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  static Future<Map> deleteMember(String id) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_delete',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
    });
  }

  static Future<Map> memberRecharge(String id, String amount, {String? note}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_recharge',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
      'amount': amount,
      if (note != null) 'note': note,
    });
  }

  static Future<Map> memberDeduct(String id, String amount, {String? note}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_deduct',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
      'amount': amount,
      if (note != null) 'note': note,
    });
  }

  static Future<Map> getMemberRecords({String? memberId, int page = 1}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_member_records',
      if (_sessionId != null) 'session_id': _sessionId!,
      if (memberId != null) 'member_id': memberId,
      'page': page.toString(),
    });
  }

  // ========== 5. 客户 ==========
  static Future<Map> getCustomers({String? keyword, int page = 1}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_customers',
      if (_sessionId != null) 'session_id': _sessionId!,
      if (keyword != null) 'keyword': keyword,
      'page': page.toString(),
    });
  }

  static Future<Map> getCustomerDetail(String id) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_customer_detail',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
    });
  }

  // ========== 6. 车辆 ==========
  static Future<Map> getVehicleDetail(String id) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_vehicle_detail',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
    });
  }

  static Future<Map> updateVehicle(Map data) async {
    return await _post(ApiConfig.vehicleApi, {
      'action': 'save',
      if (_sessionId != null) 'session_id': _sessionId!,
      ...data.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  // ========== 7. 库存 ==========
  static Future<Map> getInventory({String? keyword, int page = 1}) async {
    return await _post(ApiConfig.appApi, {
      'action': 'app_inventory',
      if (_sessionId != null) 'session_id': _sessionId!,
      if (keyword != null) 'keyword': keyword,
      'page': page.toString(),
    });
  }

  // ========== 8. 洗车 ==========
  static Future<Map> getWashMeals() async {
    return await _post(ApiConfig.washApi, {
      'action': 'meal_list',
      if (_sessionId != null) 'session_id': _sessionId!,
    });
  }

  static Future<Map> saveWashMeal(Map data) async {
    return await _post(ApiConfig.washApi, {
      'action': 'meal_save',
      if (_sessionId != null) 'session_id': _sessionId!,
      ...data.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  static Future<Map> deleteWashMeal(String id) async {
    return await _post(ApiConfig.washApi, {
      'action': 'meal_delete',
      if (_sessionId != null) 'session_id': _sessionId!,
      'id': id,
    });
  }

  static Future<Map> searchMember(String keyword, {bool global = false}) async {
    return await _post(ApiConfig.washApi, {
      'action': 'member_search',
      if (_sessionId != null) 'session_id': _sessionId!,
      'keyword': keyword,
      'global': global ? '1' : '0',
    });
  }

  static Future<Map> saveMember(Map data) async {
    return await _post(ApiConfig.washApi, {
      'action': 'member_save',
      if (_sessionId != null) 'session_id': _sessionId!,
      ...data.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  static Future<Map> wash(String memberId, int times) async {
    return await _post(ApiConfig.washApi, {
      'action': 'wash',
      if (_sessionId != null) 'session_id': _sessionId!,
      'member_id': memberId,
      'times': times.toString(),
    });
  }

  // ========== 9. 店铺 ==========
  static Future<Map> getStores() async {
    return await _post(ApiConfig.storeApi, {
      'action': 'list',
      if (_sessionId != null) 'session_id': _sessionId!,
    });
  }

  // ========== 10. 系统设置 ==========
  static Future<Map> getSettings() async {
    return await _post(ApiConfig.appApi, {
      'action': 'settings',
      if (_sessionId != null) 'session_id': _sessionId!,
    });
  }
}
