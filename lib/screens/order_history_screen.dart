import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => OrderHistoryScreenState();
}

class OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<OrderItem>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _apiService.getMyOrders();
  }

  // Dipanggil dari MainScreen ketika masuk ke menu Riwayat
  Future<void> refreshFromParent() async {
    await _refresh();
  }

  Future<void> _refresh() async {
    final future = _apiService.getMyOrders();

    setState(() {
      _ordersFuture = future;
    });

    await future;
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'selesai':
        return Colors.green;
      case 'diproses':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Order'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<OrderItem>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Gagal memuat: ${snapshot.error}'),
                  ),
                ],
              );
            }

            final orders = snapshot.data ?? [];

            if (orders.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada order.\n'
                      'Yuk mulai titip barang favoritmu!\n\n'
                      '(Tarik ke bawah atau tekan ikon refresh '
                      'untuk muat ulang)',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: order.fotoUrl != null
                          ? Image.network(
                              order.fotoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey[200],
                              child: const Icon(Icons.shopping_bag_outlined),
                            ),
                    ),
                    title: Text(
                      order.namaProduk,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.jumlah}x • ${_formatRupiah(order.totalHarga)}',
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'ID: ${order.id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: order.id),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order ID disalin'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Icon(Icons.copy, size: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,

                    trailing: Chip(
                      label: Text(
                        order.status,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: _statusColor(order.status),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
