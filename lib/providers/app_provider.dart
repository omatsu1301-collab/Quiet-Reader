import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../models/reader_settings.dart';
import '../services/storage_service.dart';

class AppProvider extends ChangeNotifier {
  final StorageService _storage;
  final _uuid = const Uuid();

  List<Work> _works = [];
  ReaderSettings _settings = ReaderSettings();

  List<Work> get works => _works;
  ReaderSettings get settings => _settings;

  AppProvider(this._storage) {
    _load();
  }

  void _load() {
    _works = _storage.getAllWorks();
    _settings = _storage.getSettings();
    notifyListeners();
  }

  // ---- Work ----
  Future<Work> createWork(String title) async {
    final now = DateTime.now();
    final work = Work(
      id: _uuid.v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.saveWork(work);
    _works = _storage.getAllWorks();
    notifyListeners();
    return work;
  }

  Future<void> updateWork(Work work, String newTitle) async {
    work.title = newTitle;
    work.updatedAt = DateTime.now();
    await _storage.saveWork(work);
    _works = _storage.getAllWorks();
    notifyListeners();
  }

  Future<void> deleteWork(String workId) async {
    await _storage.deleteWork(workId);
    _works = _storage.getAllWorks();
    notifyListeners();
  }

  // ---- Document ----
  List<Document> getDocuments(String workId) {
    return _storage.getDocumentsByWork(workId);
  }

  Document? getDocument(String documentId) {
    return _storage.getDocument(documentId);
  }

  Future<Document> createDocument({
    required String workId,
    required String title,
    required String type,
    required String body,
  }) async {
    final now = DateTime.now();
    final doc = Document(
      id: _uuid.v4(),
      workId: workId,
      title: title,
      type: type,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.saveDocument(doc);
    _works = _storage.getAllWorks();
    notifyListeners();
    return doc;
  }

  Future<void> updateDocument(Document doc, {
    String? title,
    String? type,
    String? body,
  }) async {
    if (title != null) doc.title = title;
    if (type != null) doc.type = type;
    if (body != null) doc.body = body;
    doc.updatedAt = DateTime.now();
    await _storage.saveDocument(doc);
    _works = _storage.getAllWorks();
    notifyListeners();
  }

  Future<void> deleteDocument(String documentId) async {
    await _storage.deleteDocument(documentId);
    notifyListeners();
  }

  Future<void> saveReadPosition(String documentId, double position) async {
    final doc = _storage.getDocument(documentId);
    if (doc == null) return;
    doc.lastReadPosition = position;
    doc.lastOpenedAt = DateTime.now();
    await _storage.saveDocument(doc);
  }

  // ---- Bookmark ----
  List<Bookmark> getBookmarks(String documentId) {
    return _storage.getBookmarksByDocument(documentId);
  }

  Future<Bookmark> addBookmark(String documentId, double position, {String? label}) async {
    final bookmark = Bookmark(
      id: _uuid.v4(),
      documentId: documentId,
      position: position,
      label: label,
      createdAt: DateTime.now(),
    );
    await _storage.saveBookmark(bookmark);
    notifyListeners();
    return bookmark;
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _storage.deleteBookmark(bookmarkId);
    notifyListeners();
  }

  // ---- Highlight ----
  List<Highlight> getHighlights(String documentId) {
    return _storage.getHighlightsByDocument(documentId);
  }

  Future<Highlight> addHighlight({
    required String documentId,
    required int startOffset,
    required int endOffset,
    required String text,
    required String category,
  }) async {
    final now = DateTime.now();
    final highlight = Highlight(
      id: _uuid.v4(),
      documentId: documentId,
      startOffset: startOffset,
      endOffset: endOffset,
      text: text,
      category: category,
      createdAt: now,
      updatedAt: now,
    );
    await _storage.saveHighlight(highlight);
    notifyListeners();
    return highlight;
  }

  Future<void> deleteHighlight(String highlightId) async {
    await _storage.deleteHighlight(highlightId);
    notifyListeners();
  }

  // ---- Memo ----
  Memo? getMemo(String highlightId) {
    return _storage.getMemoByHighlight(highlightId);
  }

  Future<void> saveMemo(String highlightId, String content) async {
    final existing = _storage.getMemoByHighlight(highlightId);
    final now = DateTime.now();
    if (existing != null) {
      existing.content = content;
      existing.updatedAt = now;
      await _storage.saveMemo(existing);
    } else {
      final memo = Memo(
        id: _uuid.v4(),
        highlightId: highlightId,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
      await _storage.saveMemo(memo);
    }
    notifyListeners();
  }

  // ---- Settings ----
  Future<void> updateSettings(ReaderSettings newSettings) async {
    _settings = newSettings;
    await _storage.saveSettings(newSettings);
    notifyListeners();
  }

  // ---- Export ----
  String exportHighlightsAndMemos(String workId, String documentId) {
    final work = _works.firstWhere((w) => w.id == workId);
    final doc = _storage.getDocument(documentId);
    if (doc == null) return '';

    final highlights = _storage.getHighlightsByDocument(documentId);
    if (highlights.isEmpty) return '# ${work.title}\n## ${doc.title}\n\nメモはありません。';

    final categoryLabel = {
      'good': '良表現',
      'fix': '違和感',
      'check': '要確認',
    };

    final buffer = StringBuffer();
    buffer.writeln('# ${work.title}');
    buffer.writeln('## ${doc.title}');
    buffer.writeln('### メモ一覧');
    buffer.writeln();

    for (final h in highlights) {
      final memo = _storage.getMemoByHighlight(h.id);
      final cat = categoryLabel[h.category] ?? h.category;
      buffer.writeln('- 種別: $cat');
      buffer.writeln('- ハイライト: 「${h.text}」');
      if (memo != null && memo.content.isNotEmpty) {
        buffer.writeln('- メモ: ${memo.content}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}
