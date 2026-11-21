import 'package:flutter/material.dart';
import 'bootstrap/scaffold_home.dart';
import 'themes/learning/learning_theme.dart';

/// Technical bootstrapping and application root.
///
/// Preserves starter shell for default runs, while optionally accepting a
/// [RouterConfig] for modular navigation environments.
class AndrilApp extends StatelessWidget {
  /// Optional router configuration. When omitted, the starter shell is displayed.
  final RouterConfig<Object>? routerConfig;

  /// Creates an [AndrilApp].
  const AndrilApp({super.key, this.routerConfig});

  @override
  Widget build(BuildContext context) {
    if (routerConfig != null) {
      return MaterialApp.router(
        title: 'ANDRIL',
        debugShowCheckedModeBanner: false,
        theme: LearningTheme.theme,
        routerConfig: routerConfig,
      );
    }

    return MaterialApp(
      title: 'ANDRIL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF364B66)),
        useMaterial3: true,
      ),
      home: const ScaffoldHome(),
    );
  }
}
