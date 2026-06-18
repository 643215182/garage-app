// 报表/统计页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  Map _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getStats();
    if (!mounted) return;
    setState(() {
      _stats = res['data'] ?? {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('报表统计')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection('运营概览', [
                  _statRow('总客户数', '${_stats['customers'] ?? 0}', Icons.people),
                  _statRow('总车辆数', '${_stats['vehicles'] ?? 0}', Icons.directions_car),
                  _statRow('本月收入', '¥${NumberFormat('#,###').format((_stats['month_revenue'] ?? 0).toDouble())}', Icons.monetization_on),
                  _statRow('今日完成', '${_stats['completed_today'] ?? 0} 单', Icons.check_circle),
                  _statRow('待处理工单', '${_stats['pending_orders'] ?? 0}', Icons.build),
                  _statRow('低库存商品', '${_stats['low_stock'] ?? 0}', Icons.warning),
                ]),
                const SizedBox(height: 16),
                _buildSection('会员统计', [
                  _statRow('总会员数', '${_stats['total_members'] ?? 0}', Icons.card_membership),
                  _statRow('今日洗车', '${_stats['today_wash'] ?? 0} 次', Icons.local_car_wash),
                  _statRow('今日充值', '¥${NumberFormat('#,###').format((_stats['member_revenue'] ?? 0).toDouble())}', Icons.trending_up),
                ]),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
