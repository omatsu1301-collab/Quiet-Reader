import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/document.dart';
import '../theme/app_theme.dart';

class DocumentEditScreen extends StatefulWidget {
  final String workId;
  final Document? document; // nullなら新規作成

  const DocumentEditScreen({super.key, required this.workId, this.document});

  @override
  State<DocumentEditScreen> createState() => _DocumentEditScreenState();
}

class _DocumentEditScreenState extends State<DocumentEditScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = '本文';
  bool _isSaving = false;

  bool get _isEditing => widget.document != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.document!.title;
      _bodyController.text = widget.document!.body;
      _selectedType = widget.document!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: Text(_isEditing ? '文書を編集' : '文書を追加'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: Text(
                '保存',
                style: GoogleFonts.notoSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _isSaving ? AppColors.textHint : AppColors.accent,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // タイトル
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '文書タイトル',
                        hintText: '例：本文 第1章 ／ プロット v2',
                      ),
                      textInputAction: TextInputAction.next,
                      style: GoogleFonts.notoSerif(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 文書種別選択
                    Text(
                      '文書種別',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _TypeSelector(
                      selected: _selectedType,
                      onChanged: (t) => setState(() => _selectedType = t),
                    ),
                    const SizedBox(height: 20),

                    // 本文入力欄
                    Text(
                      '本文',
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _BodyHint(),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _bodyController,
                        maxLines: null,
                        minLines: 16,
                        keyboardType: TextInputType.multiline,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          height: 1.8,
                        ),
                        decoration: InputDecoration(
                          hintText: 'PCで書いた本文をここにコピペしてください\n\n改行・段落はそのまま保持されます',
                          hintStyle: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: AppColors.textHint,
                            height: 1.8,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                          filled: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // 保存ボタン（フッター）
            _SaveFooter(isSaving: _isSaving, onSave: _save),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('タイトルを入力してください'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final provider = context.read<AppProvider>();

    if (_isEditing) {
      await provider.updateDocument(
        widget.document!,
        title: title,
        type: _selectedType,
        body: body,
      );
    } else {
      await provider.createDocument(
        workId: widget.workId,
        title: title,
        type: _selectedType,
        body: body,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _TypeSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DocTypes.all.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? DocTypes.badgeColor(type)
                  : AppColors.cardBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? DocTypes.badgeTextColor(type).withValues(alpha: 0.4)
                    : AppColors.divider,
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Text(
              type,
              style: GoogleFonts.notoSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? DocTypes.badgeTextColor(type)
                    : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BodyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PCからコピーしてそのまま貼り付けできます。改行・段落は維持されます。',
              style: GoogleFonts.notoSans(
                fontSize: 12,
                color: AppColors.accent,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveFooter extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onSave;

  const _SaveFooter({required this.isSaving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bgDefault,
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.8)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSaving ? null : onSave,
          child: isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('保存する'),
        ),
      ),
    );
  }
}
