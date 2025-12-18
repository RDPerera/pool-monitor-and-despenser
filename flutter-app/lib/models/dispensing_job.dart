import 'package:json_annotation/json_annotation.dart';

part 'dispensing_job.g.dart';

@JsonSerializable()
class DispensingJob {
  final int id;
  @JsonKey(name: 'device_id')
  final String deviceId;
  final double hcl;
  final double soda;
  final double cl;
  final double al;
  final String flag;
  final String timestamp;

  DispensingJob({
    required this.id,
    required this.deviceId,
    required this.hcl,
    required this.soda,
    required this.cl,
    required this.al,
    required this.flag,
    required this.timestamp,
  });

  factory DispensingJob.fromJson(Map<String, dynamic> json) => _$DispensingJobFromJson(json);
  Map<String, dynamic> toJson() => _$DispensingJobToJson(this);
}