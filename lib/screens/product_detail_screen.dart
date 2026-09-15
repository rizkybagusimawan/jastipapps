import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  late Future<Product> _productFuture;

  @override
  void initState() {
    super.initState();
    _productFuture = _apiService.getProductById(widget.productId);
  }

  String _formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Gagal memuat produk: ${snapshot.error}'),
              ),
            );
          }

          final product = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: product.fotoUrl != null
                      ? Image.network(
                          product.fotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.namaProduk,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          Chip(
                            label: Text(product.status),
                            backgroundColor: product.status == 'tersedia'
                                ? Colors.green[100]
                                : Colors.grey[300],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (product.kategori != null)
                        Chip(label: Text(product.kategori!)),
                      const SizedBox(height: 16),

                      if (product.sumber != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.storefront_outlined, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Dari: ${product.sumber}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      const Divider(),
                      const SizedBox(height: 8),

                      Text(
                        'Rincian Harga',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _priceRow('Harga Barang', product.hargaAsli),
                      _priceRow('Biaya Jasa Titip', product.biayaJasa),
                      const Divider(),
                      _priceRow('Total', product.hargaTotal, isBold: true),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),

                      Text(
                        'Deskripsi',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(product.deskripsi ?? '-'),

                      const SizedBox(height: 8),
                      Text(
                        'Kuota tersisa: ${product.kuota}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Product>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final product = snapshot.data!;
              return FilledButton(
                onPressed: () => _showOrderDialog(context, product),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Titip Sekarang'),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _formatRupiah(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context, Product product) {
    int jumlah = 1;
    final catatanController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Titip Barang Ini'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah'),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: jumlah > 1
                            ? () => setDialogState(() => jumlah--)
                            : null,
                      ),
                      Text('$jumlah', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: jumlah < product.kuota
                            ? () => setDialogState(() => jumlah++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Misal: size 42, warna hitam',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Text(
                'Total: ${_formatRupiah(product.hargaTotal * jumlah)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      try {
                        await _apiService.createOrder(
                          productId: product.id,
                          jumlah: jumlah,
                          catatan: catatanController.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order berhasil dibuat!'),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
  }
}
