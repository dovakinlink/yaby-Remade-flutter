import 'package:yabai_app/features/home/data/models/project_attr_model.dart';
import 'package:yabai_app/features/home/data/models/project_criteria_model.dart';
import 'package:yabai_app/features/home/data/models/project_file_model.dart';
import 'package:yabai_app/features/home/data/models/project_model.dart';
import 'package:yabai_app/features/home/data/models/project_staff_model.dart';

class ProjectDetailModel extends ProjectModel {
  const ProjectDetailModel({
    required super.id,
    required super.projName,
    super.shortTitle,
    super.sponsorName,
    super.piName,
    super.indication,
    super.projectNo,
    required super.progressName,
    required super.signedCount,
    required super.totalSignCount,
    required super.customTags,
    required super.createdAt,
    required super.updatedAt,
    super.xiaobaiStatus,
    this.remark,
    required this.customAttrs,
    required this.criteria,
    required this.files,
    required this.staff,
  });

  final String? remark;
  final List<ProjectAttrModel> customAttrs;
  final List<ProjectCriteriaModel> criteria;
  final List<ProjectFileModel> files;
  final List<ProjectStaffModel> staff;

  factory ProjectDetailModel.fromJson(Map<String, dynamic> json) {
    return ProjectDetailModel(
      id: json['id'] as int,
      projName: json['projName'] as String,
      shortTitle: json['shortTitle'] as String?,
      sponsorName: json['sponsorName'] as String?,
      piName: json['piName'] as String?,
      indication: json['indication'] as String?,
      projectNo: ProjectModel.parseProjectNo(json),
      progressName: json['progressName'] as String,
      signedCount: json['signedCount'] as int,
      totalSignCount: json['totalSignCount'] as int,
      customTags: (json['customTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      xiaobaiStatus: json['xiaobaiStatus'] as int? ?? 0,
      remark: json['remark'] as String?,
      customAttrs: (json['customAttrs'] as List<dynamic>?)
              ?.map((e) => ProjectAttrModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      criteria: (json['criteria'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectCriteriaModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      files: (json['files'] as List<dynamic>?)
              ?.map((e) => ProjectFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      staff: (json['staff'] as List<dynamic>?)
              ?.map((e) => ProjectStaffModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// 获取入组标准列表
  List<ProjectCriteriaModel> get inclusionCriteria =>
      criteria.where((c) => c.isInclusion).toList();

  /// 获取排除标准列表
  List<ProjectCriteriaModel> get exclusionCriteria =>
      criteria.where((c) => c.isExclusion).toList();

  /// 获取主要负责人
  ProjectStaffModel? get primaryStaff {
    try {
      return staff.firstWhere((s) => s.isPrimary);
    } catch (_) {
      return null;
    }
  }

  /// 获取 PI 人员（roleName = PI）
  ProjectStaffModel? get piStaff {
    try {
      return staff.firstWhere(
        (s) => s.roleName.toUpperCase() == 'PI',
      );
    } catch (_) {
      return null;
    }
  }

  /// 是否有备注
  bool get hasRemark => remark != null && remark!.isNotEmpty;

  /// 是否有自定义属性
  bool get hasCustomAttrs => customAttrs.isNotEmpty;

  /// 是否有标签
  bool get hasCustomTags => customTags.isNotEmpty;

  /// 是否有入排标准
  bool get hasCriteria => criteria.isNotEmpty;

  /// 是否有附件
  bool get hasFiles => files.isNotEmpty;

  /// 是否有人员
  bool get hasStaff => staff.isNotEmpty;
}
