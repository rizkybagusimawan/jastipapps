import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/admin_order.dart';
import '../screens/chat_screen.dart';
import '../services/api_service.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, int> _unreadCounts = {};

  late Future<List<AdminOrderItem>> _ordersFuture;

  Timer? _unreadTimer;

  String _selectedStatus = 'Semua';
  String _searchQuery = '';

  final List<String> _statusList = [
    'Semua',
    'pending',
    'diproses',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();

    _ordersFuture = _apiService.getAllOrdersAdmin(status: null, orderId: '');

    _loadUnreadCounts();

    // Update badge otomatis setiap 4 detik.
    _unreadTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadUnreadCounts();
    });
  }

  Future<void> _refresh() async {
    final future = _apiService.getAllOrdersAdmin(
      status: _selectedStatus == 'Semua' ? null : _selectedStatus,
      orderId: _searchQuery,
    );

    if (mounted) {
      setState(() {
        _ordersFuture = future;
      });
    }

    await Future.wait([future, _loadUnreadCounts()]);
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final counts = await _apiService.getUnreadMessageCounts();

      if (!mounted) return;

      setState(() {
        _unreadCounts = counts;
      });
    } catch (_) {
      // Jangan membuat halaman order gagal
      // hanya karena unread count gagal dimuat.
    }
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

  Widget _buildUnreadBadge(String orderId) {
    final count = _unreadCounts[orderId] ?? 0;

    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: -6,
      top: -8,
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).scaffoldBackgroundColor,
            width: 2,
          ),
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

  Future<void> _openChat(AdminOrderItem order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(orderId: order.id, orderTitle: order.namaProduk),
      ),
    );

    // Setelah kembali dari ChatScreen,
    // langsung update badge.
    if (!mounted) return;

    await _loadUnreadCounts();
  }

  Future<void> _changeStatus(AdminOrderItem order) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _ChangeStatusDialog(order: order, apiService: _apiService),
    );

    if (result == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Status diubah')));

      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Order'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Order ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _searchQuery = '';
                          });

                          _refresh();
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });

                _refresh();
              },
            ),
          ),

          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _statusList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusList[index];
                final isSelected = status == _selectedStatus;

                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = status;
                    });

                    _refresh();
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<AdminOrderItem>>(
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
                            'Tidak ada order.',
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        order.fotoUrl != null &&
                                            order.fotoUrl!.isNotEmpty
                                        ? Image.network(
                                            AppConfig.getImageUrl(
                                              order.fotoUrl!,
                                            ),
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return Container(
                                                width: 48,
                                                height: 48,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 20,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 20,
                                            ),
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.namaProduk,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${order.jumlah}x • ${_formatRupiah(order.totalHarga)}',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Chip(
                                    label: Text(
                                      order.status,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: _statusColor(order.status),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ],
                              ),

                              const Divider(),

                              Text(
                                'Order ID: ${order.id}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),

                              const SizedBox(height: 4),

                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${order.userFullName} (${order.userEmail})',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if (order.catatan != null &&
                                  order.catatan!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Catatan: ${order.catatan}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],

                              if (order.keteranganStatus != null &&
                                  order.keteranganStatus!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Keterangan: ${order.keteranganStatus}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],

                              if (order.buktiFotoUrl != null &&
                                  order.buktiFotoUrl!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    AppConfig.getImageUrl(order.buktiFotoUrl!),
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) {
                                      return Container(
                                        height: 100,
                                        width: double.infinity,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _openChat(order),
                                        icon: const Icon(
                                          Icons.chat_bubble_outline,
                                          size: 16,
                                        ),
                                        label: const Text('Chat'),
                                      ),

                                      _buildUnreadBadge(order.id),
                                    ],
                                  ),

                                  const SizedBox(width: 8),

                                  OutlinedButton.icon(
                                    onPressed: () => _changeStatus(order),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Ubah Status'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
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

  @override
  void dispose() {
    _unreadTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}

class _ChangeStatusDialog extends StatefulWidget {
  final AdminOrderItem order;
  final ApiService apiService;

  const _ChangeStatusDialog({required this.order, required this.apiService});

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  late String _selectedStatus;

  final _keteranganController = TextEditingController();
  final _buktiFotoController = TextEditingController();

  bool _isSaving = false;
  bool _isUploadingBukti = false;

  File? _selectedBuktiImage;

  @override
  void initState() {
    super.initState();

    _selectedStatus = widget.order.status;

    _keteranganController.text = widget.order.keteranganStatus ?? '';

    _buktiFotoController.text = widget.order.buktiFotoUrl ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    final imageFile = File(pickedFile.path);

    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    setState(() {
      _selectedBuktiImage = imageFile;
      _isUploadingBukti = true;
    });

    try {
      final url = await widget.apiService.uploadImage(imageFile);

      if (!mounted) return;

      setState(() {
        _buktiFotoController.text = url;
        _isUploadingBukti = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingBukti = false;
        _selectedBuktiImage = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload foto gagal: $e')));
    }
  }

  Future<void> _handleSave() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.apiService.updateOrderStatus(
        orderId: widget.order.id,
        status: _selectedStatus,
        keteranganStatus: _keteranganController.text.trim(),
        buktiFotoUrl: _buktiFotoController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildImageArea() {
    if (_selectedBuktiImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_selectedBuktiImage!, fit: BoxFit.cover),
          ),
          if (_isUploadingBukti)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }

    if (_buktiFotoController.text.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          AppConfig.getImageUrl(_buktiFotoController.text),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Icon(Icons.broken_image_outlined, size: 36),
            );
          },
        ),
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 36),
          SizedBox(height: 6),
          Text('Tap untuk pilih foto bukti'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Status Order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                'pending',
                'diproses',
                'selesai',
                'dibatalkan',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _keteranganController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (opsional)',
                hintText: 'Misal: barang sudah dikirim via JNE',
              ),
              maxLines: 2,
            ),

            if (_selectedStatus == 'selesai') ...[
              const SizedBox(height: 12),

              const Text(
                'Bukti Foto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),

              const SizedBox(height: 8),

              GestureDetector(
                onTap: _isUploadingBukti ? null : _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildImageArea(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),

        FilledButton(
          onPressed: (_isSaving || _isUploadingBukti) ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _keteranganController.dispose();
    _buktiFotoController.dispose();
    super.dispose();
  }
}
