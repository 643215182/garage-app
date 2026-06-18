// 工单列表页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  List _orders = [];
  bool _loading = true;
  String _statusFilter = '';
  final _searchCtrl = TextEditingController();

  final _statusTabs = [
    {'key': '', 'label': '全部', 'color': Colors.blue},
    {'key': 'pending', 'label': '待接单', 'color': Colors.orange},
    {'key': 'in_progress', 'label': '维修中', 'color': Colors.blue},
    {'key': 'completed', 'label': '已完成', 'color': Colors.green},
    {'key': 'cancelled', 'label': '已取消', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getOrders(
      status: _statusFilter.isEmpty ? null : _statusFilter,
    );
    if (!mounted) return;
    setState(() {
      _orders = (res['data'] ?? []) as List;
      _loading = false;
    });
  }

  String _statusLabel(String status) {
    final labels = {'pending': '待接单', 'in_progress': '维修中', 'completed': '已完成', 'cancelled': '已取消'};
    return labels[status] ?? status;
  }

  Color _statusColor(String status) {
    final colors = {'pending': Colors.orange, 'in_progress': Colors.blue, 'completed': Colors.green, 'cancelled': Colors.grey};
    return colors[status] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('工单管理')),
      body: Column(
        children: [
          // 状态筛选标签
          Container(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _statusTabs.map((t) {
                final active = _statusFilter == t['key'];
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: FilterChip(
                    label: Text(t['label'] as String),
                    selected: active,
                    onSelected: (_) {
                      setState(() => _statusFilter = t['key'] as String);
                      _load();
                    },
                    selectedColor: (t['color'] as Color).withOpacity(0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          // 搜索
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索车牌/客户名/电话',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          // 列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? const Center(child: Text('暂无工单'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (_, i) {
                            final o = _orders[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ExpansionTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(o['status'] ?? '').withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _statusLabel(o['status'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _statusColor(o['status'] ?? ''),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                title: Text('${o['plate'] ?? ''} - ${o['customer_name'] ?? ''}'),
                                subtitle: Text(o['created_at'] ?? '', style: const TextStyle(fontSize: 12)),
                                trailing: Text('¥${o['actual_cost'] ?? '0'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (o['services'] != null) ...[
                                          const Text('服务项目:', style: TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          ...((o['services'] as List).map((s) => Text('  • ${s['name'] ?? ''}  ¥${s['price'] ?? '0'}'))),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (o['status'] == 'pending')
                                              _actionChip('接单', Colors.blue, () => _updateStatus(o['id'].toString(), 'in_progress')),
                                            if (o['status'] == 'in_progress')
                                              _actionChip('完成', Colors.green, () => _updateStatus(o['id'].toString(), 'completed')),
                                            if (o['status'] != 'cancelled')
                                              _actionChip('取消', Colors.red, () => _updateStatus(o['id'].toString(), 'cancelled')),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _actionChip(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ActionChip(
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        onPressed: onTap,
        side: BorderSide(color: color),
      ),
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    final res = await ApiService.updateOrder(int.parse(id), <String, String>{"status": status});
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('操作成功')));
      _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '操作失败')));
    }
  }

  void _createOrder() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('新建工单'),
        content: Text('功能开发中...'),
      ),
    );
  }
}
