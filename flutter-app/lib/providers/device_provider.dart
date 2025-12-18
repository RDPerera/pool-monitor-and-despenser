import 'package:flutter/material.dart';
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
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  Future<void> loadDevices() async {
    _setLoading(true);
    _setError(null);

    try {
      _devices = await _deviceService.getDevices();
      if (_devices.isNotEmpty && _selectedDevice == null) {
        _selectedDevice = _devices.first;
        await loadLatestReading(_selectedDevice!.deviceId);
      }
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadLatestReading(String deviceId) async {
    try {
      _latestReading = await _deviceService.getLatestReading(deviceId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> loadDeviceConfig(String deviceId) async {
    _setLoading(true);
    _setError(null);

    try {
      _deviceConfig = await _deviceService.getDeviceConfig(deviceId);
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
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