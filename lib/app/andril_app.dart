import 'package:flutter/material.dart';
import 'bootstrap/scaffold_home.dart';

/// Technical bootstrapping only. Product screens and module authorization
/// are not implemented in this scaffold.
class AndrilApp extends StatelessWidget {
  const AndrilApp({super.key});

  @override
  Widget build(BuildContext context) {
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
