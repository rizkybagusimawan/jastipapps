import 'package:dio/dio.dart';
import '../models/product.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../models/order.dart';
import '../models/admin_order.dart';
import '../models/chat_message.dart';
import 'dart:io';
import '../config/app_config.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.apiBaseUrl}/auth',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ============================================
  // REGISTER
  // ============================================
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final response = await _dio.post(
        '/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        },
      );

      await _saveToken(response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // LOGIN
  // ============================================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      await _saveToken(response.data['token']);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // FORGOT PASSWORD
  // ============================================
  Future<String> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
      );
      return response.data.toString();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // RESET PASSWORD
  // ============================================
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/reset-password',
        data: {'token': token, 'newPassword': newPassword},
      );
      return response.data.toString();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // TOKEN STORAGE
  // ============================================
  Future<void> _saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
  }

  // ============================================
  // ERROR HANDLING
  // ============================================
  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return data.toString();
    }
    return 'Terjadi kesalahan. Cek koneksi internet kamu.';
  }

  // ============================================
  // PRODUCTS
  // ============================================
  Future<List<Product>> getProducts({
    String? status,
    String? search,
    String? kategori,
  }) async {
    try {
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/products',
            queryParameters: {
              if (status != null) 'status': status,
              if (search != null && search.isNotEmpty) 'search': search,
              if (kategori != null && kategori != 'Semua') 'kategori': kategori,
            },
          );

      final List<dynamic> content = response.data['content'];
      return content.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await Dio(
        BaseOptions(baseUrl: AppConfig.apiBaseUrl),
      ).get('/products/$id');

      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> getProfile() async {
    try {
      final token = await getToken();
      final response = await _dio.get(
        '/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) async {
    try {
      final token = await getToken();
      final response = await _dio.put(
        '/me',
        data: {'fullName': fullName, 'phoneNumber': phoneNumber},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<OrderItem> createOrder({
    required String productId,
    required int jumlah,
    String? catatan,
  }) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .post(
            '/orders',
            data: {
              'productId': productId,
              'jumlah': jumlah,
              'catatan': catatan,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      return OrderItem.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<OrderItem>> getMyOrders() async {
    try {
      final token = await getToken();

      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/orders/my',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

      final List<dynamic> data = response.data;

      final orders = data.map((json) {
        return OrderItem.fromJson(json);
      }).toList();

      return orders;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ============================================
  // ADMIN: PRODUCT MANAGEMENT
  // ============================================
  Future<Product> createProduct({
    required String namaProduk,
    String? deskripsi,
    String? kategori,
    String? fotoUrl,
    String? sumber,
    required double hargaAsli,
    required double biayaJasa,
    int? kuota,
  }) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .post(
            '/products',
            data: {
              'namaProduk': namaProduk,
              'deskripsi': deskripsi,
              'kategori': kategori,
              'fotoUrl': fotoUrl,
              'sumber': sumber,
              'hargaAsli': hargaAsli,
              'biayaJasa': biayaJasa,
              'kuota': kuota,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> updateProduct({
    required String id,
    required String namaProduk,
    String? deskripsi,
    String? kategori,
    String? fotoUrl,
    String? sumber,
    required double hargaAsli,
    required double biayaJasa,
    int? kuota,
  }) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .put(
            '/products/$id',
            data: {
              'namaProduk': namaProduk,
              'deskripsi': deskripsi,
              'kategori': kategori,
              'fotoUrl': fotoUrl,
              'sumber': sumber,
              'hargaAsli': hargaAsli,
              'biayaJasa': biayaJasa,
              'kuota': kuota,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      return Product.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateProductStatus({
    required String id,
    required String status,
  }) async {
    try {
      final token = await getToken();
      await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).patch(
        '/products/$id/status',
        data: {'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final token = await getToken();
      await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).delete(
        '/products/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Product>> getAllProductsForAdmin({
    String? search,
    String? kategori,
  }) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/products',
            queryParameters: {
              'size': 100,
              if (search != null && search.isNotEmpty) 'search': search,
              if (kategori != null && kategori != 'Semua') 'kategori': kategori,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      final List<dynamic> content = response.data['content'];
      return content.map((json) => Product.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<AdminOrderItem>> getAllOrdersAdmin({
    String? status,
    String? orderId,
  }) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/orders/all',
            queryParameters: {
              if (status != null && status.isNotEmpty) 'status': status,
              if (orderId != null && orderId.isNotEmpty) 'orderId': orderId,
            },
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      final List<dynamic> data = response.data;
      return data.map((json) => AdminOrderItem.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
    String? keteranganStatus,
    String? buktiFotoUrl,
  }) async {
    try {
      final token = await getToken();
      await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).patch(
        '/orders/$orderId/status',
        data: {
          'status': status,
          'keteranganStatus': keteranganStatus,
          'buktiFotoUrl': buktiFotoUrl,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChatMessage>> getMessages(String orderId) async {
    try {
      final token = await getToken();
      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/orders/$orderId/messages',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
      final List<dynamic> data = response.data;
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> sendMessage({
    required String orderId,
    String? message,
    String? imageUrl,
  }) async {
    try {
      final token = await getToken();

      await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).post(
        '/orders/$orderId/messages',
        data: {'message': message, 'imageUrl': imageUrl},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      final token = await getToken();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .post(
            '/upload',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markMessagesAsRead(String orderId) async {
    try {
      final token = await getToken();

      await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl)).patch(
        '/orders/$orderId/messages/read',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadMessageCount(String orderId) async {
    try {
      final token = await getToken();

      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/orders/$orderId/messages/unread-count',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, int>> getUnreadMessageCounts() async {
    try {
      final token = await getToken();

      final response = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .get(
            '/orders/my/messages/unread-counts',
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data,
      );

      return data.map((key, value) => MapEntry(key, (value as num).toInt()));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
