class AdminOrderItem {
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
  final String userFullName;
  final String userEmail;

  AdminOrderItem({
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
    required this.userFullName,
    required this.userEmail,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
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
      userFullName: json['userFullName'],
      userEmail: json['userEmail'],
    );
  }
}
