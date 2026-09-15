class Product {
  final String id;
  final String namaProduk;
  final String? deskripsi;
  final String? kategori;
  final String? fotoUrl;
  final String? sumber;
  final double hargaAsli;
  final double biayaJasa;
  final double hargaTotal;
  final String status;
  final int kuota;

  Product({
    required this.id,
    required this.namaProduk,
    this.deskripsi,
    this.kategori,
    this.fotoUrl,
    this.sumber,
    required this.hargaAsli,
    required this.biayaJasa,
    required this.hargaTotal,
    required this.status,
    required this.kuota,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      namaProduk: json['namaProduk'],
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      fotoUrl: json['fotoUrl'],
      sumber: json['sumber'],
      hargaAsli: (json['hargaAsli'] as num).toDouble(),
      biayaJasa: (json['biayaJasa'] as num).toDouble(),
      hargaTotal: (json['hargaTotal'] as num).toDouble(),
      status: json['status'],
      kuota: json['kuota'] ?? 0,
    );
  }
}
