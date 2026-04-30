import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../models/reader_settings.dart';
import '../services/repository.dart';

/// アプリ全体の状態管理
///
/// StorageService への直接依存をなくし、AppRepository インターフェース
/// のみに依存する。将来 Firebase 等に切り替える場合は main.dart の
/// DI 注入箇所だけを変更すればよい。
class AppProvider extends ChangeNotifier {
  final AppRepository _repo;
  final _uuid = const Uuid();

  List<Work> _works = [];
  ReaderSettings _settings = ReaderSettings();

  List<Work> get works => _works;
  ReaderSettings get settings => _settings;

  /// DataTransferScreen から TransferService を生成するために公開
  AppRepository get repo => _repo;

  AppProvider(this._repo) {
    _reload();
  }

  /// Repository からデータを再読み込みして UI を更新する
  void _reload() {
    _works    = _repo.getAllWorks();
    _settings = _repo.getSettings();
    notifyListeners();
  }

  // ── Work ──

  Future<Work> createWork(String title) async {
    final now  = DateTime.now();
    final work = Work(id: _uuid.v4(), title: title, createdAt: now, updatedAt: now);
    await _repo.saveWork(work);
    _reload();
    return work;
  }

  Future<void> updateWork(Work work, String newTitle) async {
    work.title     = newTitle;
    work.updatedAt = DateTime.now();
    await _repo.saveWork(work);
    _reload();
  }

  Future<void> deleteWork(String workId) async {
    await _repo.deleteWork(workId);
    _reload();
  }

  // ── Document ──

  List<Document> getDocuments(String workId) =>
      _repo.getDocumentsByWork(workId);

  Document? getDocument(String documentId) =>
      _repo.getDocument(documentId);

  Future<Document> createDocument({
    required String workId,
    required String title,
    required String type,
    required String body,
  }) async {
    final now = DateTime.now();
    final doc = Document(
      id: _uuid.v4(), workId: workId, title: title,
      type: type, body: body, createdAt: now, updatedAt: now,
    );
    await _repo.saveDocument(doc);
    _reload();
    return doc;
  }

  Future<void> updateDocument(Document doc, {
    String? title, String? type, String? body,
  }) async {
    if (title != null) doc.title = title;
    if (type  != null) doc.type  = type;
    if (body  != null) doc.body  = body;
    doc.updatedAt = DateTime.now();
    await _repo.saveDocument(doc);
    _reload();
  }

  Future<void> deleteDocument(String documentId) async {
    await _repo.deleteDocument(documentId);
    notifyListeners();
  }

  Future<void> saveReadPosition(String documentId, double position) async {
    final doc = _repo.getDocument(documentId);
    if (doc == null) return;
    doc.lastReadPosition = position;
    doc.lastOpenedAt     = DateTime.now();
    await _repo.saveDocument(doc);
    // 読書位置保存は高頻度のため notifyListeners は呼ばない
  }

  // ── Bookmark ──

  List<Bookmark> getBookmarks(String documentId) =>
      _repo.getBookmarksByDocument(documentId);

  Future<Bookmark> addBookmark(String documentId, double position, {String? label}) async {
    final bm = Bookmark(
      id: _uuid.v4(), documentId: documentId,
      position: position, label: label, createdAt: DateTime.now(),
    );
    await _repo.saveBookmark(bm);
    notifyListeners();
    return bm;
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _repo.deleteBookmark(bookmarkId);
    notifyListeners();
  }

  // ── Highlight ──

  List<Highlight> getHighlights(String documentId) =>
      _repo.getHighlightsByDocument(documentId);

  Future<Highlight> addHighlight({
    required String documentId,
    required int startOffset,
    required int endOffset,
    required String text,
    required String category,
  }) async {
    final now = DateTime.now();
    final h   = Highlight(
      id: _uuid.v4(), documentId: documentId,
      startOffset: startOffset, endOffset: endOffset,
      text: text, category: category, createdAt: now, updatedAt: now,
    );
    await _repo.saveHighlight(h);
    notifyListeners();
    return h;
  }

  Future<void> deleteHighlight(String highlightId) async {
    await _repo.deleteHighlight(highlightId);
    notifyListeners();
  }

  // ── Memo ──

  Memo? getMemo(String highlightId) => _repo.getMemoByHighlight(highlightId);

  Future<void> saveMemo(String highlightId, String content) async {
    final existing = _repo.getMemoByHighlight(highlightId);
    final now      = DateTime.now();
    if (existing != null) {
      existing.content   = content;
      existing.updatedAt = now;
      await _repo.saveMemo(existing);
    } else {
      await _repo.saveMemo(Memo(
        id: _uuid.v4(), highlightId: highlightId,
        content: content, createdAt: now, updatedAt: now,
      ));
    }
    notifyListeners();
  }

  // ── ReaderSettings ──

  Future<void> updateSettings(ReaderSettings newSettings) async {
    _settings = newSettings;
    await _repo.saveSettings(newSettings);
    notifyListeners();
  }

  // ── ハイライト/メモ テキスト書き出し（読書画面用）──

  String exportHighlightsAndMemos(String workId, String documentId) {
    final work = _works.firstWhere((w) => w.id == workId);
    final doc  = _repo.getDocument(documentId);
    if (doc == null) return '';

    final highlights = _repo.getHighlightsByDocument(documentId);
    if (highlights.isEmpty) {
      return '# ${work.title}\n## ${doc.title}\n\nメモはありません。';
    }

    const labels = {'good': '良表現', 'fix': '違和感', 'check': '要確認'};
    final buf = StringBuffer()
      ..writeln('# ${work.title}')
      ..writeln('## ${doc.title}')
      ..writeln('### メモ一覧')
      ..writeln();

    for (final h in highlights) {
      final memo = _repo.getMemoByHighlight(h.id);
      buf
        ..writeln('- 種別: ${labels[h.category] ?? h.category}')
        ..writeln('- ハイライト: 「${h.text}」');
      if (memo != null && memo.content.isNotEmpty) {
        buf.writeln('- メモ: ${memo.content}');
      }
      buf.writeln();
    }
    return buf.toString();
  }

  // ── データ転送（JSON インポート完了後に呼ぶ）──

  /// インポート後にアプリ全体の状態を再読み込みする
  Future<void> reloadAfterImport() async {
    _reload();
  }
}
