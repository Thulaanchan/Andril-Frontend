import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AuthFormField {
  email,
  password,
  passwordConfirmation,
  verificationCode;

  bool get isPassword => this == password || this == passwordConfirmation;
}

/// Fields and actions for isolated authentication compositions. Callers supply
/// copy, controller callbacks, and typed outcome messages. This widget owns
/// transient input only and does not own session state or navigation.
class OfflineAuthForm extends StatefulWidget {
  const OfflineAuthForm({
    super.key,
    this.fields = const {},
    required this.actionLabel,
    required this.busyLabel,
    required this.failureLabel,
    required this.onSubmit,
    this.passwordVisibilityLabels,
    this.status,
    this.enabled = true,
  });

  final Map<AuthFormField, String> fields;
  final String actionLabel;
  final String busyLabel;
  final String failureLabel;
  final Future<void> Function(Map<AuthFormField, String> input) onSubmit;
  final ({String show, String hide})? passwordVisibilityLabels;
  final String? status;
  final bool enabled;

  @override
  State<OfflineAuthForm> createState() => _OfflineAuthFormState();
}

class _OfflineAuthFormState extends State<OfflineAuthForm> {
  final _controllers = {
    for (final field in AuthFormField.values) field: TextEditingController(),
  };
  final _visible = <AuthFormField>{};
  bool _submitting = false;
  bool _failed = false;

  bool get _enabled => widget.enabled && !_submitting;

  Future<void> _submit() async {
    if (!_enabled) return;
    final input = Map<AuthFormField, String>.unmodifiable({
      for (final field in widget.fields.keys) field: _controllers[field]!.text,
    });
    setState(() {
      _submitting = true;
      _failed = false;
    });
    try {
      await widget.onSubmit(input);
    } catch (_) {
      // Unexpected callback failures get caller-supplied neutral copy.
      _failed = true;
    } finally {
      if (mounted) {
        for (final field in _controllers.keys.where((field) =>
            field.isPassword || field == AuthFormField.verificationCode)) {
          _controllers[field]!.clear();
        }
        setState(() {
          _visible.clear();
          _submitting = false;
        });
      }
    }
  }

  Widget _field(AuthFormField field, {required bool last}) {
    final password = field.isPassword;
    final code = field == AuthFormField.verificationCode;
    final visible = _visible.contains(field);
    final labels = widget.passwordVisibilityLabels;

    return TextField(
      key: ValueKey(field),
      controller: _controllers[field],
      enabled: _enabled,
      obscureText: password && !visible,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: code
          ? TextInputType.number
          : password
              ? TextInputType.visiblePassword
              : TextInputType.emailAddress,
      inputFormatters: code ? [FilteringTextInputFormatter.digitsOnly] : null,
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onSubmitted: last ? (_) => _submit() : null,
      decoration: InputDecoration(
        labelText: widget.fields[field],
        suffixIcon: password && labels != null
            ? IconButton(
                tooltip: visible ? labels.hide : labels.show,
                onPressed: _enabled
                    ? () => setState(() {
                          if (!_visible.remove(field)) _visible.add(field);
                        })
                    : null,
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _failed ? widget.failureLabel : widget.status;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final field in widget.fields.keys)
          _field(field, last: field == widget.fields.keys.last),
        FilledButton(
          onPressed: _enabled ? _submit : null,
          child: Text(_submitting ? widget.busyLabel : widget.actionLabel),
        ),
        if (status != null) Semantics(liveRegion: true, child: Text(status)),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant OfflineAuthForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final field in oldWidget.fields.keys) {
      if (!widget.fields.containsKey(field)) {
        _controllers[field]!.clear();
        _visible.remove(field);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
