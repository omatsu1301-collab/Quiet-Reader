import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../theme/app_theme.dart';

import 'settings_panel.dart';
import 'related_docs_sheet.dart';
import 'export_screen.dart';

class ReaderScreen extends StatefulWidget {
  final Work work;
  final Document document;

  const ReaderScreen({super.key, required this.work, required this.document});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _menuVisible = false;


  // ハイライト関連
  int? _selStart;
  int? _selEnd;
  String _selText = '';
  bool _showHighlightToolbar = false;

  // 章ジャンプ用
  List<_Chapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restorePosition();
      _parseChapters();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _parseChapters() {
    _chapters = _detectChapters(widget.document.body);
    setState(() {});
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final pos = _scrollController.offset / max;
    // 読書位置を定期保存（1%ごと）
    final rounded = (pos * 100).round() / 100;
    context.read<AppProvider>().saveReadPosition(widget.document.id, rounded.clamp(0.0, 1.0));
  }

  void _restorePosition() {
    final pos = widget.document.lastReadPosition;
    if (pos <= 0.01) return;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo((pos * max).clamp(0, max));
      if (mounted) setState(() {});
    });
  }

  void _toggleMenu() {
    setState(() {
      _menuVisible = !_menuVisible;
      _showHighlightToolbar = false;
    });
  }

  void _hideMenu() {
    if (_menuVisible) setState(() => _menuVisible = false);
  }

  double get _currentPosition {
    if (!_scrollController.hasClients) return 0;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scrollController.offset / max).clamp(0.0, 1.0);
  }

  void _scrollToChapter(_Chapter chapter) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      (chapter.position * max).clamp(0, max),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToBookmark(Bookmark bookmark) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      (bookmark.position * max).clamp(0, max),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final settings = provider.settings;
    final highlights = provider.getHighlights(widget.document.id);

    final bgColor = AppColors.background(settings.backgroundTone);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: bgColor,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        body: GestureDetector(
          onTap: _toggleMenu,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── メイン読書エリア ──
              _ReaderBody(
                document: widget.document,
                settings: settings,
                highlights: highlights,
                scrollController: _scrollController,
                bgColor: bgColor,
                onSelectionChanged: (start, end, text) {
                  setState(() {
                    _selStart = start;
                    _selEnd = end;
                    _selText = text;
                    _showHighlightToolbar = text.isNotEmpty;
                    _menuVisible = false;
                  });
                },
              ),

              // ── 上部ナビゲーション（タップ時のみ表示）──
              AnimatedSlide(
                offset: _menuVisible ? Offset.zero : const Offset(0, -1),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: AnimatedOpacity(
                  opacity: _menuVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: _TopBar(
                    work: widget.work,
                    document: widget.document,
                    bgColor: bgColor,
                    onClose: _hideMenu,
                    onSettings: () {
                      _hideMenu();
                      _showSettings();
                    },
                  ),
                ),
              ),

              // ── 下部メニューバー（タップ時のみ表示）──
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: AnimatedSlide(
                  offset: _menuVisible ? Offset.zero : const Offset(0, 1),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _menuVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: _BottomMenuBar(
                      bgColor: bgColor,
                      onBookmark: _addBookmark,
                      onChapters: _showChapters,
                      onRelated: _showRelated,
                      onExport: _showExport,
                      currentPosition: _currentPosition,
                    ),
                  ),
                ),
              ),

              // ── ハイライトツールバー ──
              if (_showHighlightToolbar && _selStart != null && _selEnd != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 60,
                  left: 0, right: 0,
                  child: _HighlightToolbar(
                    text: _selText,
                    onSelect: (category) {
                      _addHighlight(category);
                      setState(() => _showHighlightToolbar = false);
                    },
                    onDismiss: () => setState(() => _showHighlightToolbar = false),
                  ),
                ),

              // ── 進捗インジケーター ──
              Positioned(
                top: 0, right: 0,
                child: SafeArea(
                  child: AnimatedOpacity(
                    opacity: _menuVisible ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: _ProgressDot(position: _currentPosition),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBookmark() async {
    final pos = _currentPosition;
    final provider = context.read<AppProvider>();
    await provider.addBookmark(widget.document.id, pos);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.bookmark_added, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('しおりを追加しました（${(pos * 100).toStringAsFixed(0)}%）'),
        ]),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _addHighlight(String category) {
    if (_selStart == null || _selEnd == null || _selText.isEmpty) return;
    context.read<AppProvider>().addHighlight(
      documentId: widget.document.id,
      startOffset: _selStart!,
      endOffset: _selEnd!,
      text: _selText,
      category: category,
    );
    setState(() {
      _selStart = null;
      _selEnd = null;
      _selText = '';
    });
  }

  void _showChapters() {
    _hideMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChaptersSheet(
        chapters: _chapters,
        bookmarks: context.read<AppProvider>().getBookmarks(widget.document.id),
        onChapterTap: _scrollToChapter,
        onBookmarkTap: _scrollToBookmark,
        onBookmarkDelete: (id) => context.read<AppProvider>().deleteBookmark(id),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SettingsPanel(
        settings: context.read<AppProvider>().settings,
        onChanged: (s) => context.read<AppProvider>().updateSettings(s),
      ),
    );
  }

  void _showRelated() {
    _hideMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => RelatedDocsSheet(
        work: widget.work,
        currentDocId: widget.document.id,
      ),
    );
  }

  void _showExport() {
    _hideMenu();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ExportScreen(
        workId: widget.work.id,
        documentId: widget.document.id,
      ),
    );
  }
}

