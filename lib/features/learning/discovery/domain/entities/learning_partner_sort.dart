/// Supported sorting criteria for Learning Partner Explorer (CF-04).
enum LearningPartnerSort {
  /// Default relevance / recommended ordering.
  recommended,

  /// Display Name alphabetical order (A – Z).
  nameAsc,

  /// Display Name reverse alphabetical order (Z – A).
  nameDesc,

  /// Candidates with the most offered skills first.
  skillsCount;

  /// User-visible label for presentation in sort dropdowns.
  String get label {
    switch (this) {
      case LearningPartnerSort.recommended:
        return 'Recommended';
      case LearningPartnerSort.nameAsc:
        return 'Name: A to Z';
      case LearningPartnerSort.nameDesc:
        return 'Name: Z to A';
      case LearningPartnerSort.skillsCount:
        return 'Most Skills Offered';
    }
  }
}
