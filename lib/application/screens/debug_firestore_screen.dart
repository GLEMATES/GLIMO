import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';

class DebugFirestoreScreen extends StatefulWidget {
  const DebugFirestoreScreen({super.key});

  @override
  State<DebugFirestoreScreen> createState() => _DebugFirestoreScreenState();
}

class _DebugFirestoreScreenState extends State<DebugFirestoreScreen> {
  late Future<String> _debugInfo;

  @override
  void initState() {
    super.initState();
    _debugInfo = _fetchFirestoreStructure();
  }

  Future<String> _fetchFirestoreStructure() async {
    final firestore = FirebaseFirestore.instance;
    StringBuffer buffer = StringBuffer();

    try {
      // Check buku_servis collection
      buffer.writeln('=== COLLECTION: buku_servis ===\n');
      final bukuServisSnapshot = await firestore.collection('buku_servis').get();
      buffer.writeln('Total Documents: ${bukuServisSnapshot.docs.length}\n');

      for (var doc in bukuServisSnapshot.docs) {
        buffer.writeln('Document ID: ${doc.id}');
        buffer.writeln('Data: ${doc.data()}');
        buffer.writeln('Keys: ${doc.data().keys.toList()}');
        buffer.writeln('---');
      }

      // Check motors collection
      buffer.writeln('\n=== COLLECTION: motors ===\n');
      final motorsSnapshot = await firestore.collection('motors').get();
      buffer.writeln('Total Documents: ${motorsSnapshot.docs.length}\n');

      for (var doc in motorsSnapshot.docs.take(3)) {
        buffer.writeln('Document ID: ${doc.id}');
        buffer.writeln('Data: ${doc.data()}');
        buffer.writeln('---');
      }

      return buffer.toString();
    } catch (e) {
      return 'Error: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Firestore'),
        backgroundColor: AppColors.normalHover,
      ),
      body: FutureBuilder<String>(
        future: _debugInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: SelectableText(
              snapshot.data ?? 'No data',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }
}