// ── 読書本文ウィジェット ──
class _ReaderBody extends StatefulWidget {
  final Document document;
  final dynamic settings;
  final List<Highlight> highlights;
  final ScrollController scrollController;
  final Color bgColor;
  final void Function(int start, int end, String text) onSelectionChanged;

  const _ReaderBody({
    required this.document,
    required this.settings,
    required this.highlights,
    required this.scrollController,
    required this.bgColor,
    required this.onSelectionChanged,
  });

  @override
  State<_ReaderBody> createState() => _ReaderBodyState();
}

class _ReaderBodyState extends State<_ReaderBody> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * settings.contentWidth;
    final hPad = settings.horizontalPadding;

    return SingleChildScrollView(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth.clamp(300, 680)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              MediaQuery.of(context).padding.top + 56,
              hPad,
              MediaQuery.of(context).padding.bottom + 80,
            ),
            child: _HighlightedText(
              body: widget.document.body,
              highlights: widget.highlights,
              settings: settings,
              onSelectionChanged: widget.onSelectionChanged,
            ),
          ),
        ),
      ),
    );
  }
}

// ── ハイライト付きテキスト表示 ──
class _HighlightedText extends StatefulWidget {
  final String body;
  final List<Highlight> highlights;
  final dynamic settings;
  final void Function(int start, int end, String text) onSelectionChanged;

  const _HighlightedText({
    required this.body,
    required this.highlights,
    required this.settings,
    required this.onSelectionChanged,
  });

  @override
  State<_HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<_HighlightedText> {
  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final baseStyle = AppTheme.readerTextStyle(
      fontFamily: settings.fontFamily,
      fontSize: settings.fontSize,
      lineHeight: settings.lineHeight,
    );

    if (widget.highlights.isEmpty) {
      return SelectableText(
        widget.body,
        style: baseStyle,
        onSelectionChanged: (sel, cause) {
          if (sel.start >= 0 && sel.end > sel.start) {
            widget.onSelectionChanged(
              sel.start, sel.end,
              widget.body.substring(sel.start.clamp(0, widget.body.length),
                  sel.end.clamp(0, widget.body.length)),
            );
          }
        },
      );
    }

    // ハイライトをオフセット順にソートしてスパンを構築
    final spans = _buildSpans(widget.body, widget.highlights, baseStyle);

    return SelectableText.rich(
      TextSpan(children: spans),
      onSelectionChanged: (sel, cause) {
        if (sel.start >= 0 && sel.end > sel.start) {
          widget.onSelectionChanged(
            sel.start, sel.end,
            widget.body.substring(
              sel.start.clamp(0, widget.body.length),
              sel.end.clamp(0, widget.body.length),
            ),
          );
        }
      },
    );
  }

