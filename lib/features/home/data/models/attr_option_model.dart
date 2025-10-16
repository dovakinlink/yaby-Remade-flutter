class AttrOptionModel {
  const AttrOptionModel({
    required this.id,
    required this.code,
    required this.label,
    required this.sort,
    required this.enabled,
  });

  final int id;
  final String code;
  final String label;
  final int sort;
  final bool enabled;

  factory AttrOptionModel.fromJson(Map<String, dynamic> json) {
    return AttrOptionModel(
      id: json['id'] as int,
      code: json['code'] as String,
      label: json['label'] as String,
      sort: json['sort'] as int,
      enabled: json['enabled'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'label': label,
      'sort': sort,
      'enabled': enabled,
    };
  }
}

