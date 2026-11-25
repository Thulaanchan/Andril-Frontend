import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/module_config.dart';
import '../presentation/navigation/chat_navigation_contract.dart';
import '../presentation/screens/andril_chat_screen.dart';
import '../presentation/screens/andril_chats_list_screen.dart';

/// Screen displayed when chat navigation is rejected due to policy violations,
/// module mismatches, invalid conversation IDs, or unauthorized routes.
class ChatRouteDeniedScreen extends StatelessWidget {
  final String reason;
  final VoidCallback? onReturn;

  const ChatRouteDeniedScreen({
    super.key,
    required this.reason,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('chat_route_denied_screen'),
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Access Restricted'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Color(0xFFEF4444),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Chat Navigation Restricted',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('return_to_preview_button'),
                          onPressed: () {
                            if (onReturn != null) {
                              onReturn!();
                            } else if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(ChatNavigationParams.listPath(
                                  AndrilModuleType.learning));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Return to Preview'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Creates an isolated M4 GoRouter instance for technical preview and testing.
///
/// This router is strictly isolated to M4 Chat navigation and does NOT claim or
/// bypass production authentication, onboarding, or module activation gates.
GoRouter createChatPreviewRouter({
  String initialLocation = '/preview/chat/learning',
  List<NavigatorObserver>? observers,
  Map<String, List<String>>? allowedConversations,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    observers: observers,
    routes: [
      GoRoute(
        path: '/preview/chat/denied',
        name: 'chat-preview-denied',
        builder: (context, state) {
          final reason = state.uri.queryParameters['reason'] ??
              'Navigation request denied.';
          return ChatRouteDeniedScreen(reason: reason);
        },
      ),
      GoRoute(
        path: '/preview/chat/:module',
        name: 'chat-preview-list',
        builder: (context, state) {
          final rawModule = state.pathParameters['module'];
          final moduleType =
              ChatNavigationParams.parseModuleType(rawModule ?? '');
          if (moduleType == null) {
            return ChatRouteDeniedScreen(
              reason: 'Unsupported module: "$rawModule".',
            );
          }

          final config = _resolveConfig(moduleType);
          return AndrilChatsListScreen(
            key: ValueKey('preview_chats_list_${moduleType.name}'),
            moduleConfig: config,
            onOpenConversation: (item) {
              context.go(
                ChatNavigationParams.detailPath(moduleType, item.id),
                extra: item.partner,
              );
            },
          );
        },
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'chat-preview-detail',
            builder: (context, state) {
              final rawModule = state.pathParameters['module'];
              final conversationId = state.pathParameters['conversationId'];
              final partnerExtra = state.extra is AndrilModuleProfile
                  ? state.extra as AndrilModuleProfile
                  : null;

              final validation = ChatNavigationParams.validate(
                rawModule: rawModule,
                conversationId: conversationId,
                partner: partnerExtra,
                allowedConversationsByModule: allowedConversations ??
                    MockConversationCatalog.previewAllowedConversations,
              );

              if (!validation.isValid) {
                return ChatRouteDeniedScreen(
                  reason: validation.denialReason ??
                      'Invalid chat navigation parameters.',
                );
              }

              final params = validation.params!;
              final partner = partnerExtra ??
                  MockConversationCatalog.defaultPartnerFor(
                    params.moduleType,
                    params.conversationId,
                  );

              if (partner == null) {
                return ChatRouteDeniedScreen(
                  reason:
                      'No matching partner profile available for conversation "${params.conversationId}".',
                );
              }

              return AndrilChatScreen(
                key: ValueKey(
                    'preview_chat_${params.moduleType.name}_${params.conversationId}'),
                moduleConfig: params.moduleConfig,
                partner: partner,
                conversationId: params.conversationId,
                onBackPressed: () {
                  context.go(ChatNavigationParams.listPath(params.moduleType));
                },
              );
            },
          ),
        ],
      ),
    ],
  );
}

AndrilModuleConfig _resolveConfig(AndrilModuleType type) {
  switch (type) {
    case AndrilModuleType.learning:
      return AndrilModuleConfig.learning;
    case AndrilModuleType.hobbies:
      return AndrilModuleConfig.hobbies;
    case AndrilModuleType.social:
      return AndrilModuleConfig.social;
  }
}

/// Standalone preview test app for M4 GoRouter navigation verification.
class MainAppChatRoutePreviewApp extends StatelessWidget {
  final GoRouter? router;
  final String initialLocation;
  final TransitionBuilder? builder;

  const MainAppChatRoutePreviewApp({
    super.key,
    this.router,
    this.initialLocation = '/preview/chat/learning',
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRouter =
        router ?? createChatPreviewRouter(initialLocation: initialLocation);
    return MaterialApp.router(
      title: 'ANDRIL M4 Chat Route Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E293B),
        ),
      ),
      routerConfig: effectiveRouter,
      builder: builder,
    );
  }
}
