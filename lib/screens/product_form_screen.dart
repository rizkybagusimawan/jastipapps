import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = mode tambah, ada isinya = mode edit

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late final TextEditingController _namaController;
  late final TextEditingController _deskripsiController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _fotoUrlController;
  late final TextEditingController _sumberController;
  late final TextEditingController _hargaAsliController;
  late final TextEditingController _biayaJasaController;
  late final TextEditingController _kuotaController;

  bool _isSaving = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _namaController = TextEditingController(text: p?.namaProduk ?? '');
    _deskripsiController = TextEditingController(text: p?.deskripsi ?? '');
    _kategoriController = TextEditingController(text: p?.kategori ?? '');
    _fotoUrlController = TextEditingController(text: p?.fotoUrl ?? '');
    _sumberController = TextEditingController(text: p?.sumber ?? '');
    _hargaAsliController = TextEditingController(
      text: p?.hargaAsli.toStringAsFixed(0) ?? '',
    );
    _biayaJasaController = TextEditingController(
      text: p?.biayaJasa.toStringAsFixed(0) ?? '',
    );
    _kuotaController = TextEditingController(text: p?.kuota.toString() ?? '1');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        await _apiService.updateProduct(
          id: widget.product!.id,
          namaProduk: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          kategori: _kategoriController.text.trim(),
          fotoUrl: _fotoUrlController.text.trim(),
          sumber: _sumberController.text.trim(),
          hargaAsli: double.parse(_hargaAsliController.text),
          biayaJasa: double.parse(_biayaJasaController.text),
          kuota: int.tryParse(_kuotaController.text),
        );
      } else {
        await _apiService.createProduct(
          namaProduk: _namaController.text.trim(),
          deskripsi: _deskripsiController.text.trim(),
          kategori: _kategoriController.text.trim(),
          fotoUrl: _fotoUrlController.text.trim(),
          sumber: _sumberController.text.trim(),
          hargaAsli: double.parse(_hargaAsliController.text),
          biayaJasa: double.parse(_biayaJasaController.text),
          kuota: int.tryParse(_kuotaController.text),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kategoriController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Fashion, Elektronik, Kosmetik, dll',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fotoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Foto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sumberController,
                decoration: const InputDecoration(
                  labelText: 'Sumber (nama toko/negara)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hargaAsliController,
                decoration: const InputDecoration(
                  labelText: 'Harga Asli (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _biayaJasaController,
                decoration: const InputDecoration(
                  labelText: 'Biaya Jasa Titip (Rp)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Wajib diisi';
                  if (double.tryParse(v) == null) return 'Harus berupa angka';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kuotaController,
                decoration: const InputDecoration(
                  labelText: 'Kuota',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditMode ? 'Simpan Perubahan' : 'Tambah Produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
