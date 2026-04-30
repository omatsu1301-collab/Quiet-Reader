import 'package:hive/hive.dart';

part 'reader_settings.g.dart';

@HiveType(typeId: 5)
class ReaderSettings extends HiveObject {
  @HiveField(0)
  String fontFamily; // 'serif', 'sans-serif'

  @HiveField(1)
  double fontSize;

  @HiveField(2)
  double lineHeight;

  @HiveField(3)
  double horizontalPadding;

  @HiveField(4)
  double contentWidth; // 0.0〜1.0 (画面幅に対する比率)

  @HiveField(5)
  double backgroundTone; // 0.0=明るい 〜 1.0=濃いクリーム

  ReaderSettings({
    this.fontFamily = 'serif',
    this.fontSize = 17.0,
    this.lineHeight = 1.9,
    this.horizontalPadding = 24.0,
    this.contentWidth = 0.88,
    this.backgroundTone = 0.5,
  });

  ReaderSettings copyWith({
    String? fontFamily,
    double? fontSize,
    double? lineHeight,
    double? horizontalPadding,
    double? contentWidth,
    double? backgroundTone,
  }) {
    return ReaderSettings(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      contentWidth: contentWidth ?? this.contentWidth,
      backgroundTone: backgroundTone ?? this.backgroundTone,
    );
  }
}
