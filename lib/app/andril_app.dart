import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_config.dart';
import '../core/security/session/session_controller.dart';
import 'bootstrap/scaffold_home.dart';
import 'dependencies/supabase_bootstrap.dart';

/// Technical bootstrapping only. Product screens and module authorization
/// are not implemented in this scaffold.
class AndrilApp extends StatefulWidget {
  const AndrilApp({super.key, this.initialize = initializeAuthFoundation});

  final Future<SessionController> Function() initialize;

  @override
  State<AndrilApp> createState() => _AndrilAppState();
}

class _AndrilAppState extends State<AndrilApp> {
  SessionController? _session;
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
      setState(() => _session = controller);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is ConfigurationException
          ? 'Authentication configuration required.'
          : 'Authentication setup unavailable.');
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final home = _error != null
        ? _BootstrapMessage(_error!)
        : session == null
            ? const _BootstrapMessage(null)
            : Consumer<SessionController>(
                builder: (context, state, child) => switch (state.phase) {
                  SessionPhase.restoring => const _BootstrapMessage(null),
                  SessionPhase.unavailable => const _BootstrapMessage(
                      'Authentication session unavailable.'),
                  SessionPhase.recovery => const _BootstrapMessage(
                      'Password recovery requires the approved recovery flow.'),
                  SessionPhase.signedIn ||
                  SessionPhase.signedOut =>
                    const ScaffoldHome(),
                },
              );
    final app = MaterialApp(
      title: 'ANDRIL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF364B66)),
        useMaterial3: true,
      ),
      home: home,
    );
    return session == null
        ? app
        : ChangeNotifierProvider.value(value: session, child: app);
  }
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
