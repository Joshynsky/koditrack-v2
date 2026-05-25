import 'package:flutter/material.dart';
import '../../theme/koditrack_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.apartment,
                  size: 64, color: kt.brandGreen.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('KodiTrack',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const Center(child: Text('Version 1.0.0')),
            const SizedBox(height: 24),
            const Text(
              'Property and rent management for Kenyan landlords. '
              'Track units, tenants, payments, and M-Pesa collections.',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Text('Backend: Supabase',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
