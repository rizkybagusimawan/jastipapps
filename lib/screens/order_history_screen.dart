import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import '../screens/chat_screen.dart';
import '../config/app_config.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => OrderHistoryScreenState();
}

class OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<OrderItem>> _ordersFuture;

  Map<String, int> _unreadCounts = {};

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter status
  String _selectedStatus = 'Semua';

  final List<String> _statusFilters = [
    'Semua',
    'pending',
    'diproses',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();

    _ordersFuture = _apiService.getMyOrders();
    _loadUnreadCounts();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  // Dipanggil dari MainScreen ketika masuk ke menu Riwayat
  Future<void> refreshFromParent() async {
    await _refresh();
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final counts = await _apiService.getUnreadMessageCounts();

      if (!mounted) return;

      setState(() {
        _unreadCounts = counts;
      });
    } catch (_) {
      // Jangan membuat halaman riwayat gagal hanya karena
      // unread count gagal dimuat.
    }
  }

  Widget _buildUnreadBadge(String orderId) {
    final count = _unreadCounts[orderId] ?? 0;

    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          count > 99 ? '99+' : count.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final future = _apiService.getMyOrders();

    setState(() {
      _ordersFuture = future;
    });

    await Future.wait([future, _loadUnreadCounts()]);
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return Colors.green;

      case 'diproses':
        return Colors.blue;

      case 'dibatalkan':
        return Colors.red;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'diproses':
        return 'Diproses';

      case 'selesai':
        return 'Selesai';

      case 'dibatalkan':
        return 'Dibatalkan';

      default:
        return status;
    }
  }

  List<OrderItem> _filterOrders(List<OrderItem> orders) {
    return orders.where((order) {
      // =========================
      // FILTER STATUS
      // =========================
      final statusMatch =
          _selectedStatus == 'Semua' ||
          order.status.toLowerCase() == _selectedStatus.toLowerCase();

      if (!statusMatch) {
        return false;
      }

      // =========================
      // SEARCH
      // =========================
      if (_searchQuery.isEmpty) {
        return true;
      }

      final namaProduk = order.namaProduk.toLowerCase();
      final orderId = order.id.toLowerCase();
      final status = order.status.toLowerCase();

      return namaProduk.contains(_searchQuery) ||
          orderId.contains(_searchQuery) ||
          status.contains(_searchQuery);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama produk atau Order ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final isSelected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(status == 'Semua' ? 'Semua' : _statusLabel(status)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySearchResult() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 60),
        Icon(Icons.search_off, size: 60, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'Order tidak ditemukan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Coba gunakan kata kunci atau filter status lainnya.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: order.fotoUrl != null && order.fotoUrl!.isNotEmpty
              ? Image.network(
                  AppConfig.getImageUrl(order.fotoUrl!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported_outlined),
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
            Text('${order.jumlah}x • ${_formatRupiah(order.totalHarga)}'),

            // =========================
            // ORDER ID
            // =========================
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ID: ${order.id}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: order.id));

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

            // =========================
            // KETERANGAN STATUS
            // =========================
            if (order.keteranganStatus != null &&
                order.keteranganStatus!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Keterangan: ${order.keteranganStatus}',
                style: const TextStyle(fontSize: 12),
              ),
            ],

            // =========================
            // BUKTI FOTO
            // =========================
            if (order.buktiFotoUrl != null &&
                order.buktiFotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  _showImagePreview(AppConfig.getImageUrl(order.buktiFotoUrl!));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    AppConfig.getImageUrl(order.buktiFotoUrl!),
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        isThreeLine: true,

        // =========================
        // CHAT + STATUS
        // =========================
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          orderId: order.id,
                          orderTitle: order.namaProduk,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    await _loadUnreadCounts();
                  },
                ),
                _buildUnreadBadge(order.id),
              ],
            ),

            Chip(
              label: Text(
                _statusLabel(order.status),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: _statusColor(order.status),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

      body: Column(
        children: [
          // =========================
          // SEARCH
          // =========================
          _buildSearchBar(),

          // =========================
          // FILTER STATUS
          // =========================
          _buildStatusFilter(),

          const SizedBox(height: 4),

          // =========================
          // LIST ORDER
          // =========================
          Expanded(
            child: RefreshIndicator(
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
                          child: Text(
                            'Gagal memuat: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  }

                  final orders = snapshot.data ?? [];

                  // =========================
                  // BELUM ADA ORDER
                  // =========================
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

                  // =========================
                  // FILTER ORDER
                  // =========================
                  final filteredOrders = _filterOrders(orders);

                  // =========================
                  // HASIL FILTER KOSONG
                  // =========================
                  if (filteredOrders.isEmpty) {
                    return _buildEmptySearchResult();
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];

                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
