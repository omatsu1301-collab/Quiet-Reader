import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';
import '../widgets/doc_type_badge.dart';
import 'document_edit_screen.dart';
import 'reader_screen.dart';

class WorkScreen extends StatelessWidget {
  final Work work;
  const WorkScreen({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: Text(work.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.accent),
              tooltip: '文書を追加',
              onPressed: () => _addDocument(context),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final docs = provider.getDocuments(work.id);
          if (docs.isEmpty) {
            return _EmptyWork(onAdd: () => _addDocument(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _DocumentCard(work: work, doc: docs[index]);
            },
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.getDocuments(work.id).isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _addDocument(context),
            tooltip: '文書を追加',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _addDocument(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentEditScreen(workId: work.id),
      ),
    );
  }
}

class _EmptyWork extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyWork({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined,
                size: 56, color: AppColors.textHint.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              '文書がまだありません',
              style: GoogleFonts.notoSerif(
                fontSize: 17,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PCで書いた本文やプロットを\nコピペして取り込みましょう',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                color: AppColors.textHint,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('文書を追加する'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Work work;
  final Document doc;
  const _DocumentCard({required this.work, required this.doc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openReader(context),
        onLongPress: () => _showDocOptions(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DocTypeBadge(type: doc.type, small: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            doc.title,
                            style: GoogleFonts.notoSerif(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        _BodyPreview(doc: doc),
                        const Spacer(),
                        if (doc.lastReadPosition > 0.01)
                          _ReadProgress(position: doc.lastReadPosition),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openReader(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(work: work, document: doc),
      ),
    );
  }

  void _showDocOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _DocOptionsSheet(work: work, doc: doc),
    );
  }
}

class _BodyPreview extends StatelessWidget {
  final Document doc;
  const _BodyPreview({required this.doc});

  @override
  Widget build(BuildContext context) {
    final charCount = doc.body.length;
    final preview = doc.body.replaceAll('\n', ' ').trim();
    final short = preview.length > 30 ? '${preview.substring(0, 30)}…' : preview;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            short.isEmpty ? '（本文なし）' : short,
            style: GoogleFonts.notoSans(
              fontSize: 12,
              color: AppColors.textHint,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$charCount字',
            style: GoogleFonts.notoSans(
              fontSize: 11,
              color: AppColors.textHint.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadProgress extends StatelessWidget {
  final double position;
  const _ReadProgress({required this.position});

  @override
  Widget build(BuildContext context) {
    final pct = (position * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$pct%',
        style: GoogleFonts.notoSans(
          fontSize: 11,
          color: AppColors.accent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DocOptionsSheet extends StatelessWidget {
  final Work work;
  final Document doc;
  const _DocOptionsSheet({required this.work, required this.doc});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                DocTypeBadge(type: doc.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    doc.title,
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined, color: AppColors.accent),
            title: const Text('読む'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReaderScreen(work: work, document: doc),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            title: const Text('編集'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentEditScreen(workId: work.id, document: doc),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Color(0xFFB85050)),
            title: const Text('削除', style: TextStyle(color: Color(0xFFB85050))),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('文書を削除',
            style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('「${doc.title}」を削除します。\nハイライトやメモも消えます。この操作は取り消せません。',
            style: GoogleFonts.notoSans(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB85050)),
            onPressed: () {
              ctx.read<AppProvider>().deleteDocument(doc.id);
              Navigator.pop(ctx);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
