import 'package:flutter/foundation.dart';
import '../domain/entities/eligibility_result.dart';
import '../domain/entities/gender_type.dart';
import '../domain/repositories/eligibility_repository.dart';

/// ViewModel managing state, age guidance, and submission for Screen 09.
class EligibilityViewModel extends ChangeNotifier {
  EligibilityViewModel({
    required EligibilityRepository repository,
  }) : _repository = repository;

  final EligibilityRepository _repository;

  DateTime? _dateOfBirth;
  GenderType? _gender;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _isLoading = false;
  bool _isServiceUnavailable = false;
  String? _errorMessage;

  String _languageCode = 'en';

  DateTime? get dateOfBirth => _dateOfBirth;
  GenderType? get gender => _gender;
  bool get termsAccepted => _termsAccepted;
  bool get privacyAccepted => _privacyAccepted;
  bool get isLoading => _isLoading;
  bool get isServiceUnavailable => _isServiceUnavailable;
  String? get errorMessage => _errorMessage;
  String get languageCode => _languageCode;

  /// ISO-8601 YYYY-MM-DD representation of the selected date of birth.
  String? get dateOfBirthIso {
    if (_dateOfBirth == null) return null;
    final y = _dateOfBirth!.year.toString().padLeft(4, '0');
    final m = _dateOfBirth!.month.toString().padLeft(2, '0');
    final d = _dateOfBirth!.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void setLanguageCode(String code) {
    _languageCode = code;
    notifyListeners();
  }

  /// Sets DOB from an ISO YYYY-MM-DD string with strict calendar validity (e.g. leap years).
  void setDateOfBirthFromIso(String isoString) {
    try {
      final parts = isoString.split('-');
      if (parts.length != 3) {
        _errorMessage = 'Invalid date format. Expected YYYY-MM-DD.';
        notifyListeners();
        return;
      }
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final parsed = DateTime(year, month, day);
      if (parsed.year != year || parsed.month != month || parsed.day != day) {
        _errorMessage = 'Invalid calendar date.';
        notifyListeners();
        return;
      }
      setDateOfBirth(parsed);
    } catch (_) {
      _errorMessage = 'Invalid date format. Expected YYYY-MM-DD.';
      notifyListeners();
    }
  }

  /// Calculates user age locally strictly for display guidance (Rule 01 & 02).
  int? get calculatedAge {
    if (_dateOfBirth == null) return null;
    final now = DateTime.now();
    var age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get isUnder16 {
    final age = calculatedAge;
    return age != null && age < 16;
  }

  bool get isUnder18 {
    final age = calculatedAge;
    return age != null && age < 18;
  }

  bool get canSubmit =>
      !_isLoading &&
      _dateOfBirth != null &&
      _gender != null &&
      _termsAccepted &&
      _privacyAccepted &&
      !isUnder16;

  void setDateOfBirth(DateTime date) {
    final now = DateTime.now();
    if (date.isAfter(now)) {
      _errorMessage = 'Date of birth cannot be in the future.';
      notifyListeners();
      return;
    }
    _dateOfBirth = date;
    _errorMessage = null;

    if (isUnder16) {
      _errorMessage =
          'You must be at least 16 years old to participate in ANDRIL modules.';
    }

    notifyListeners();
  }

  void setGender(GenderType gender) {
    _gender = gender;
    _errorMessage = null;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setPrivacyAccepted(bool value) {
    _privacyAccepted = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> submitEligibility({
    required ValueChanged<EligibilityResult> onSuccess,
  }) async {
    if (_isLoading) return;
    _errorMessage = null;
    _isServiceUnavailable = false;

    if (_dateOfBirth == null) {
      _errorMessage = 'Please select your date of birth.';
      notifyListeners();
      return;
    }

    if (isUnder16) {
      _errorMessage =
          'ANDRIL requires members to be at least 16 years of age.';
      notifyListeners();
      return;
    }

    if (_gender == null) {
      _errorMessage = 'Please select your gender.';
      notifyListeners();
      return;
    }

    if (!_termsAccepted || !_privacyAccepted) {
      _errorMessage =
          'Please agree to the Terms of Service and Privacy Policy.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.submitEligibility(
        dateOfBirth: _dateOfBirth!,
        gender: _gender!,
        termsAccepted: _termsAccepted,
        privacyAccepted: _privacyAccepted,
      );

      _isLoading = false;

      if (result.isServiceUnavailable) {
        _isServiceUnavailable = true;
        _errorMessage = result.errorMessage ??
            'Policy documents are unavailable (HTTP 503). Progression paused.';
        notifyListeners();
        return;
      }

      if (!result.isEligible) {
        _errorMessage = result.errorMessage ??
            'Your account is not currently eligible for module participation.';
        notifyListeners();
        return;
      }

      notifyListeners();
      onSuccess(result);
    } catch (_) {
      _isLoading = false;
      _errorMessage =
          'Unable to submit eligibility at this time. Please check your network connection.';
      notifyListeners();
    }
  }
}
