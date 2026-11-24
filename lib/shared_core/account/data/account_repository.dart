import '../../../core/network/api_client/andril_api_client.dart';
import '../../../core/security/session/session_controller.dart';

class Account {
  const Account._(this.accountId, this.createdAtUtc, this.updatedAtUtc);

  final String accountId;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;

  factory Account.fromJson(Map<String, Object?> json) {
    final id = json['accountId'];
    final created = _utc(json['createdAtUtc']);
    final updated = _utc(json['updatedAtUtc']);
    if (id is! String ||
        !RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
                caseSensitive: false)
            .hasMatch(id) ||
        id == '00000000-0000-0000-0000-000000000000' ||
        created == null ||
        updated == null ||
        updated.isBefore(created)) {
      throw const HandoffFailure(HandoffIssue.invalidResponse);
    }
    return Account._(id, created, updated);
  }

  static DateTime? _utc(Object? value) {
    if (value is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|\+00:00)$')
            .hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse(value);
    if (date == null ||
        date.year != int.parse(value.substring(0, 4)) ||
        date.month != int.parse(value.substring(5, 7)) ||
        date.day != int.parse(value.substring(8, 10)) ||
        date.hour != int.parse(value.substring(11, 13)) ||
        date.minute != int.parse(value.substring(14, 16)) ||
        date.second != int.parse(value.substring(17, 19))) {
      return null;
    }
    return date;
  }
}

class AccountRepository {
  const AccountRepository(this._api);
  final AndrilApiClient _api;

  Future<Account> loadOrInitialize(BackendSession session) async {
    try {
      return Account.fromJson(await _api.request(AccountEndpoint.me, session));
    } on HandoffFailure catch (failure) {
      if (failure.issue != HandoffIssue.accountNotInitialized) rethrow;
      return Account.fromJson(
          await _api.request(AccountEndpoint.initialize, session));
    }
  }
}
