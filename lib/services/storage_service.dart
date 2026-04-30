import 'package:hive_flutter/hive_flutter.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../models/reader_settings.dart';

class StorageService {
  static const String _worksBox = 'works';
  static const String _documentsBox = 'documents';
  static const String _bookmarksBox = 'bookmarks';
  static const String _highlightsBox = 'highlights';
  static const String _memosBox = 'memos';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(WorkAdapter());
    Hive.registerAdapter(DocumentAdapter());
    Hive.registerAdapter(BookmarkAdapter());
    Hive.registerAdapter(HighlightAdapter());
    Hive.registerAdapter(MemoAdapter());
    Hive.registerAdapter(ReaderSettingsAdapter());

    await Hive.openBox<Work>(_worksBox);
    await Hive.openBox<Document>(_documentsBox);
    await Hive.openBox<Bookmark>(_bookmarksBox);
    await Hive.openBox<Highlight>(_highlightsBox);
    await Hive.openBox<Memo>(_memosBox);
    await Hive.openBox<ReaderSettings>(_settingsBox);
  }

  // ---- Work ----
  Box<Work> get worksBox => Hive.box<Work>(_worksBox);
  Box<Document> get documentsBox => Hive.box<Document>(_documentsBox);
  Box<Bookmark> get bookmarksBox => Hive.box<Bookmark>(_bookmarksBox);
  Box<Highlight> get highlightsBox => Hive.box<Highlight>(_highlightsBox);
  Box<Memo> get memosBox => Hive.box<Memo>(_memosBox);
  Box<ReaderSettings> get settingsBox => Hive.box<ReaderSettings>(_settingsBox);

  List<Work> getAllWorks() {
    return worksBox.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveWork(Work work) async {
    await worksBox.put(work.id, work);
  }

  Future<void> deleteWork(String workId) async {
    await worksBox.delete(workId);
    final docs = getDocumentsByWork(workId);
    for (final doc in docs) {
      await deleteDocument(doc.id);
    }
  }

  // ---- Document ----
  List<Document> getDocumentsByWork(String workId) {
    return documentsBox.values
        .where((d) => d.workId == workId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Document? getDocument(String documentId) {
    return documentsBox.get(documentId);
  }

  Future<void> saveDocument(Document doc) async {
    await documentsBox.put(doc.id, doc);
    // 作品のupdatedAtも更新
    final work = worksBox.get(doc.workId);
    if (work != null) {
      work.updatedAt = DateTime.now();
      await work.save();
    }
  }

  Future<void> deleteDocument(String documentId) async {
    await documentsBox.delete(documentId);
    // 関連データも削除
    final bookmarks = getBookmarksByDocument(documentId);
    for (final b in bookmarks) {
      await bookmarksBox.delete(b.id);
    }
    final highlights = getHighlightsByDocument(documentId);
    for (final h in highlights) {
      await deleteHighlight(h.id);
    }
  }

  // ---- Bookmark ----
  List<Bookmark> getBookmarksByDocument(String documentId) {
    return bookmarksBox.values
        .where((b) => b.documentId == documentId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    await bookmarksBox.put(bookmark.id, bookmark);
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await bookmarksBox.delete(bookmarkId);
  }

  // ---- Highlight ----
  List<Highlight> getHighlightsByDocument(String documentId) {
    return highlightsBox.values
        .where((h) => h.documentId == documentId)
        .toList()
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));
  }

  Future<void> saveHighlight(Highlight highlight) async {
    await highlightsBox.put(highlight.id, highlight);
  }

  Future<void> deleteHighlight(String highlightId) async {
    await highlightsBox.delete(highlightId);
    final memos = getMemosByHighlight(highlightId);
    for (final m in memos) {
      await memosBox.delete(m.id);
    }
  }

  // ---- Memo ----
  List<Memo> getMemosByHighlight(String highlightId) {
    return memosBox.values
        .where((m) => m.highlightId == highlightId)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Memo? getMemoByHighlight(String highlightId) {
    final list = getMemosByHighlight(highlightId);
    return list.isEmpty ? null : list.first;
  }

  Future<void> saveMemo(Memo memo) async {
    await memosBox.put(memo.id, memo);
  }

  Future<void> deleteMemo(String memoId) async {
    await memosBox.delete(memoId);
  }

  // ---- ReaderSettings ----
  ReaderSettings getSettings() {
    return settingsBox.get('default') ?? ReaderSettings();
  }

  Future<void> saveSettings(ReaderSettings settings) async {
    await settingsBox.put('default', settings);
  }
}
