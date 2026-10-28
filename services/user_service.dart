import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';

class UserService {
  static const String baseUrl = 'https://reqres.in/api/users';
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'x-api-key': 'free_user_3LJyqSYwnjqqQEUTi7RJfYl97Co',
  };

  // GET
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl?page=1'), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final userList = data['data'] as List<dynamic>;
        return userList
            .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw _responseError('mengambil data', response.statusCode);
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server Reqres.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melewati batas waktu.');
    }
  }

  // POST
  Future<UserModel> createUser(String name, String job) async {
    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: _headers,
            body: jsonEncode({'name': name, 'job': job}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseId = data['id'];
        return UserModel(
          id: int.tryParse(responseId?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
          email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
          firstName: name,
          lastName: '',
          avatar: '',
        );
      } else {
        throw _responseError('membuat user', response.statusCode);
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server Reqres.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melewati batas waktu.');
    }
  }

  // PUT
  Future<bool> updateUser(int id, String name, String job) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/$id'),
            headers: _headers,
            body: jsonEncode({'name': name, 'job': job}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw _responseError('memperbarui user', response.statusCode);
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server Reqres.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melewati batas waktu.');
    }
  }

  // DELETE
  Future<bool> deleteUser(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$baseUrl/$id'), headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 204) {
        return true;
      } else {
        throw _responseError('menghapus user', response.statusCode);
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on http.ClientException {
      throw Exception('Tidak dapat terhubung ke server Reqres.');
    } on TimeoutException {
      throw Exception('Permintaan ke server melewati batas waktu.');
    }
  }

  Exception _responseError(String action, int statusCode) {
    return Exception(
      'Gagal $action. Server merespons dengan status $statusCode.',
    );
  }
}