  List<TextSpan> _buildSpans(String text, List<Highlight> highlights, TextStyle base) {
    final sorted = [...highlights]
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final h in sorted) {
      final start = h.startOffset.clamp(0, text.length);
      final end = h.endOffset.clamp(0, text.length);
      if (start >= end || start < cursor) continue;

      if (cursor < start) {
        spans.add(TextSpan(text: text.substring(cursor, start), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: base.copyWith(
          backgroundColor: HighlightColors.background(h.category),
        ),
      ));
      cursor = end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: base));
    }
    return spans;
  }
}

// ── 上部バー ──
class _TopBar extends StatelessWidget {
  final Work work;
  final Document document;
  final Color bgColor;
  final VoidCallback onClose;
  final VoidCallback onSettings;

  const _TopBar({
    required this.work,
    required this.document,
    required this.bgColor,
    required this.onClose,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor.withValues(alpha: 0.97),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      document.title,
                      style: GoogleFonts.notoSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      work.title,
                      style: GoogleFonts.notoSans(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                color: AppColors.textSecondary,
                onPressed: onSettings,
                tooltip: '表示設定',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 下部メニューバー ──
class _BottomMenuBar extends StatelessWidget {
  final Color bgColor;
  final VoidCallback onBookmark;
  final VoidCallback onChapters;
  final VoidCallback onRelated;
  final VoidCallback onExport;
  final double currentPosition;

  const _BottomMenuBar({
    required this.bgColor,
    required this.onBookmark,
    required this.onChapters,
    required this.onRelated,
    required this.onExport,
    required this.currentPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.97),
        border: const Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MenuBtn(icon: Icons.bookmark_border, label: 'しおり', onTap: onBookmark),
              _MenuBtn(icon: Icons.format_list_bulleted, label: '章', onTap: onChapters),
              _MenuBtn(icon: Icons.layers_outlined, label: '関連文書', onTap: onRelated),
              _MenuBtn(icon: Icons.ios_share_outlined, label: '書き出し', onTap: onExport),
              _ProgressText(position: currentPosition),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.notoSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressText extends StatelessWidget {
  final double position;
  const _ProgressText({required this.position});

  @override
  Widget build(BuildContext context) {
    final pct = (position * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$pct%',
            style: GoogleFonts.notoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          Text(
            '読書位置',
            style: GoogleFonts.notoSans(fontSize: 10, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ── ハイライトツールバー ──
class _HighlightToolbar extends StatelessWidget {
  final String text;
  final void Function(String category) onSelect;
  final VoidCallback onDismiss;

  const _HighlightToolbar({
    required this.text,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2820),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '「${text.length > 20 ? '${text.substring(0, 20)}…' : text}」',
                style: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HlBtn('良表現', 'good', const Color(0xFFD4E8C2), const Color(0xFF3A6B28), onSelect),
                  const SizedBox(width: 8),
                  _HlBtn('違和感', 'fix', const Color(0xFFF5D0C8), const Color(0xFF8B3A2A), onSelect),
                  const SizedBox(width: 8),
                  _HlBtn('要確認', 'check', const Color(0xFFFBEAB8), const Color(0xFF7A6010), onSelect),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close, size: 18, color: Colors.white54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HlBtn extends StatelessWidget {
  final String label;
  final String category;
  final Color bg;
  final Color fg;
  final void Function(String) onTap;

  const _HlBtn(this.label, this.category, this.bg, this.fg, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ── 進捗ドット ──
class _ProgressDot extends StatelessWidget {
  final double position;
  const _ProgressDot({required this.position});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10, top: 6),
      child: Text(
        '${(position * 100).toStringAsFixed(0)}%',
        style: GoogleFonts.notoSans(
          fontSize: 10,
          color: AppColors.textHint,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ── 章検出 ──
class _Chapter {
  final String title;
  final double position; // 0.0〜1.0 (文字位置の比率)
  final int charOffset;

  _Chapter({required this.title, required this.position, required this.charOffset});
}

List<_Chapter> _detectChapters(String text) {
  final chapters = <_Chapter>[];
  final lines = text.split('\n');
  int offset = 0;

  final patterns = [
    RegExp(r'^#{1,3}\s+(.+)$'),                          // Markdown見出し
    RegExp(r'^第[一二三四五六七八九十百\d]+[章話節部編]\s*(.*)$'),  // 第N章
    RegExp(r'^[■◆●▶︎【].+'),                             // 記号付き見出し
    RegExp(r'^\[.+\]$'),                                   // [タイトル]形式
  ];

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      for (final pat in patterns) {
        if (pat.hasMatch(trimmed)) {
          final title = trimmed.replaceAll(RegExp(r'^#{1,3}\s+'), '');
          final pos = text.isNotEmpty ? offset / text.length : 0.0;
          chapters.add(_Chapter(title: title, position: pos, charOffset: offset));
          break;
        }
      }
    }
    offset += line.length + 1; // +1 for \n
  }

  return chapters;
}

// ── 章・しおりシート ──
class _ChaptersSheet extends StatefulWidget {
  final List<_Chapter> chapters;
  final List<Bookmark> bookmarks;
  final void Function(_Chapter) onChapterTap;
  final void Function(Bookmark) onBookmarkTap;
  final void Function(String) onBookmarkDelete;

  const _ChaptersSheet({
    required this.chapters,
    required this.bookmarks,
    required this.onChapterTap,
    required this.onBookmarkTap,
    required this.onBookmarkDelete,
  });

  @override
  State<_ChaptersSheet> createState() => _ChaptersSheetState();
}

class _ChaptersSheetState extends State<_ChaptersSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      builder: (_, ctrl) => Column(
        children: [
          // ハンドル
          const SizedBox(height: 8),
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textHint,
            indicatorColor: AppColors.accent,
            labelStyle: GoogleFonts.notoSans(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: '章 (${widget.chapters.length})'),
              Tab(text: 'しおり (${widget.bookmarks.length})'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 章一覧
                widget.chapters.isEmpty
                    ? _EmptyTab(message: '見出しが検出されませんでした\n（# 章タイトル や 第1章 などを使うと自動検出されます）')
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: widget.chapters.length,
                        itemBuilder: (_, i) {
                          final ch = widget.chapters[i];
                          return ListTile(
                            leading: Text(
                              '${(ch.position * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.notoSans(
                                fontSize: 12, color: AppColors.textHint),
                            ),
                            title: Text(
                              ch.title,
                              style: GoogleFonts.notoSerif(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onChapterTap(ch);
                            },
                          );
                        },
                      ),
                // しおり一覧
                widget.bookmarks.isEmpty
                    ? const _EmptyTab(message: '読書中にメニューから\nしおりを追加できます')
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: widget.bookmarks.length,
                        itemBuilder: (_, i) {
                          final bm = widget.bookmarks[i];
                          return ListTile(
                            leading: const Icon(
                              Icons.bookmark, color: AppColors.accent, size: 20),
                            title: Text(
                              bm.label?.isNotEmpty == true
                                  ? bm.label!
                                  : '${(bm.position * 100).toStringAsFixed(0)}% 付近',
                              style: GoogleFonts.notoSans(
                                fontSize: 14, color: AppColors.textPrimary),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: AppColors.textHint),
                              onPressed: () {
                                widget.onBookmarkDelete(bm.id);
                                Navigator.pop(context);
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onBookmarkTap(bm);
                            },
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String message;
  const _EmptyTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSans(
            fontSize: 13, color: AppColors.textHint, height: 1.8),
        ),
      ),
    );
  }
}
