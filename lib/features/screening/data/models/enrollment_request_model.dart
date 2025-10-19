/// 入组信息提交请求模型
class EnrollmentRequestModel {
  const EnrollmentRequestModel({
    required this.enrollNo,
    required this.enrollDate,
    this.firstDoseDate,
  });

  final String enrollNo;
  final String enrollDate; // yyyy-MM-dd
  final String? firstDoseDate; // yyyy-MM-dd

  Map<String, dynamic> toJson() => {
        'enrollNo': enrollNo,
        'enrollDate': enrollDate,
        'firstDoseDate': firstDoseDate,
      };
}

