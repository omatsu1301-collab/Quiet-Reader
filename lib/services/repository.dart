import '../models/work.dart';
import '../models/document.dart';
import '../models/bookmark.dart';
import '../models/highlight.dart';
import '../models/memo.dart';
import '../models/reader_settings.dart';

/// ストレージ抽象レイヤー
///
/// UI層・Provider層はこのインターフェースのみに依存する。
/// 将来 Firebase や他の同期基盤へ切り替える際は、
/// このインターフェースを実装した新クラスを作り
/// main.dart の DI 注入箇所だけを差し替えれば済む。
abstract class AppRepository {
  // ── Work ──
  List<Work> getAllWorks();
  Future<void> saveWork(Work work);
  Future<void> deleteWork(String workId);

  // ── Document ──
  List<Document> getDocumentsByWork(String workId);
  Document? getDocument(String documentId);
  Future<void> saveDocument(Document doc);
  Future<void> deleteDocument(String documentId);

  // ── Bookmark ──
  List<Bookmark> getBookmarksByDocument(String documentId);
  Future<void> saveBookmark(Bookmark bookmark);
  Future<void> deleteBookmark(String bookmarkId);

  // ── Highlight ──
  List<Highlight> getHighlightsByDocument(String documentId);
  Future<void> saveHighlight(Highlight highlight);
  Future<void> deleteHighlight(String highlightId);

  // ── Memo ──
  List<Memo> getMemosByHighlight(String highlightId);
  Memo? getMemoByHighlight(String highlightId);
  Future<void> saveMemo(Memo memo);
  Future<void> deleteMemo(String memoId);

  // ── ReaderSettings ──
  ReaderSettings getSettings();
  Future<void> saveSettings(ReaderSettings settings);

  // ── 一括操作（インポート用）──
  /// 全データを削除して [snapshot] で上書きする（全置換）
  Future<void> replaceAll(RepositorySnapshot snapshot);

  /// [snapshot] を既存データにマージする（ID重複時は snapshot 優先）
  Future<void> mergeAll(RepositorySnapshot snapshot);

  /// 全データを取得して [RepositorySnapshot] として返す（エクスポート用）
  Future<RepositorySnapshot> exportAll();
}

/// 全データを一括転送するためのバリューオブジェクト
///
/// JSON シリアライズ / デシリアライズの責務を持つ。
/// AppRepository の実装に依存しないため、
/// Firebase / Hive どちらの実装でも同じ JSON フォーマットを使える。
class RepositorySnapshot {
  final String formatVersion;   // 将来のフォーマット変更に対応
  final DateTime exportedAt;
  final List<Work> works;
  final List<Document> documents;
  final List<Bookmark> bookmarks;
  final List<Highlight> highlights;
  final List<Memo> memos;
  final ReaderSettings settings;

  const RepositorySnapshot({
    required this.formatVersion,
    required this.exportedAt,
    required this.works,
    required this.documents,
    required this.bookmarks,
    required this.highlights,
    required this.memos,
    required this.settings,
  });

  // ── JSON シリアライズ ──
  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'exportedAt': exportedAt.toIso8601String(),
    'works': works.map(_workToJson).toList(),
    'documents': documents.map(_documentToJson).toList(),
    'bookmarks': bookmarks.map(_bookmarkToJson).toList(),
    'highlights': highlights.map(_highlightToJson).toList(),
    'memos': memos.map(_memoToJson).toList(),
    'settings': _settingsToJson(settings),
  };

  // ── JSON デシリアライズ ──
  factory RepositorySnapshot.fromJson(Map<String, dynamic> json) {
    return RepositorySnapshot(
      formatVersion: json['formatVersion'] as String? ?? '1',
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? '') ?? DateTime.now(),
      works: (json['works'] as List<dynamic>? ?? [])
          .map((e) => _workFromJson(e as Map<String, dynamic>))
          .toList(),
      documents: (json['documents'] as List<dynamic>? ?? [])
          .map((e) => _documentFromJson(e as Map<String, dynamic>))
          .toList(),
      bookmarks: (json['bookmarks'] as List<dynamic>? ?? [])
          .map((e) => _bookmarkFromJson(e as Map<String, dynamic>))
          .toList(),
      highlights: (json['highlights'] as List<dynamic>? ?? [])
          .map((e) => _highlightFromJson(e as Map<String, dynamic>))
          .toList(),
      memos: (json['memos'] as List<dynamic>? ?? [])
          .map((e) => _memoFromJson(e as Map<String, dynamic>))
          .toList(),
      settings: _settingsFromJson(json['settings'] as Map<String, dynamic>? ?? {}),
    );
  }

  // ── 統計情報 ──
  Map<String, int> get counts => {
    'works': works.length,
    'documents': documents.length,
    'bookmarks': bookmarks.length,
    'highlights': highlights.length,
    'memos': memos.length,
  };
}

