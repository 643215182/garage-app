// API 配置
class ApiConfig {
  // 你的服务器地址 - 改成你的正式域名
  static const String baseUrl = 'https://154.194.253.213';
  
  // API 路径
  static const String appApi = '$baseUrl/car_repair_system/api/app_api.php';
  static const String washApi = '$baseUrl/car_repair_system/api/wash_api.php';
  static const String userApi = '$baseUrl/car_repair_system/api/user_api.php';
  static const String vehicleApi = '$baseUrl/car_repair_system/api/vehicle_api.php';
  static const String storeApi = '$baseUrl/car_repair_system/api/store_api.php';
  static const String plateRecognize = '$baseUrl/car_repair_system/api/plate_recognize.php';
  static const String vinDecode = '$baseUrl/car_repair_system/api/vin_decode.php';
  
  // 连接超时（秒）
  static const int timeout = 15;
}
