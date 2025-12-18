import 'package:json_annotation/json_annotation.dart';

part 'dispensing_job.g.dart';

@JsonSerializable()
class DispensingJob {
  final int? id;
  @JsonKey(name: 'device_id')
  final String? deviceId;
  final double hcl;
  final double soda;
  final double cl;
  final double al;
  final String flag;
  final String timestamp;

  DispensingJob({
    this.id,
    this.deviceId,
    this.hcl = 0.0,
    this.soda = 0.0,
    this.cl = 0.0,
    this.al = 0.0,
    this.flag = '',
    this.timestamp = '',
  });

  factory DispensingJob.fromJson(Map<String, dynamic> json) {
    return DispensingJob(
      id: json['id'] as int?,
      deviceId: json['device_id'] as String?,
      hcl: (json['hcl'] as num?)?.toDouble() ?? 0.0,
      soda: (json['soda'] as num?)?.toDouble() ?? 0.0,
      cl: (json['cl'] as num?)?.toDouble() ?? 0.0,
      al: (json['al'] as num?)?.toDouble() ?? 0.0,
      flag: json['flag'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => _$DispensingJobToJson(this);
}