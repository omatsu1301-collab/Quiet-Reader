import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/work.dart';
import '../theme/app_theme.dart';
import 'work_screen.dart';
import 'data_transfer_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: Text(
          'Quiet Reader',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 1.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_outlined, color: AppColors.textSecondary),
            tooltip: 'データ転送',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DataTransferScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.add, color: AppColors.accent),
              tooltip: '作品を追加',
              onPressed: () => _showAddWorkDialog(context),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final works = provider.works;
          if (works.isEmpty) {
            return _EmptyLibrary(onAdd: () => _showAddWorkDialog(context));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: works.length,
            itemBuilder: (context, index) {
              return _WorkCard(work: works[index]);
            },
          );
        },
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.works.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showAddWorkDialog(context),
            tooltip: '作品を追加',
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddWorkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _AddWorkDialog(),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyLibrary({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 64, color: AppColors.textHint.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              '作品がまだありません',
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'PCで書いた文章を、ここで静かに読み返す\nあなただけの読書空間です',
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
              label: const Text('最初の作品を追加する'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  final Work work;
  const _WorkCard({required this.work});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WorkScreen(work: work)),
        ),
        onLongPress: () => _showWorkOptions(context),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.divider, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work.title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _DocumentCountBadge(workId: work.id),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _WorkOptionsSheet(work: work),
    );
  }
}

class _DocumentCountBadge extends StatelessWidget {
  final String workId;
  const _DocumentCountBadge({required this.workId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final docs = provider.getDocuments(workId);
    return Text(
      '${docs.length}件の文書',
      style: GoogleFonts.notoSans(
        fontSize: 12,
        color: AppColors.textHint,
      ),
    );
  }
}

class _AddWorkDialog extends StatefulWidget {
  const _AddWorkDialog();

  @override
  State<_AddWorkDialog> createState() => _AddWorkDialogState();
}

class _AddWorkDialogState extends State<_AddWorkDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        '新しい作品',
        style: GoogleFonts.notoSerif(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: '作品タイトルを入力',
          labelText: 'タイトル',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => _submit(context),
          child: const Text('作成'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    context.read<AppProvider>().createWork(title);
    Navigator.pop(context);
  }
}

class _WorkOptionsSheet extends StatelessWidget {
  final Work work;
  const _WorkOptionsSheet({required this.work});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              work.title,
              style: GoogleFonts.notoSerif(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
            title: const Text('タイトルを変更'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context);
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

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: work.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('タイトルを変更',
            style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'タイトル'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                ctx.read<AppProvider>().updateWork(work, t);
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
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
        title: Text('作品を削除',
            style: GoogleFonts.notoSerif(fontSize: 16, fontWeight: FontWeight.w600)),
        content: Text('「${work.title}」とすべての文書を削除します。\nこの操作は取り消せません。',
            style: GoogleFonts.notoSans(fontSize: 14, height: 1.6)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB85050)),
            onPressed: () {
              ctx.read<AppProvider>().deleteWork(work.id);
              Navigator.pop(ctx);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
