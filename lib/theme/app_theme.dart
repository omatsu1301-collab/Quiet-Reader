import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // クリーム背景トーン（backgroundTone 0.0〜1.0 で補間）
  static Color background(double tone) {
    // 0.0: #FAF8F4 (明るい) 〜 1.0: #EDE5D6 (濃いクリーム)
    return Color.lerp(
      const Color(0xFFFAF8F4),
      const Color(0xFFEDE5D6),
      tone,
    )!;
  }

  // 既定背景
  static const Color bgDefault = Color(0xFFF5F0E8);
  // 墨色テキスト（真っ黒でなく柔らかい）
  static const Color textPrimary = Color(0xFF2C2820);
  // サブテキスト
  static const Color textSecondary = Color(0xFF7A6E60);
  // 薄いテキスト
  static const Color textHint = Color(0xFFB0A898);
  // 区切り線
  static const Color divider = Color(0xFFDDD5C8);
  // カード背景
  static const Color cardBg = Color(0xFFFBF8F2);
  // アクセントカラー（温かい茶系）
  static const Color accent = Color(0xFF8B6F47);
  // アクセント薄色
  static const Color accentLight = Color(0xFFD4B896);
  // ハイライト色
  static const Color highlightGood = Color(0xFFD4E8C2);   // 良表現：やわらか緑
  static const Color highlightFix = Color(0xFFF5D0C8);    // 違和感：やわらかサーモン
  static const Color highlightCheck = Color(0xFFFBEAB8);  // 要確認：やわらか黄
  // オーバーレイ
  static const Color overlay = Color(0x88000000);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accentLight,
        surface: AppColors.bgDefault,
        onSurface: AppColors.textPrimary,
        outline: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.bgDefault,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDefault,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        titleTextStyle: GoogleFonts.notoSerif(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.8,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.divider, width: 0.8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accent),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: GoogleFonts.notoSansTextTheme().copyWith(
        bodyLarge: GoogleFonts.notoSans(color: AppColors.textPrimary, fontSize: 15),
        bodyMedium: GoogleFonts.notoSans(color: AppColors.textPrimary, fontSize: 14),
        bodySmall: GoogleFonts.notoSans(color: AppColors.textSecondary, fontSize: 12),
        titleLarge: GoogleFonts.notoSerif(
          color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.notoSerif(
          color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.notoSerif(
          color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  // 読書画面用テキストスタイル
  static TextStyle readerTextStyle({
    required String fontFamily,
    required double fontSize,
    required double lineHeight,
    Color? color,
  }) {
    final c = color ?? AppColors.textPrimary;
    if (fontFamily == 'serif') {
      return GoogleFonts.notoSerif(
        fontSize: fontSize,
        height: lineHeight,
        color: c,
        letterSpacing: 0.3,
      );
    } else {
      return GoogleFonts.notoSans(
        fontSize: fontSize,
        height: lineHeight,
        color: c,
        letterSpacing: 0.2,
      );
    }
  }
}

// 文書種別の定数
class DocTypes {
  static const List<String> all = ['本文', '初稿', '推敲稿', 'プロット', 'キャラシート', 'その他'];

  static Color badgeColor(String type) {
    switch (type) {
      case '本文': return const Color(0xFFD4E8C2);
      case '初稿': return const Color(0xFFDDE8F5);
      case '推敲稿': return const Color(0xFFE8DDF5);
      case 'プロット': return const Color(0xFFF5ECD4);
      case 'キャラシート': return const Color(0xFFF5D4D4);
      default: return const Color(0xFFE8E4DC);
    }
  }

  static Color badgeTextColor(String type) {
    switch (type) {
      case '本文': return const Color(0xFF3A6B28);
      case '初稿': return const Color(0xFF2A4E7A);
      case '推敲稿': return const Color(0xFF4E2A7A);
      case 'プロット': return const Color(0xFF7A5A1A);
      case 'キャラシート': return const Color(0xFF7A2A2A);
      default: return const Color(0xFF5A5048);
    }
  }
}

// ハイライト色ユーティリティ
class HighlightColors {
  static Color background(String category) {
    switch (category) {
      case 'good': return AppColors.highlightGood;
      case 'fix': return AppColors.highlightFix;
      case 'check': return AppColors.highlightCheck;
      default: return AppColors.highlightCheck;
    }
  }

  static String label(String category) {
    switch (category) {
      case 'good': return '良表現';
      case 'fix': return '違和感';
      case 'check': return '要確認';
      default: return category;
    }
  }

  static Color labelColor(String category) {
    switch (category) {
      case 'good': return const Color(0xFF3A6B28);
      case 'fix': return const Color(0xFF8B3A2A);
      case 'check': return const Color(0xFF7A6010);
      default: return AppColors.textSecondary;
    }
  }
}