// ──────────────────────────────────────────────
// JSON 変換ヘルパー（Hive 非依存の純粋な変換関数）
// ──────────────────────────────────────────────

Map<String, dynamic> _workToJson(Work w) => {
  'id': w.id,
  'title': w.title,
  'createdAt': w.createdAt.toIso8601String(),
  'updatedAt': w.updatedAt.toIso8601String(),
};

Work _workFromJson(Map<String, dynamic> j) => Work(
  id: j['id'] as String,
  title: j['title'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
);

Map<String, dynamic> _documentToJson(Document d) => {
  'id': d.id,
  'workId': d.workId,
  'title': d.title,
  'type': d.type,
  'body': d.body,
  'createdAt': d.createdAt.toIso8601String(),
  'updatedAt': d.updatedAt.toIso8601String(),
  'lastReadPosition': d.lastReadPosition,
  'lastOpenedAt': d.lastOpenedAt?.toIso8601String(),
};

Document _documentFromJson(Map<String, dynamic> j) => Document(
  id: j['id'] as String,
  workId: j['workId'] as String,
  title: j['title'] as String,
  type: j['type'] as String,
  body: j['body'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
  lastReadPosition: (j['lastReadPosition'] as num?)?.toDouble() ?? 0.0,
  lastOpenedAt: j['lastOpenedAt'] != null
      ? DateTime.tryParse(j['lastOpenedAt'] as String)
      : null,
);

Map<String, dynamic> _bookmarkToJson(Bookmark b) => {
  'id': b.id,
  'documentId': b.documentId,
  'position': b.position,
  'label': b.label,
  'createdAt': b.createdAt.toIso8601String(),
};

Bookmark _bookmarkFromJson(Map<String, dynamic> j) => Bookmark(
  id: j['id'] as String,
  documentId: j['documentId'] as String,
  position: (j['position'] as num).toDouble(),
  label: j['label'] as String?,
  createdAt: DateTime.parse(j['createdAt'] as String),
);

Map<String, dynamic> _highlightToJson(Highlight h) => {
  'id': h.id,
  'documentId': h.documentId,
  'startOffset': h.startOffset,
  'endOffset': h.endOffset,
  'text': h.text,
  'category': h.category,
  'createdAt': h.createdAt.toIso8601String(),
  'updatedAt': h.updatedAt.toIso8601String(),
};

Highlight _highlightFromJson(Map<String, dynamic> j) => Highlight(
  id: j['id'] as String,
  documentId: j['documentId'] as String,
  startOffset: j['startOffset'] as int,
  endOffset: j['endOffset'] as int,
  text: j['text'] as String,
  category: j['category'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
);

Map<String, dynamic> _memoToJson(Memo m) => {
  'id': m.id,
  'highlightId': m.highlightId,
  'content': m.content,
  'createdAt': m.createdAt.toIso8601String(),
  'updatedAt': m.updatedAt.toIso8601String(),
};

Memo _memoFromJson(Map<String, dynamic> j) => Memo(
  id: j['id'] as String,
  highlightId: j['highlightId'] as String,
  content: j['content'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
);

Map<String, dynamic> _settingsToJson(ReaderSettings s) => {
  'fontFamily': s.fontFamily,
  'fontSize': s.fontSize,
  'lineHeight': s.lineHeight,
  'horizontalPadding': s.horizontalPadding,
  'contentWidth': s.contentWidth,
  'backgroundTone': s.backgroundTone,
};

ReaderSettings _settingsFromJson(Map<String, dynamic> j) => ReaderSettings(
  fontFamily: j['fontFamily'] as String? ?? 'serif',
  fontSize: (j['fontSize'] as num?)?.toDouble() ?? 17.0,
  lineHeight: (j['lineHeight'] as num?)?.toDouble() ?? 1.9,
  horizontalPadding: (j['horizontalPadding'] as num?)?.toDouble() ?? 24.0,
  contentWidth: (j['contentWidth'] as num?)?.toDouble() ?? 0.88,
  backgroundTone: (j['backgroundTone'] as num?)?.toDouble() ?? 0.5,
);
