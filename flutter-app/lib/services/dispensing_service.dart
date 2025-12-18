import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dispensing_job.dart';
import 'auth_service.dart';

class DispensingService {
  static const String baseUrl = 'http://localhost:5000/api';
  final AuthService _authService = AuthService();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<DispensingJob> createDispensingJob({
    required String deviceId,
    required double hcl,
    required double soda,
    required double cl,
    required double al,
    String flag = 'PENDING',
    String? timestamp,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/dispensing-jobs'),
      headers: await _getHeaders(),
      body: json.encode({
        'device_id': deviceId,
        'hcl': hcl,
        'soda': soda,
        'cl': cl,
        'al': al,
        'flag': flag,
        if (timestamp != null) 'timestamp': timestamp,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DispensingJob.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to create dispensing job');
    }
  }

  Future<List<DispensingJob>> getPendingJobs({
    int limit = 100,
    String? deviceId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (deviceId != null) 'device_id': deviceId,
    };

    final uri = Uri.parse('$baseUrl/dispensing-jobs')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DispensingJob.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load pending jobs');
    }
  }

  Future<List<DispensingJob>> getJobsByDevice(
    String deviceId, {
    int limit = 100,
    String status = 'PENDING',
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'status': status,
    };

    final uri = Uri.parse('$baseUrl/dispensing-jobs/$deviceId')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DispensingJob.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load jobs for device');
    }
  }

  Future<List<DispensingJob>> getAllJobs({
    int limit = 500,
    String? deviceId,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (deviceId != null) 'device_id': deviceId,
      if (status != null) 'status': status,
    };

    final uri = Uri.parse('$baseUrl/dispensing-jobs/all')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => DispensingJob.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load all jobs');
    }
  }

  Future<DispensingJob> updateDispensingJob(
    int jobId,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/dispensing-jobs/$jobId'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return DispensingJob.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update dispensing job');
    }
  }
}