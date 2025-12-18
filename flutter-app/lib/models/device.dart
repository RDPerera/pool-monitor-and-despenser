import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

@JsonSerializable()
class Device {
  final int id;
  @JsonKey(name: 'device_id')
  final String deviceId;
  final String name;
  final String location;
  @JsonKey(name: 'registered_at')
  final String registeredAt;
  @JsonKey(name: 'last_seen')
  final String? lastSeen;

  Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.location,
    required this.registeredAt,
    this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

@JsonSerializable()
class SensorReading {
  final int id;
  @JsonKey(name: 'device_id')
  final String deviceId;
  final String timestamp;
  final double ph;
  final double turbidity;
  final double temperature;
  @JsonKey(name: 'water_quality')
  final String waterQuality;
  @JsonKey(name: 'wifi_rssi')
  final int? wifiRssi;
  final int? uptime;

  SensorReading({
    required this.id,
    required this.deviceId,
    required this.timestamp,
    required this.ph,
    required this.turbidity,
    required this.temperature,
    required this.waterQuality,
    this.wifiRssi,
    this.uptime,
  });

  factory SensorReading.fromJson(Map<String, dynamic> json) => _$SensorReadingFromJson(json);
  Map<String, dynamic> toJson() => _$SensorReadingToJson(this);
}

@JsonSerializable()
class DeviceConfig {
  final Map<String, dynamic>? calibration;
  final Map<String, dynamic>? thresholds;
  final Map<String, dynamic>? intervals;

  DeviceConfig({
    this.calibration,
    this.thresholds,
    this.intervals,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) => _$DeviceConfigFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceConfigToJson(this);
}

@JsonSerializable()
class DeviceStats {
  @JsonKey(name: 'period_hours')
  final int periodHours;
  @JsonKey(name: 'total_readings')
  final int totalReadings;
  final Map<String, dynamic> ph;
  final Map<String, dynamic> turbidity;
  final Map<String, dynamic> temperature;

  DeviceStats({
    required this.periodHours,
    required this.totalReadings,
    required this.ph,
    required this.turbidity,
    required this.temperature,
  });

  factory DeviceStats.fromJson(Map<String, dynamic> json) => _$DeviceStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceStatsToJson(this);
}