import 'package:flutter/material.dart';

enum CatMood { happy, sad, excited, tired, neutral }

class CuteCatMascot extends StatelessWidget {
  final CatMood mood;

  const CuteCatMascot({
    super.key,
    this.mood = CatMood.happy, // Default Happy
  });

  @override
  Widget build(BuildContext context) {
    // Tentukan path gambar berdasarkan mood
    String imagePath;
    switch (mood) {
      case CatMood.sad:
        imagePath = 'sadcat.png';
        break;
      case CatMood.tired:
        imagePath = 'cattired.png';
        break;
      case CatMood.excited:
        imagePath = 'excitedcat.png';
        break;
      case CatMood.neutral:
        imagePath = 'cat.png';
        break;
      case CatMood.happy:
      default:
        imagePath = 'happycat.png';
        break;
    }

    // ANIMASI SMOOTH
    return SizedBox(
      width: 90, // UKURAN DIPERBESAR (sebelumnya 60)
      height: 90,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500), // Durasi animasi
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Efek Scale (Membal) + Fade biar cute
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        // PENTING: Key harus berubah biar animasi jalan
        child: Image.asset(
          'assets/$imagePath',
          key: ValueKey<String>(imagePath), 
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD1DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.pets, color: Colors.white),
            );
          },
        ),
      ),
    );
  }
}
