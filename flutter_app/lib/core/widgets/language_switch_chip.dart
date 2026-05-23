import 'package:flutter/material.dart';
import '../services/locale_service.dart';

class LanguageSwitchChip extends StatelessWidget {
  const LanguageSwitchChip({super.key});

  bool _isArabic(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isArabic(context);

    return Material(
      color: Colors.white.withOpacity(0.94),
      elevation: 4,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFD6E7D6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, 'EN', !isAr, const Locale('en')),
            _buildOption(context, 'AR', isAr, const Locale('ar')),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String label, bool active, Locale locale) {
    return GestureDetector(
      onTap: () => LocaleService.setLocale(locale),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00897B) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF00897B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
