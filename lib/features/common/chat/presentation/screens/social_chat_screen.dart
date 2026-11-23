import 'package:flutter/material.dart';
import 'package:andril_mobile/features/common/chat/domain/module_config.dart';
import 'package:andril_mobile/features/common/chat/presentation/screens/andril_chat_screen.dart';

export 'andril_chat_screen.dart';

/// Backwards-compatible SocialChatScreen entrypoint.
/// Delegates to the unified [AndrilChatScreen] configured with [AndrilModuleConfig.social].
class SocialChatScreen extends StatelessWidget {
  final int initialBalance;
  const SocialChatScreen({super.key, this.initialBalance = 40});

  @override
  Widget build(BuildContext context) {
    return AndrilChatScreen(
      moduleConfig: AndrilModuleConfig.social,
      initialBalance: initialBalance,
    );
  }
}
