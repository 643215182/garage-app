// 会员管理页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List _members = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getMembers();
    if (!mounted) return;
    setState(() {
      _members = (res['data'] ?? []) as List;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('会员管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索姓名/电话/车牌',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (v) async {
                final res = await ApiService.getMembers(keyword: v);
                if (mounted) {
                  setState(() => _members = (res['data'] ?? []) as List);
                }
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _members.isEmpty
                    ? const Center(child: Text('暂无会员数据'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _members.length,
                          itemBuilder: (_, i) {
                            final m = _members[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.purple[100],
                                  child: Text(
                                    (m['name'] ?? '?').toString().isNotEmpty 
                                        ? (m['name'] ?? '?').toString()[0] 
                                        : '?',
                                    style: const TextStyle(color: Colors.purple),
                                  ),
                                ),
                                title: Text(m['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${m['phone'] ?? ''}  ${m['plate'] ?? ''}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('洗车: ${m['wash_times'] ?? 0}次', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                    Text('余额: ¥${m['balance'] ?? '0'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                                onTap: () => _showMemberDetail(m),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createMember(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showMemberDetail(Map member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberDetailSheet(member: member, onChanged: _load),
    );
  }

  void _createMember() {
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('新增会员'),
        content: Text('功能开发中...'),
      ),
    );
  }
}

class _MemberDetailSheet extends StatefulWidget {
  final Map member;
  final VoidCallback onChanged;

  const _MemberDetailSheet({required this.member, required this.onChanged});

  @override
  State<_MemberDetailSheet> createState() => _MemberDetailSheetState();
}

class _MemberDetailSheetState extends State<_MemberDetailSheet> {
  final _amountCtrl = TextEditingController();

  Future<void> _recharge() async {
    final amount = _amountCtrl.text;
    if (amount.isEmpty) return;
    final res = await ApiService.memberRecharge(widget.member['id'].toString(), amount);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '充值成功')));
      _amountCtrl.clear();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      expand: false,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(m['name'] ?? '', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _infoRow(Icons.phone, '电话', m['phone'] ?? '-'),
          _infoRow(Icons.directions_car, '车牌', m['plate'] ?? '-'),
          _infoRow(Icons.local_car_wash, '洗车次数', '${m['wash_times'] ?? 0} 次'),
          _infoRow(Icons.monetization_on, '余额', '¥${m['balance'] ?? '0'}'),
          _infoRow(Icons.calendar_today, '开卡时间', m['created_at'] ?? '-'),
          const Divider(height: 32),
          const Text('充值/扣费', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '金额',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _recharge,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('充值'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.remove, size: 18),
                label: const Text('扣费'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
}
