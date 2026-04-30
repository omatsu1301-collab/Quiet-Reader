import 'package:hive_flutter/hive_flutter.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../models/reader_settings.dart';
import 'repository.dart';

/// Hive を使ったローカルストレージ実装
///
/// AppRepository インターフェースの唯一の実装。
/// 将来 FirebaseRepository に差し替えるときは
/// main.dart の Provider 注入箇所だけを変更すればよい。
class HiveRepository implements AppRepository {
  static const String _worksBox      = 'works';
  static const String _documentsBox  = 'documents';
  static const String _bookmarksBox  = 'bookmarks';
  static const String _highlightsBox = 'highlights';
  static const String _memosBox      = 'memos';
  static const String _settingsBox   = 'settings';

  // ── 初期化 ──
  static Future<void> init() async {
    await Hive.openBox<Work>(_worksBox);
    await Hive.openBox<Document>(_documentsBox);
    await Hive.openBox<Bookmark>(_bookmarksBox);
    await Hive.openBox<Highlight>(_highlightsBox);
    await Hive.openBox<Memo>(_memosBox);
    await Hive.openBox<ReaderSettings>(_settingsBox);
  }

  // ── Box アクセサ ──
  Box<Work>           get _works      => Hive.box<Work>(_worksBox);
  Box<Document>       get _documents  => Hive.box<Document>(_documentsBox);
  Box<Bookmark>       get _bookmarks  => Hive.box<Bookmark>(_bookmarksBox);
  Box<Highlight>      get _highlights => Hive.box<Highlight>(_highlightsBox);
  Box<Memo>           get _memos      => Hive.box<Memo>(_memosBox);
  Box<ReaderSettings> get _settings   => Hive.box<ReaderSettings>(_settingsBox);

  // ── Work ──
  @override
  List<Work> getAllWorks() => _works.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Future<void> saveWork(Work work) => _works.put(work.id, work);

  @override
  Future<void> deleteWork(String workId) async {
    await _works.delete(workId);
    for (final doc in getDocumentsByWork(workId).toList()) {
      await deleteDocument(doc.id);
    }
  }

  // ── Document ──
  @override
  List<Document> getDocumentsByWork(String workId) =>
      _documents.values.where((d) => d.workId == workId).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  @override
  Document? getDocument(String documentId) => _documents.get(documentId);

  @override
  Future<void> saveDocument(Document doc) async {
    await _documents.put(doc.id, doc);
    final work = _works.get(doc.workId);
    if (work != null) {
      work.updatedAt = DateTime.now();
      await work.save();
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await _documents.delete(documentId);
    for (final b in getBookmarksByDocument(documentId).toList()) {
      await _bookmarks.delete(b.id);
    }
    for (final h in getHighlightsByDocument(documentId).toList()) {
      await deleteHighlight(h.id);
    }
  }

  // ── Bookmark ──
  @override
  List<Bookmark> getBookmarksByDocument(String documentId) =>
      _bookmarks.values.where((b) => b.documentId == documentId).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  @override
  Future<void> saveBookmark(Bookmark bookmark) =>
      _bookmarks.put(bookmark.id, bookmark);

  @override
  Future<void> deleteBookmark(String bookmarkId) =>
      _bookmarks.delete(bookmarkId);

  // ── Highlight ──
  @override
  List<Highlight> getHighlightsByDocument(String documentId) =>
      _highlights.values.where((h) => h.documentId == documentId).toList()
        ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

  @override
  Future<void> saveHighlight(Highlight highlight) =>
      _highlights.put(highlight.id, highlight);

  @override
  Future<void> deleteHighlight(String highlightId) async {
    await _highlights.delete(highlightId);
    for (final m in getMemosByHighlight(highlightId).toList()) {
      await _memos.delete(m.id);
    }
  }

  // ── Memo ──
  @override
  List<Memo> getMemosByHighlight(String highlightId) =>
      _memos.values.where((m) => m.highlightId == highlightId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Memo? getMemoByHighlight(String highlightId) {
    final list = getMemosByHighlight(highlightId);
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<void> saveMemo(Memo memo) => _memos.put(memo.id, memo);

  @override
  Future<void> deleteMemo(String memoId) => _memos.delete(memoId);

  // ── ReaderSettings ──
  @override
  ReaderSettings getSettings() => _settings.get('default') ?? ReaderSettings();

  @override
  Future<void> saveSettings(ReaderSettings settings) =>
      _settings.put('default', settings);

  // ── 一括操作 ──

  /// 全データを削除して snapshot で上書き（全置換）
  @override
  Future<void> replaceAll(RepositorySnapshot snapshot) async {
    await _clearAll();
    await _writeSnapshot(snapshot);
  }

  /// snapshot を既存データにマージ（ID重複時は snapshot 側を優先）
  @override
  Future<void> mergeAll(RepositorySnapshot snapshot) async {
    await _writeSnapshot(snapshot);
  }

  /// 全データを RepositorySnapshot として返す
  @override
  Future<RepositorySnapshot> exportAll() async {
    final allWorks = getAllWorks();
    final allDocs  = _documents.values.toList();
    final allBMs   = _bookmarks.values.toList();
    final allHLs   = _highlights.values.toList();
    final allMemos = _memos.values.toList();
    final settings = getSettings();

    return RepositorySnapshot(
      formatVersion: '1',
      exportedAt: DateTime.now(),
      works:      allWorks,
      documents:  allDocs,
      bookmarks:  allBMs,
      highlights: allHLs,
      memos:      allMemos,
      settings:   settings,
    );
  }

  // ── 内部ヘルパー ──

  Future<void> _clearAll() async {
    await _works.clear();
    await _documents.clear();
    await _bookmarks.clear();
    await _highlights.clear();
    await _memos.clear();
    // settings は clear しない（全置換でも設定は保持する選択肢もあるが、
    // snapshot に含まれていれば上書きされるので問題なし）
  }

  Future<void> _writeSnapshot(RepositorySnapshot s) async {
    for (final w in s.works)      { await _works.put(w.id, w); }
    for (final d in s.documents)  { await _documents.put(d.id, d); }
    for (final b in s.bookmarks)  { await _bookmarks.put(b.id, b); }
    for (final h in s.highlights) { await _highlights.put(h.id, h); }
    for (final m in s.memos)      { await _memos.put(m.id, m); }
    await _settings.put('default', s.settings);
  }
}
