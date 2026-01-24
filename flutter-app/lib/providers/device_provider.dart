import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class DeviceProvider with ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  
  List<Device> _devices = [];
  Device? _selectedDevice;
  List<SensorReading> _readings = [];
  SensorReading? _latestReading;
  DeviceConfig? _deviceConfig;
  DeviceStats? _deviceStats;
  
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => _devices;
  Device? get selectedDevice => _selectedDevice;
  List<SensorReading> get readings => _readings;
  SensorReading? get latestReading => _latestReading;
  DeviceConfig? get deviceConfig => _deviceConfig;
  DeviceStats? get deviceStats => _deviceStats;
  bool get isLoading => _isLoading;
  String? get error => _error;


  void _setLoading(bool loading) {
    _isLoading = loading;
    debugPrint('[DeviceProvider] Loading: $_isLoading');
    notifyListeners();
  }


  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('[DeviceProvider] Error: $error');
    }
    notifyListeners();
  }

  Future<void> loadDevices() async {
    _setLoading(true);
    _setError(null);

    try {
      debugPrint('[DeviceProvider] Fetching devices...');
      _devices = await _deviceService.getDevices();
      debugPrint('[DeviceProvider] Devices loaded: \\${_devices.length}');

      // If no real devices found, populate mock device + reading in debug mode
      if (_devices.isEmpty && kDebugMode) {
        _devices = [
          Device(
            id: 0,
            deviceId: 'mock-device',
            name: 'Mock Pool Device',
            location: 'Test Pool',
            registeredAt: DateTime.now().toIso8601String(),
            lastSeen: DateTime.now().toIso8601String(),
          ),
        ];
        _selectedDevice = _devices.first;
        _latestReading = SensorReading(
          id: 0,
          deviceId: 'mock-device',
          timestamp: DateTime.now().toIso8601String(),
          ph: 7.20,
          turbidity: 3.5,
          temperature: 26.8,
          waterQuality: 'Optimal',
          wifiRssi: -48,
          uptime: 3600,
        );
      } else if (_devices.isNotEmpty && _selectedDevice == null) {
        _selectedDevice = _devices.first;
        await loadLatestReading(_selectedDevice!.deviceId);
      }
    } catch (e) {
      debugPrint('[DeviceProvider] Exception in loadDevices: $e');
      if (kDebugMode) {
        // Populate mock device + reading when backend is unavailable
        _devices = [
          Device(
            id: 0,
            deviceId: 'mock-device',
            name: 'Mock Pool Device',
            location: 'Test Pool',
            registeredAt: DateTime.now().toIso8601String(),
            lastSeen: DateTime.now().toIso8601String(),
          ),
        ];
        _selectedDevice = _devices.first;
        _latestReading = SensorReading(
          id: 0,
          deviceId: 'mock-device',
          timestamp: DateTime.now().toIso8601String(),
          ph: 7.20,
          turbidity: 3.5,
          temperature: 26.8,
          waterQuality: 'Optimal',
          wifiRssi: -48,
          uptime: 3600,
        );
        _setError(null);
      } else {
        _setError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> selectDevice(String deviceId) async {
    _selectedDevice = _devices.firstWhere((device) => device.deviceId == deviceId);
    await loadLatestReading(deviceId);
    notifyListeners();
  }

  Future<void> loadDeviceReadings(String deviceId, {int limit = 100, int? hours}) async {
    _setLoading(true);
    _setError(null);

    try {
      _readings = await _deviceService.getDeviceReadings(
        deviceId,
        limit: limit,
        hours: hours,
      );
    } catch (e) {
      debugPrint('[DeviceProvider] Exception in loadDeviceReadings: $e');
      if (kDebugMode) {
        // create some mock historical readings for UI demo
        _readings = List.generate(6, (i) {
          final t = DateTime.now().subtract(Duration(hours: i * 4));
          return SensorReading(
            id: i,
            deviceId: deviceId,
            timestamp: t.toIso8601String(),
            ph: 7.0 + (i % 3) * 0.1,
            turbidity: 2.0 + (i % 4) * 0.5,
            temperature: 26.0 + (i % 5) * 0.6,
            waterQuality: 'Optimal',
          );
        });
      } else {
        _setError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLatestReading(String deviceId) async {
    try {
      debugPrint('[DeviceProvider] Fetching latest reading for device: $deviceId');
      final reading = await _deviceService.getLatestReading(deviceId);
      if (reading == null) {
        debugPrint('[DeviceProvider] No latest reading for device: $deviceId');
        _latestReading = null;
      } else {
        _latestReading = reading;
        debugPrint('[DeviceProvider] Latest reading: $_latestReading');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DeviceProvider] Exception in loadLatestReading: $e');
      if (kDebugMode) {
        _latestReading = SensorReading(
          id: 0,
          deviceId: deviceId,
          timestamp: DateTime.now().toIso8601String(),
          ph: 7.20,
          turbidity: 3.5,
          temperature: 26.8,
          waterQuality: 'Optimal',
          wifiRssi: -48,
          uptime: 3600,
        );
        _setError(null);
        notifyListeners();
      } else {
        _latestReading = null;
        _setError(e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> loadDeviceConfig(String deviceId) async {
    _setLoading(true);
    _setError(null);

    try {
      _deviceConfig = await _deviceService.getDeviceConfig(deviceId);
      // leave _deviceConfig as returned by the backend (no debug mock)
    } catch (e) {
      debugPrint('[DeviceProvider] Exception in loadDeviceConfig: $e');
      if (kDebugMode) {
        _setError(null);
      } else {
        _setError(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDeviceConfig(String deviceId, DeviceConfig config) async {
    _setLoading(true);
    _setError(null);

    try {
      if (_deviceConfig == null) {
        _deviceConfig = await _deviceService.createDeviceConfig(deviceId, config);
      } else {
        _deviceConfig = await _deviceService.updateDeviceConfig(deviceId, config);
      }
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDeviceStats(String deviceId, {int hours = 24}) async {
    _setLoading(true);
    _setError(null);

    try {
      _deviceStats = await _deviceService.getDeviceStats(deviceId, hours: hours);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateDevice(String deviceId, {String? name, String? location}) async {
    _setLoading(true);
    _setError(null);

    try {
      final updatedDevice = await _deviceService.updateDevice(
        deviceId,
        name: name,
        location: location,
      );
      
      final index = _devices.indexWhere((device) => device.deviceId == deviceId);
      if (index != -1) {
        _devices[index] = updatedDevice;
        if (_selectedDevice?.deviceId == deviceId) {
          _selectedDevice = updatedDevice;
        }
      }
      
      return true;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _setError(null);
  }

  // Helper methods for water quality analysis
  String getWaterQualityStatus() {
    if (_latestReading == null) return 'Unknown';
    
    final reading = _latestReading!;
    
    // Check pH levels
    if (reading.ph < 6.8 || reading.ph > 8.2) {
      return 'Critical';
    } else if (reading.ph < 7.0 || reading.ph > 7.8) {
      return 'Warning';
    }
    
    // Check turbidity
    if (reading.turbidity > 50) {
      return 'Critical';
    } else if (reading.turbidity > 20) {
      return 'Warning';
    }
    
    // Check temperature
    if (reading.temperature > 33 || reading.temperature < 18) {
      return 'Critical';
    } else if (reading.temperature > 30 || reading.temperature < 20) {
      return 'Warning';
    }
    
    return 'Optimal';
  }

  Color getWaterQualityColor() {
    switch (getWaterQualityStatus()) {
      case 'Optimal':
        return Colors.green;
      case 'Warning':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}