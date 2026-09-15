class OrderItem {
  final String id;
  final String productId;
  final String namaProduk;
  final String? fotoUrl;
  final int jumlah;
  final String? catatan;
  final double hargaSatuan;
  final double totalHarga;
  final String status;
  final String createdAt;

  OrderItem({
    required this.id,
    required this.productId,
    required this.namaProduk,
    this.fotoUrl,
    required this.jumlah,
    this.catatan,
    required this.hargaSatuan,
    required this.totalHarga,
    required this.status,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['productId'],
      namaProduk: json['namaProduk'],
      fotoUrl: json['fotoUrl'],
      jumlah: json['jumlah'],
      catatan: json['catatan'],
      hargaSatuan: (json['hargaSatuan'] as num).toDouble(),
      totalHarga: (json['totalHarga'] as num).toDouble(),
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }
}
