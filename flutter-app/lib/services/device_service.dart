import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device.dart';
import 'auth_service.dart';

class DeviceService {
  static const String baseUrl = 'http://localhost:5000/api';
  final AuthService _authService = AuthService();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Device>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load devices');
    }
  }

  Future<Device> getDevice(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load device');
    }
  }

  Future<List<SensorReading>> getDeviceReadings(
    String deviceId, {
    int limit = 100,
    int? hours,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      if (hours != null) 'hours': hours.toString(),
    };

    final uri = Uri.parse('$baseUrl/devices/$deviceId/readings')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => SensorReading.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load device readings');
    }
  }

  Future<SensorReading?> getLatestReading(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId/latest'),
      headers: await _getHeaders(),
    );

    // Debug: print raw response
    print('[DeviceService] getLatestReading raw response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data != null ? SensorReading.fromJson(data) : null;
    } else {
      throw Exception('Failed to load latest reading');
    }
  }

  Future<DeviceConfig?> getDeviceConfig(String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices/$deviceId/config'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data != null ? DeviceConfig.fromJson(data) : null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load device config');
    }
  }

  Future<DeviceConfig> createDeviceConfig(String deviceId, DeviceConfig config) async {
    final response = await http.post(
      Uri.parse('$baseUrl/devices/$deviceId/config'),
      headers: await _getHeaders(),
      body: json.encode(config.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return DeviceConfig.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to create device config');
    }
  }

  Future<DeviceConfig> updateDeviceConfig(String deviceId, DeviceConfig config) async {
    final response = await http.put(
      Uri.parse('$baseUrl/devices/$deviceId/config'),
      headers: await _getHeaders(),
      body: json.encode(config.toJson()),
    );

    if (response.statusCode == 200) {
      return DeviceConfig.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update device config');
    }
  }

  Future<Device> updateDevice(String deviceId, {String? name, String? location}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (location != null) body['location'] = location;

    final response = await http.put(
      Uri.parse('$baseUrl/devices/$deviceId'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return Device.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update device');
    }
  }

  Future<DeviceStats> getDeviceStats(String deviceId, {int hours = 24}) async {
    final queryParams = <String, String>{
      'hours': hours.toString(),
    };

    final uri = Uri.parse('$baseUrl/stats/$deviceId')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return DeviceStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load device stats');
    }
  }
}