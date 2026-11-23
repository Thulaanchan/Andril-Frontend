import 'package:flutter/material.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chats_list_screen.dart';

/// Isolated M4 development preview entrypoint.
///
/// Does NOT touch or modify:
/// - `lib/main.dart`
/// - `lib/app/andril_app.dart`
/// - Existing production router
/// - Authentication and session boundaries
///
/// Execution command:
/// ```powershell
/// flutter run -t lib/features/common/chat/preview/main_chat_preview.dart
/// ```
///
/// Optional target module definition:
/// ```powershell
/// flutter run -t lib/features/common/chat/preview/main_chat_preview.dart --dart-define=MODULE=learning
/// flutter run -t lib/features/common/chat/preview/main_chat_preview.dart --dart-define=MODULE=hobbies
/// flutter run -t lib/features/common/chat/preview/main_chat_preview.dart --dart-define=MODULE=social
/// ```
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const moduleParam = String.fromEnvironment('MODULE', defaultValue: '');
  final config = switch (moduleParam.toLowerCase()) {
    'learning' => AndrilModuleConfig.learning,
    'hobbies' => AndrilModuleConfig.hobbies,
    'social' => AndrilModuleConfig.social,
    _ => null,
  };

  runApp(
    config != null
        ? AndrilM4DemoApp(moduleConfig: config)
        : const AndrilM4InteractivePreview(),
  );
}

/// Standalone M4 Chat Application Preview harness.
/// Supports running Learning, Hobbies, or Social independently based on the authenticated module context.
class AndrilM4DemoApp extends StatelessWidget {
  final AndrilModuleConfig moduleConfig;
  final bool startAtChatsList;

  const AndrilM4DemoApp({
    super.key,
    this.moduleConfig = AndrilModuleConfig.social,
    this.startAtChatsList = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = moduleConfig.theme;

    return MaterialApp(
      title: 'ANDRIL ${moduleConfig.name} Chat — M4 Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: theme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primary,
        ).copyWith(primary: theme.primary, surface: theme.background),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: theme.ink),
          bodyLarge: TextStyle(color: theme.ink),
        ),
      ),
      home: startAtChatsList
          ? AndrilChatsListScreen(moduleConfig: moduleConfig)
          : AndrilChatScreen(moduleConfig: moduleConfig),
    );
  }
}

/// Interactive launcher for local Android development and QA testing across all 3 modules.
class AndrilM4InteractivePreview extends StatefulWidget {
  const AndrilM4InteractivePreview({super.key});

  @override
  State<AndrilM4InteractivePreview> createState() =>
      _AndrilM4InteractivePreviewState();
}

class _AndrilM4InteractivePreviewState
    extends State<AndrilM4InteractivePreview> {
  AndrilModuleType _selectedModule = AndrilModuleType.social;
  bool _startAtChatsList = true;

  @override
  Widget build(BuildContext context) {
    final config = switch (_selectedModule) {
      AndrilModuleType.learning => AndrilModuleConfig.learning,
      AndrilModuleType.hobbies => AndrilModuleConfig.hobbies,
      AndrilModuleType.social => AndrilModuleConfig.social,
    };
    final theme = config.theme;

    return MaterialApp(
      title: 'ANDRIL M4 Three-Module Chat Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: theme.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: theme.primary,
        ).copyWith(primary: theme.primary, surface: theme.background),
      ),
      home: Scaffold(
        body: Column(
          children: [
            // Safe developer toolbar for switching modules in isolated preview
            Container(
              padding: const EdgeInsets.fromLTRB(12, 36, 12, 8),
              color: Colors.black87,
              child: Row(
                children: [
                  const Text(
                    'M4 PREVIEW:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final mod in AndrilModuleType.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: ChoiceChip(
                        key: Key('preview_chip_${mod.name}'),
                        label: Text(
                          mod.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _selectedModule == mod
                                ? Colors.white
                                : Colors.white70,
                          ),
                        ),
                        selected: _selectedModule == mod,
                        selectedColor: theme.primary,
                        backgroundColor: Colors.grey[800],
                        padding: EdgeInsets.zero,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedModule = mod);
                          }
                        },
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    key: const Key('preview_toggle_view'),
                    tooltip: _startAtChatsList
                        ? 'Switch to Direct Chat'
                        : 'Switch to Chats List',
                    icon: Icon(
                      _startAtChatsList ? Icons.chat : Icons.list,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _startAtChatsList = !_startAtChatsList);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _startAtChatsList
                  ? AndrilChatsListScreen(
                      key: ValueKey('list_${config.type.name}'),
                      moduleConfig: config,
                    )
                  : AndrilChatScreen(
                      key: ValueKey('chat_${config.type.name}'),
                      moduleConfig: config,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
