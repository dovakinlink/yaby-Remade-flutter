/// 用药预约数据模型
class MedApptModel {
  final int id;
  final int orgId;
  final int projectId;
  final String projName;
  final String patientInNo;
  final String patientName;
  final String? patientNameAbbr;
  final String researcherPersonId;
  final String researcherName;
  final String? crcPersonId;
  final String? crcName;
  final String? nursePersonId;
  final String? nurseName;
  final String planDate; // yyyy-MM-dd
  final String planWeekMonday; // yyyy-MM-dd
  final String timeSlot; // AM, PM, EVE
  final int durationMinutes;
  final int? coreValidHours;
  final String drugText;
  final String? note;
  final String status; // PENDING, CONFIRMED, CANCELLED, DONE
  final String source; // APP, WEB, IMPORT
  final int createdBy;
  final String createdAt;
  final int? updatedBy;
  final String updatedAt;

  MedApptModel({
    required this.id,
    required this.orgId,
    required this.projectId,
    required this.projName,
    required this.patientInNo,
    required this.patientName,
    this.patientNameAbbr,
    required this.researcherPersonId,
    required this.researcherName,
    this.crcPersonId,
    this.crcName,
    this.nursePersonId,
    this.nurseName,
    required this.planDate,
    required this.planWeekMonday,
    required this.timeSlot,
    required this.durationMinutes,
    this.coreValidHours,
    required this.drugText,
    this.note,
    required this.status,
    required this.source,
    required this.createdBy,
    required this.createdAt,
    this.updatedBy,
    required this.updatedAt,
  });

  factory MedApptModel.fromJson(Map<String, dynamic> json) {
    return MedApptModel(
      id: json['id'] as int,
      orgId: json['orgId'] as int,
      projectId: json['projectId'] as int,
      projName: json['projName'] as String,
      patientInNo: json['patientInNo'] as String,
      patientName: json['patientName'] as String,
      patientNameAbbr: json['patientNameAbbr'] as String?,
      researcherPersonId: json['researcherPersonId'] as String,
      researcherName: json['researcherName'] as String,
      crcPersonId: json['crcPersonId'] as String?,
      crcName: json['crcName'] as String?,
      nursePersonId: json['nursePersonId'] as String?,
      nurseName: json['nurseName'] as String?,
      planDate: json['planDate'] as String,
      planWeekMonday: json['planWeekMonday'] as String,
      timeSlot: json['timeSlot'] as String,
      durationMinutes: json['durationMinutes'] as int,
      coreValidHours: json['coreValidHours'] as int?,
      drugText: json['drugText'] as String,
      note: json['note'] as String?,
      status: json['status'] as String,
      source: json['source'] as String,
      createdBy: json['createdBy'] as int,
      createdAt: json['createdAt'] as String,
      updatedBy: json['updatedBy'] as int?,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orgId': orgId,
      'projectId': projectId,
      'projName': projName,
      'patientInNo': patientInNo,
      'patientName': patientName,
      'patientNameAbbr': patientNameAbbr,
      'researcherPersonId': researcherPersonId,
      'researcherName': researcherName,
      'crcPersonId': crcPersonId,
      'crcName': crcName,
      'nursePersonId': nursePersonId,
      'nurseName': nurseName,
      'planDate': planDate,
      'planWeekMonday': planWeekMonday,
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'coreValidHours': coreValidHours,
      'drugText': drugText,
      'note': note,
      'status': status,
      'source': source,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt,
    };
  }

  /// 获取时段的中文描述
  String get timeSlotLabel {
    switch (timeSlot) {
      case 'AM':
        return '上午';
      case 'PM':
        return '下午';
      case 'EVE':
        return '晚上';
      default:
        return timeSlot;
    }
  }

  /// 获取状态的中文描述
  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return '待确认';
      case 'CONFIRMED':
        return '已确认';
      case 'CANCELLED':
        return '已取消';
      case 'DONE':
        return '已完成';
      default:
        return status;
    }
  }
}

