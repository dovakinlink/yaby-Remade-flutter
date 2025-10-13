class ProjectStatistics {
  const ProjectStatistics({
    required this.enrolling,
    required this.pending,
    required this.stopped,
    required this.total,
  });

  final int enrolling;
  final int pending;
  final int stopped;
  final int total;

  factory ProjectStatistics.fromJson(Map<String, dynamic> json) {
    return ProjectStatistics(
      enrolling: _readInt(json['enrolling']),
      pending: _readInt(json['pending']),
      stopped: _readInt(json['stopped']),
      total: _readInt(json['total']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
