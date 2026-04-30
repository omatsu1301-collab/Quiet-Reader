import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ExportScreen extends StatefulWidget {
  final String workId;
  final String documentId;

  const ExportScreen({
    super.key,
    required this.workId,
    required this.documentId,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final text = provider.exportHighlightsAndMemos(widget.workId, widget.documentId);
    final highlights = provider.getHighlights(widget.documentId);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.ios_share_outlined,
                    size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'メモを書き出す',
                  style: GoogleFonts.notoSerif(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (highlights.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _copied
                        ? Row(
                            key: const ValueKey('copied'),
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 16, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                'コピーしました',
                                style: GoogleFonts.notoSans(
                                  fontSize: 13,
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        : TextButton.icon(
                            key: const ValueKey('copy'),
                            onPressed: () => _copy(text),
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('コピー'),
                          ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: highlights.isEmpty
                ? _EmptyExport()
                : ListView(
                    controller: ctrl,
                    children: [
                      // ─ ハイライト別プレビュー ─
                      _HighlightList(
                        provider: provider,
                        documentId: widget.documentId,
                      ),
                      const Divider(height: 32),
                      // ─ テキスト出力プレビュー ─
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '出力テキスト',
                              style: GoogleFonts.notoSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHint,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EBE2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: SelectableText(
                                text,
                                style: GoogleFonts.notoSans(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  height: 1.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          if (highlights.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _copy(text),
                    icon: Icon(
                      _copied ? Icons.check : Icons.copy,
                      size: 18,
                    ),
                    label: Text(_copied ? 'コピーしました！' : 'テキストをコピー'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _copied = false);
  }
}

class _EmptyExport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.highlight_outlined,
                size: 48, color: AppColors.textHint.withValues(alpha: 0.6)),
            const SizedBox(height: 20),
            Text(
              'ハイライトがまだありません',
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '読書中にテキストを長押しして\nハイライトを追加すると\nここに書き出せます',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppColors.textHint,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightList extends StatelessWidget {
  final AppProvider provider;
  final String documentId;

  const _HighlightList({
    required this.provider,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context) {
    final highlights = provider.getHighlights(documentId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ハイライト一覧 (${highlights.length}件)',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...highlights.map((h) {
            final memo = provider.getMemo(h.id);
            return _HighlightCard(
              highlight: h,
              memoContent: memo?.content,
              onDelete: () => provider.deleteHighlight(h.id),
              onMemoEdit: (content) => provider.saveMemo(h.id, content),
            );
          }),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final dynamic highlight;
  final String? memoContent;
  final VoidCallback onDelete;
  final void Function(String) onMemoEdit;

  const _HighlightCard({
    required this.highlight,
    required this.memoContent,
    required this.onDelete,
    required this.onMemoEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: HighlightColors.background(highlight.category)
                  .withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: HighlightColors.background(highlight.category),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    HighlightColors.label(highlight.category),
                    style: GoogleFonts.notoSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: HighlightColors.labelColor(highlight.category),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_note, size: 18,
                      color: AppColors.textHint),
                  onPressed: () => _showMemoEdit(context),
                  tooltip: 'メモを編集',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18,
                      color: AppColors.textHint),
                  onPressed: onDelete,
                  tooltip: 'ハイライトを削除',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
          // ハイライトテキスト
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Text(
              '「${highlight.text}」',
              style: GoogleFonts.notoSerif(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.7,
              ),
            ),
          ),
          // メモ
          if (memoContent != null && memoContent!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      memoContent!,
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: GestureDetector(
                onTap: () => _showMemoEdit(context),
                child: Text(
                  '+ メモを追加',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMemoEdit(BuildContext context) {
    final controller = TextEditingController(text: memoContent ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'メモを編集',
          style: GoogleFonts.notoSerif(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: HighlightColors.background(highlight.category)
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '「${highlight.text.length > 40 ? '${highlight.text.substring(0, 40)}…' : highlight.text}」',
                style: GoogleFonts.notoSerif(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'メモを入力してください',
                labelText: 'メモ',
              ),
              style: GoogleFonts.notoSans(fontSize: 14, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              onMemoEdit(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
