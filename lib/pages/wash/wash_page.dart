// 洗车管理页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class WashPage extends StatefulWidget {
  const WashPage({super.key});

  @override
  State<WashPage> createState() => _WashPageState();
}

class _WashPageState extends State<WashPage> {
  List _meals = [];
  List _records = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final mealsRes = await ApiService.getWashMeals();
    if (!mounted) return;
    setState(() {
      _meals = (mealsRes['data'] ?? []) as List;
      _loading = false;
    });
  }

  void _washMember(Map member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('洗车 - ${member['name'] ?? ''}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('车牌: ${member['plate'] ?? ''}'),
            Text('剩余次数: ${member['wash_times'] ?? 0}'),
            const SizedBox(height: 16),
            if ((member['wash_times'] ?? 0) > 0)
              FilledButton.icon(
                onPressed: () async {
                  final res = await ApiService.wash(member['id'].toString(), 1);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '洗车成功')));
                    _load();
                  }
                },
                icon: const Icon(Icons.local_car_wash),
                label: const Text('确认洗车（扣1次）'),
              )
            else
              const Text('次数不足，请先充值', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  void _searchAndWash() async {
    final keyword = _searchCtrl.text;
    if (keyword.isEmpty) return;
    final res = await ApiService.searchMember(keyword);
    if (!mounted) return;
    if (res['success'] == true && res['data'] != null) {
      final members = res['data'] as List;
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未找到会员')));
      } else if (members.length == 1) {
        _washMember(members[0]);
      } else {
        showDialog(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('选择会员'),
            children: members.map((m) => SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _washMember(m);
              },
              child: Text('${m['name']} - ${m['plate']} (剩余${m['wash_times']}次)'),
            )).toList(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('洗车管理')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 快速洗车
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('快速洗车', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                decoration: InputDecoration(
                                  hintText: '输入会员姓名/电话/车牌',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _searchAndWash(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _searchAndWash,
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('搜索'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 新增会员
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('新增会员', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(labelText: '姓名', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneCtrl,
                          decoration: InputDecoration(labelText: '电话', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _plateCtrl,
                          decoration: InputDecoration(labelText: '车牌', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final res = await ApiService.saveMember({
                              'name': _nameCtrl.text,
                              'phone': _phoneCtrl.text,
                              'plate': _plateCtrl.text,
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '保存成功')));
                              _nameCtrl.clear();
                              _phoneCtrl.clear();
                              _plateCtrl.clear();
                            }
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('保存'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 套餐列表
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('洗车套餐', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        ..._meals.map((m) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m['meal_name'] ?? ''),
                          trailing: Text('¥${m['price'] ?? '0'} / ${m['times'] ?? 0}次', style: const TextStyle(fontWeight: FontWeight.w600)),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
