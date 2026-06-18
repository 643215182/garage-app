// 仪表盘页面 - App 首页
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map _stats = {};
  List _recentOrders = [];
  List _lowStock = [];
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStats();
    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _stats = res['data'] ?? {};
        _recentOrders = (res['recent_orders'] ?? []) as List;
        _lowStock = (res['low_stock_items'] ?? []) as List;
        _loading = false;
      });
    } else {
      setState(() { _error = res['message'] ?? '加载失败'; _loading = false; });
    }
  }

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const Center(child: Text('客户', style: TextStyle(fontSize: 24))),
      const Center(child: Text('工单', style: TextStyle(fontSize: 24))),
      const Center(child: Text('我的', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: pages[_selectedIndex],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: '首页'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: '客户'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: '工单'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final c = NumberFormat('#,###');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 24),
        Text('📊 数据概览', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildStatCard(Icons.people, '客户', '${_stats['customers'] ?? 0}', Colors.blue),
            _buildStatCard(Icons.directions_car, '车辆', '${_stats['vehicles'] ?? 0}', Colors.green),
            _buildStatCard(Icons.build, '待办', '${_stats['pending_orders'] ?? 0}', Colors.orange),
            _buildStatCard(Icons.inventory, '低库存', '${_stats['low_stock'] ?? 0}', Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.85,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildStatCard(Icons.check_circle, '今日完成', '${_stats['completed_today'] ?? 0}', Colors.teal),
            _buildStatCard(Icons.monetization_on, '本月收入', '¥${c.format((_stats['month_revenue'] ?? 0).toDouble())}', Colors.indigo),
            _buildStatCard(Icons.card_membership, '会员', '${_stats['total_members'] ?? 0}', Colors.purple),
            _buildStatCard(Icons.local_car_wash, '今日洗车', '${_stats['today_wash'] ?? 0}', Colors.cyan),
          ],
        ),
        const SizedBox(height: 24),

        // 最近工单
        if (_recentOrders.isNotEmpty) ...[
          Text('📋 最近工单', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...(_recentOrders.take(5).map((o) => Card(
            child: ListTile(
              leading: _orderStatusIcon(o['status'] ?? ''),
              title: Text('${o['plate'] ?? ''} - ${o['customer_name'] ?? ''}'),
              subtitle: Text(o['created_at'] ?? ''),
              trailing: Text('¥${o['actual_cost'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ))),
          const SizedBox(height: 24),
        ],

        // 低库存预警
        if (_lowStock.isNotEmpty) ...[
          Text('⚠️ 低库存预警', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...(_lowStock.take(5).map((i) => Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              title: Text(i['part_name'] ?? ''),
              subtitle: Text('库存: ${i['quantity'] ?? 0} / 最低: ${i['min_quantity'] ?? 0}'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ))),
        ],
      ],
    );
  }

  Widget _orderStatusIcon(String status) {
    final icons = {
      'pending': const Icon(Icons.hourglass_empty, color: Colors.orange),
      'in_progress': const Icon(Icons.build, color: Colors.blue),
      'completed': const Icon(Icons.check_circle, color: Colors.green),
      'cancelled': const Icon(Icons.cancel, color: Colors.grey),
    };
    return icons[status] ?? const Icon(Icons.help_outline);
  }
}
