import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_config.dart';
import '../core/network/api_client/andril_api_client.dart';
import '../core/security/session/session_controller.dart';
import '../shared_core/account/account_handoff_controller.dart';
import 'bootstrap/scaffold_home.dart';
import 'dependencies/supabase_bootstrap.dart';
import 'themes/learning/learning_theme.dart';

/// Hosts the starter scaffold or a caller-supplied router after auth startup.
class AndrilApp extends StatefulWidget {
  const AndrilApp({
    super.key,
    this.routerConfig,
    this.initialize = initializeAuthFoundation,
    this.createHandoff = _createAccountHandoff,
  });

  final RouterConfig<Object>? routerConfig;
  final Future<SessionController> Function() initialize;
  final AccountHandoffController? Function(SessionController) createHandoff;

  @override
  State<AndrilApp> createState() => _AndrilAppState();
}

class _AndrilAppState extends State<AndrilApp> {
  SessionController? _session;
  AccountHandoffController? _handoff;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = await widget.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      final AccountHandoffController? handoff;
      try {
        handoff = widget.createHandoff(controller);
      } catch (_) {
        controller.dispose();
        rethrow;
      }
      setState(() {
        _session = controller;
        _handoff = handoff;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ConfigurationException
          ? 'Authentication configuration required.'
          : 'Authentication setup unavailable.');
    }
  }

  @override
  void dispose() {
    _handoff?.dispose();
    _session?.dispose();
    super.dispose();
  }

  Widget _gate(BuildContext context, Widget? child) {
    if (_error case final error?) return _BootstrapMessage(error);
    return switch (context.watch<SessionController?>()?.phase) {
      null || SessionPhase.restoring => const _BootstrapMessage(null),
      SessionPhase.unavailable =>
        const _BootstrapMessage('Authentication session unavailable.'),
      SessionPhase.recovery => const _BootstrapMessage(
          'Password recovery requires the approved recovery flow.'),
      SessionPhase.signedIn ||
      SessionPhase.signedOut =>
        child ?? const _BootstrapMessage('Navigation unavailable.'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final routerConfig = widget.routerConfig;
    final Widget app;
    if (routerConfig == null) {
      app = MaterialApp(
        title: 'ANDRIL',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF364B66)),
          useMaterial3: true,
        ),
        home: const ScaffoldHome(),
        builder: _gate,
      );
    } else {
      app = MaterialApp.router(
        title: 'ANDRIL',
        debugShowCheckedModeBanner: false,
        theme: LearningTheme.theme,
        routerConfig: routerConfig,
        builder: _gate,
      );
    }
    return ChangeNotifierProvider<SessionController?>.value(
      value: _session,
      child: ChangeNotifierProvider<AccountHandoffController?>.value(
        value: _handoff,
        child: app,
      ),
    );
  }
}

AccountHandoffController? _createAccountHandoff(SessionController session) {
  if (!session.supportsBackend) return null;
  return AccountHandoffController(
      session, AndrilApiClient(AppConfig.fromEnvironment(), session));
}

class _BootstrapMessage extends StatelessWidget {
  const _BootstrapMessage(this.message);
  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ANDRIL')),
        body: Center(
          child: message == null
              ? const CircularProgressIndicator(
                  semanticsLabel: 'Restoring authentication')
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(message!, textAlign: TextAlign.center),
                ),
        ),
      );
}
