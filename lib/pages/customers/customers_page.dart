// 客户列表 + 详情页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List _customers = [];
  bool _loading = true;
  String _keyword = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getCustomers(keyword: _keyword);
    if (!mounted) return;
    setState(() {
      _customers = (res['data'] ?? []) as List;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('客户管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索姓名/电话',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _keyword.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchCtrl.clear();
                        setState(() { _keyword = ''; });
                        _load();
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (v) {
                setState(() => _keyword = v);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                    ? const Center(child: Text('暂无客户数据'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _customers.length,
                          itemBuilder: (_, i) {
                            final c = _customers[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    (c['name'] ?? '?').toString().isNotEmpty 
                                        ? (c['name'] ?? '?').toString()[0] 
                                        : '?',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(c['name'] ?? '未知', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${c['phone'] ?? ''}  |  车辆: ${c['vehicle_count'] ?? 0}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('¥${c['total_spent'] ?? '0'}', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                onTap: () => _showDetail(c),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDetail(Map customer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(customer['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _infoRow(Icons.phone, '电话', customer['phone'] ?? '-'),
            _infoRow(Icons.email, '邮箱', customer['email'] ?? '-'),
            _infoRow(Icons.location_on, '地址', customer['address'] ?? '-'),
            _infoRow(Icons.monetization_on, '累计消费', '¥${customer['total_spent'] ?? '0'}'),
            _infoRow(Icons.people, '到店次数', '${customer['visit_count'] ?? 0} 次'),
            _infoRow(Icons.calendar_today, '注册时间', customer['created_at'] ?? '-'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('编辑'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 80, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEdit({Map? customer}) {
    // TODO: 实现编辑/新增客户页面
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('新增客户'),
        content: Text('功能开发中...'),
      ),
    );
  }
}
