// App 主框架 - 底部导航整合所有功能
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard/dashboard_page.dart';
import 'customers/customers_page.dart';
import 'workorders/workorders_page.dart';
import 'members/members_page.dart';
import 'inventory/inventory_page.dart';
import 'wash/wash_page.dart';
import 'reports/reports_page.dart';
import 'profile/profile_page.dart';
import 'login/login_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final _pages = <Widget>[
    const _HomePage(),
    const CustomersPage(),
    const WorkOrdersPage(),
    const _MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '客户',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: '工单',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: '更多',
          ),
        ],
      ),
    );
  }
}

// 首页（整合了仪表盘 + 快捷入口）
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('汽修管理助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 仪表盘
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox.expand(child: Image.asset('assets/placeholder.png', fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 24),

          // 快捷功能网格
          const Text('快捷功能', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _quickAction(context, Icons.people, '客户', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomersPage()))),
              _quickAction(context, Icons.build, '工单', Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkOrdersPage()))),
              _quickAction(context, Icons.card_membership, '会员', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersPage()))),
              _quickAction(context, Icons.inventory_2, '库存', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryPage()))),
              _quickAction(context, Icons.local_car_wash, '洗车', Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WashPage()))),
              _quickAction(context, Icons.bar_chart, '报表', Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()))),
              _quickAction(context, Icons.settings, '设置', Colors.grey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
              _quickAction(context, Icons.directions_car, '车辆', Colors.green, () => {}),
            ],
          ),
          const SizedBox(height: 24),

          // 底部信息
          Center(
            child: Text('汽修管理助手 v1.0', style: TextStyle(color: Colors.grey[400])),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// "更多"页面（会员、库存、洗车、报表等入口）
class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更多功能')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(context, Icons.card_membership, '会员管理', '开卡、充值、扣次', Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersPage()))),
          _menuCard(context, Icons.local_car_wash, '洗车管理', '快速洗车、会员洗车', Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WashPage()))),
          _menuCard(context, Icons.inventory_2, '库存管理', '配件查询、库存预警', Colors.teal, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InventoryPage()))),
          _menuCard(context, Icons.bar_chart, '报表统计', '运营数据、会员统计', Colors.indigo, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage()))),
          _menuCard(context, Icons.directions_car, '车辆管理', '车辆信息、VIN查询', Colors.green, () {}),
          _menuCard(context, Icons.receipt_long, '账单管理', '历史账单、结算', Colors.brown, () {}),
          _menuCard(context, Icons.person, '个人中心', '账号信息、退出登录', Colors.grey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
