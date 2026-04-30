import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reader_settings.dart';
import '../theme/app_theme.dart';

class SettingsPanel extends StatefulWidget {
  final ReaderSettings settings;
  final void Function(ReaderSettings) onChanged;

  const SettingsPanel({super.key, required this.settings, required this.onChanged});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late ReaderSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.settings.copyWith();
  }

  void _update(ReaderSettings updated) {
    setState(() => _current = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '表示設定',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetDefaults,
                  child: Text(
                    'デフォルトに戻す',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // ── フォント ──
                _SectionTitle('フォント'),
                _FontSelector(
                  current: _current.fontFamily,
                  onChanged: (v) => _update(_current.copyWith(fontFamily: v)),
                ),
                const SizedBox(height: 20),

                // ── 文字サイズ ──
                _SectionTitle('文字サイズ', value: '${_current.fontSize.toStringAsFixed(0)}pt'),
                _SliderRow(
                  value: _current.fontSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  onChanged: (v) => _update(_current.copyWith(fontSize: v)),
                  leftLabel: '小',
                  rightLabel: '大',
                ),
                const SizedBox(height: 20),

                // ── 行間 ──
                _SectionTitle('行間', value: _current.lineHeight.toStringAsFixed(1)),
                _SliderRow(
                  value: _current.lineHeight,
                  min: 1.4,
                  max: 2.6,
                  divisions: 12,
                  onChanged: (v) => _update(_current.copyWith(lineHeight: v)),
                  leftLabel: '狭い',
                  rightLabel: '広い',
                ),
                const SizedBox(height: 20),

                // ── 本文幅 ──
                _SectionTitle('本文幅', value: '${(_current.contentWidth * 100).toStringAsFixed(0)}%'),
                _SliderRow(
                  value: _current.contentWidth,
                  min: 0.55,
                  max: 0.98,
                  divisions: 13,
                  onChanged: (v) => _update(_current.copyWith(contentWidth: v)),
                  leftLabel: '細い',
                  rightLabel: '広い',
                ),
                const SizedBox(height: 20),

                // ── 余白 ──
                _SectionTitle('左右余白', value: '${_current.horizontalPadding.toStringAsFixed(0)}px'),
                _SliderRow(
                  value: _current.horizontalPadding,
                  min: 12,
                  max: 48,
                  divisions: 9,
                  onChanged: (v) => _update(_current.copyWith(horizontalPadding: v)),
                  leftLabel: '少ない',
                  rightLabel: '多い',
                ),
                const SizedBox(height: 20),

                // ── 背景色 ──
                _SectionTitle('背景の濃淡'),
                _BackgroundToneSelector(
                  current: _current.backgroundTone,
                  onChanged: (v) => _update(_current.copyWith(backgroundTone: v)),
                ),
                const SizedBox(height: 32),

                // ── プレビュー ──
                _PreviewBox(settings: _current),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _resetDefaults() {
    final defaults = ReaderSettings();
    _update(defaults);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? value;
  const _SectionTitle(this.title, {this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (value != null) ...[
            const Spacer(),
            Text(
              value!,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppColors.accent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String rightLabel;

  const _SliderRow({
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(leftLabel, style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textHint)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(rightLabel, style: GoogleFonts.notoSans(fontSize: 11, color: AppColors.textHint)),
      ],
    );
  }
}

class _FontSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;

  const _FontSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FontBtn(
          label: '明朝体',
          subtitle: 'Noto Serif',
          value: 'serif',
          current: current,
          onChanged: onChanged,
        ),
        const SizedBox(width: 12),
        _FontBtn(
          label: 'ゴシック体',
          subtitle: 'Noto Sans',
          value: 'sans-serif',
          current: current,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FontBtn extends StatelessWidget {
  final String label;
  final String subtitle;
  final String value;
  final String current;
  final ValueChanged<String> onChanged;

  const _FontBtn({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.divider,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            children: [
              Text(
                value == 'serif' ? '明朝体' : 'ゴシック',
                style: value == 'serif'
                    ? GoogleFonts.notoSerif(
                        fontSize: 18,
                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )
                    : GoogleFonts.notoSans(
                        fontSize: 18,
                        color: isSelected ? AppColors.accent : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 11,
                  color: isSelected ? AppColors.accent : AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundToneSelector extends StatelessWidget {
  final double current;
  final ValueChanged<double> onChanged;

  const _BackgroundToneSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final tones = [0.0, 0.25, 0.5, 0.75, 1.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: tones.map((t) {
        final isSelected = (current - t).abs() < 0.1;
        return GestureDetector(
          onTap: () => onChanged(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background(t),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.divider,
                width: isSelected ? 2.0 : 0.8,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: AppColors.accent)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  final ReaderSettings settings;
  const _PreviewBox({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'プレビュー',
          style: GoogleFonts.notoSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(settings.horizontalPadding * 0.6),
          decoration: BoxDecoration(
            color: AppColors.background(settings.backgroundTone),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            'いつもの静けさの中に、彼女の声だけが残っていた。\n窓の外では、細い雨が地面を濡らしながら、どこかへ流れていく。',
            style: AppTheme.readerTextStyle(
              fontFamily: settings.fontFamily,
              fontSize: settings.fontSize * 0.85,
              lineHeight: settings.lineHeight,
            ),
          ),
        ),
      ],
    );
  }
}
