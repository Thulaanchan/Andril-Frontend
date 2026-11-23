import 'package:flutter/material.dart';

/// Starter-only view. This does not activate or disclose module profiles.
class ScaffoldHome extends StatelessWidget {
  const ScaffoldHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ANDRIL')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/branding/andril_black_logo.png',
                    height: 90, semanticLabel: 'ANDRIL logo'),
                const SizedBox(height: 20),
                const Text('Flutter folder structure scaffold',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Learning  •  Hobbies  •  Social',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                const Text(
                    'Authentication foundation only. Product screens, '
                    'profiles, APIs and module access are not implemented.',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
