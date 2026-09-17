import 'package:flutter/material.dart';

class HologramVideoModule extends StatelessWidget {
  final bool isSpeaking;

  const HologramVideoModule({super.key, required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        border: Border.all(color: const Color(0xFF00FFFF), width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSpeaking ? Icons.surround_sound : Icons.play_circle_filled,
              size: 56,
              color: const Color(0xFF00FFFF),
            ),
            const SizedBox(height: 12),
            Text(
              isSpeaking ? "GENEVIEW // Szinkronizált beszéd..." : "Holographic Idle Engine\n(GPU Accelerated)",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}