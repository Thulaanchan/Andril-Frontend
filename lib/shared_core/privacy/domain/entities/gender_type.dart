/// Approved gender values for backend serialization in ANDRIL Member-02.
enum GenderType {
  male('Male', 'male'),
  female('Female', 'female'),
  other('Other', 'other'),
  preferNotToSay('Prefer not to say', 'prefer_not_to_say');

  const GenderType(this.displayLabel, this.backendValue);

  final String displayLabel;
  final String backendValue;

  static GenderType? fromBackendValue(String? value) {
    if (value == null) return null;
    for (final type in GenderType.values) {
      if (type.backendValue == value || type.name == value) return type;
    }
    return null;
  }
}
