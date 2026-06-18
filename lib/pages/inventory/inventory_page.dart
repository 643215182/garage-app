// 库存管理页面
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List _items = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await ApiService.getInventory();
    if (!mounted) return;
    setState(() {
      _items = (res['data'] ?? []) as List;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('库存管理')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索配件名称',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('暂无库存数据'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final item = _items[i];
                            final qty = int.tryParse('${item['quantity'] ?? 0}') ?? 0;
                            final minQty = int.tryParse('${item['min_quantity'] ?? 0}') ?? 0;
                            final lowStock = qty <= minQty;
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: Icon(
                                  lowStock ? Icons.warning_amber_rounded : Icons.inventory_2,
                                  color: lowStock ? Colors.red : Colors.green,
                                ),
                                title: Text(item['part_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text('${item['part_number'] ?? ''}\n¥${item['price'] ?? '0'}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('$qty 件', style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: lowStock ? Colors.red : Colors.black87,
                                      fontSize: 16,
                                    )),
                                    Text('最低: $minQty', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
