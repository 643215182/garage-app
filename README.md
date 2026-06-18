# 汽修管理助手 Flutter App

## 项目说明
基于 Flutter 开发的汽修管理 App，对接现有 PHP 后端 API。

## 功能模块
- 登录/注册（调 `app_api.php`）
- 仪表盘（统计数据、最近工单、低库存预警）
- 客户管理（列表搜索、详情查看）
- 工单管理（列表筛选、状态变更：接单/完成/取消）
- 会员管理（开卡、充值、扣费、洗车）
- 洗车管理（快速洗车、套餐管理）
- 库存管理（配件查询、低库存预警）
- 报表统计（运营概览、会员统计）
- 个人中心（账号信息、退出登录）

## 支持的 API
全部调你服务器上的现成 PHP API，不需要改后端。

## 构建方法

### 前提
在本地电脑安装 Flutter SDK：
- Windows/macOS/Linux 都支持
- 官方下载：https://docs.flutter.dev/get-started/install

### 步骤
```bash
# 1. 克隆/复制项目
cd garage_app

# 2. 安装依赖
flutter pub get

# 3. 连接手机或开模拟器，构建APK
flutter build apk --release

# APK 输出位置：
# build/app/outputs/flutter-apk/app-release.apk
```

### 第一次构建如果报错
```bash
flutter doctor   # 检查环境
flutter clean    # 清理缓存
flutter pub get  # 重新装依赖
flutter build apk --release
```

## 配置服务器地址
编辑 `lib/config/api_config.dart`，把 `baseUrl` 改成你的正式域名：

```dart
static const String baseUrl = 'https://你的域名';
```

## 项目结构
```
garage_app/
├── lib/
│   ├── main.dart                      # 入口 + 启动页
│   ├── config/
│   │   └── api_config.dart            # API 地址配置
│   ├── services/
│   │   └── api_service.dart           # API 封装层
│   ├── pages/
│   │   ├── login/login_page.dart      # 登录
│   │   ├── main_page.dart             # 主框架（导航）
│   │   ├── dashboard/                 # 首页仪表盘
│   │   ├── customers/                 # 客户管理
│   │   ├── workorders/                # 工单管理
│   │   ├── members/                   # 会员管理
│   │   ├── inventory/                 # 库存管理
│   │   ├── wash/                      # 洗车管理
│   │   ├── reports/                   # 报表统计
│   │   └── profile/                   # 个人中心
│   └── widgets/                       # 通用组件
├── pubspec.yaml                       # 依赖配置
└── android/                           # Android 配置
```
