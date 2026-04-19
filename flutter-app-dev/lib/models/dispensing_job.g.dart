// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unused_element

part of 'dispensing_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DispensingJob _$DispensingJobFromJson(Map<String, dynamic> json) =>
    DispensingJob(
      id: (json['id'] as num).toInt(),
      deviceId: json['device_id'] as String,
      hcl: (json['hcl'] as num).toDouble(),
      soda: (json['soda'] as num).toDouble(),
      cl: (json['cl'] as num).toDouble(),
      al: (json['al'] as num).toDouble(),
      flag: json['flag'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$DispensingJobToJson(DispensingJob instance) =>
    <String, dynamic>{
      'id': instance.id,
      'device_id': instance.deviceId,
      'hcl': instance.hcl,
      'soda': instance.soda,
      'cl': instance.cl,
      'al': instance.al,
      'flag': instance.flag,
      'timestamp': instance.timestamp,
    };
