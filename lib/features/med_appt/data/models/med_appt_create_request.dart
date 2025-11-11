/// 创建用药预约的请求模型
class MedApptCreateRequest {
  final int projectId;
  final String patientInNo;
  final String patientName;
  final String? patientNameAbbr;
  final String planDate; // yyyy-MM-dd
  final String timeSlot; // AM, PM, EVE
  final int durationMinutes;
  final int? coreValidHours;
  final String drugText;
  final String? note;

  MedApptCreateRequest({
    required this.projectId,
    required this.patientInNo,
    required this.patientName,
    this.patientNameAbbr,
    required this.planDate,
    required this.timeSlot,
    required this.durationMinutes,
    this.coreValidHours,
    required this.drugText,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'patientInNo': patientInNo,
      'patientName': patientName,
      'patientNameAbbr': patientNameAbbr,
      'planDate': planDate,
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'coreValidHours': coreValidHours,
      'drugText': drugText,
      'note': note,
    };
  }
}

