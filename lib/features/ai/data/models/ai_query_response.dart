import 'package:yabai_app/features/ai/data/models/ai_project_model.dart';

class AiQueryResponse {
  const AiQueryResponse({
    required this.extractFilters,
    required this.searchTrials,
  });

  final Map<String, dynamic> extractFilters;
  final SearchTrials searchTrials;

  factory AiQueryResponse.fromJson(Map<String, dynamic> json) {
    return AiQueryResponse(
      extractFilters: json['extract_filters'] as Map<String, dynamic>? ?? {},
      searchTrials: SearchTrials.fromJson(
        json['search_trials'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'extract_filters': extractFilters,
      'search_trials': searchTrials.toJson(),
    };
  }
}

class SearchTrials {
  const SearchTrials({
    required this.projects,
  });

  final List<AiProjectModel> projects;

  factory SearchTrials.fromJson(Map<String, dynamic> json) {
    final projectsList = json['projects'] as List<dynamic>? ?? [];
    return SearchTrials(
      projects: projectsList
          .map((item) => AiProjectModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projects': projects.map((p) => p.toJson()).toList(),
    };
  }
}

