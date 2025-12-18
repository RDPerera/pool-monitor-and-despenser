// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Device _$DeviceFromJson(Map<String, dynamic> json) => Device(
      id: (json['id'] as num).toInt(),
      deviceId: json['device_id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      registeredAt: json['registered_at'] as String,
      lastSeen: json['last_seen'] as String?,
    );

Map<String, dynamic> _$DeviceToJson(Device instance) => <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'name': instance.name,
      'location': instance.location,
      'registered_at': instance.registeredAt,
      'last_seen': instance.lastSeen,
    };

SensorReading _$SensorReadingFromJson(Map<String, dynamic> json) =>
    SensorReading(
      id: (json['id'] as num).toInt(),
      deviceId: json['device_id'] as String,
      timestamp: json['timestamp'] as String,
      ph: (json['ph'] == null ? 0.0 : (json['ph'] as num).toDouble()),
      turbidity: (json['turbidity'] == null ? 0.0 : (json['turbidity'] as num).toDouble()),
      temperature: (json['temperature'] == null ? 0.0 : (json['temperature'] as num).toDouble()),
      waterQuality: json['water_quality'] as String,
      wifiRssi: (json['wifi_rssi'] as num?)?.toInt(),
      uptime: (json['uptime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SensorReadingToJson(SensorReading instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'timestamp': instance.timestamp,
      'ph': instance.ph,
      'turbidity': instance.turbidity,
      'temperature': instance.temperature,
      'water_quality': instance.waterQuality,
      'wifi_rssi': instance.wifiRssi,
      'uptime': instance.uptime,
    };

DeviceConfig _$DeviceConfigFromJson(Map<String, dynamic> json) => DeviceConfig(
      calibration: json['calibration'] as Map<String, dynamic>?,
      thresholds: json['thresholds'] as Map<String, dynamic>?,
      intervals: json['intervals'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DeviceConfigToJson(DeviceConfig instance) =>
    <String, dynamic>{
      'calibration': instance.calibration,
      'thresholds': instance.thresholds,
      'intervals': instance.intervals,
    };

DeviceStats _$DeviceStatsFromJson(Map<String, dynamic> json) => DeviceStats(
      periodHours: (json['period_hours'] as num).toInt(),
      totalReadings: (json['total_readings'] as num).toInt(),
      ph: json['ph'] as Map<String, dynamic>,
      turbidity: json['turbidity'] as Map<String, dynamic>,
      temperature: json['temperature'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$DeviceStatsToJson(DeviceStats instance) =>
    <String, dynamic>{
      'period_hours': instance.periodHours,
      'total_readings': instance.totalReadings,
      'ph': instance.ph,
      'turbidity': instance.turbidity,
      'temperature': instance.temperature,
    };
