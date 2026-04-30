import 'dart:convert';
import 'repository.dart';

/// JSON エクスポート / インポートの責務を持つサービス
///
/// AppRepository インターフェースのみに依存するため、
/// Hive / Firebase どちらの実装でも同じロジックが使える。
class TransferService {
  final AppRepository _repo;

  TransferService(this._repo);

  // ────────────────────────────────────────────
  // エクスポート
  // ────────────────────────────────────────────

  /// 全データを JSON 文字列として返す
  Future<String> exportToJson() async {
    final snapshot = await _repo.exportAll();
    final map = snapshot.toJson();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// エクスポート前のサマリーを返す（UI 表示用）
  Future<TransferSummary> getExportSummary() async {
    final snapshot = await _repo.exportAll();
    return TransferSummary.fromCounts(snapshot.counts, snapshot.exportedAt);
  }

  // ────────────────────────────────────────────
  // インポート（パース・バリデーション）
  // ────────────────────────────────────────────

  /// JSON 文字列をパースして [ImportPreview] を返す
  ///
  /// エラー時は [ImportParseException] をスロー。
  /// この段階では保存を行わない（ユーザーが確認してから保存する）。
  ImportPreview parseJson(String jsonText) {
    final dynamic raw;
    try {
      raw = jsonDecode(jsonText);
    } catch (e) {
      throw ImportParseException('JSONの形式が正しくありません。\n($e)');
    }

    if (raw is! Map<String, dynamic>) {
      throw ImportParseException('JSONのトップレベルはオブジェクト形式である必要があります。');
    }

    // 必須キーの確認
    if (!raw.containsKey('works') || !raw.containsKey('documents')) {
      throw ImportParseException(
          '必須フィールド（works, documents）が見つかりません。\nQuiet Reader の書き出しデータか確認してください。');
    }

    final RepositorySnapshot snapshot;
    try {
      snapshot = RepositorySnapshot.fromJson(raw);
    } catch (e) {
      throw ImportParseException('データの読み込みに失敗しました。\n($e)');
    }

    return ImportPreview(snapshot: snapshot);
  }

  // ────────────────────────────────────────────
  // インポート実行
  // ────────────────────────────────────────────

  /// 全置換インポート
  ///
  /// - 既存データをすべて削除してから snapshot を書き込む
  /// - 表示設定も snapshot の値で上書きされる
  Future<void> importReplace(ImportPreview preview) async {
    await _repo.replaceAll(preview.snapshot);
  }

  /// マージインポート
  ///
  /// - 既存データは保持したまま snapshot を追加/上書きする
  /// - ID が同じレコードは snapshot 側が優先（updatedAt の新しい方を選ぶ）
  /// - 表示設定はマージしない（既存設定を保持）
  Future<void> importMerge(ImportPreview preview) async {
    // 設定だけ既存を保持するため、設定を差し替えた snapshot を作る
    final currentSettings = _repo.getSettings();
    final snapshotWithCurrentSettings = RepositorySnapshot(
      formatVersion: preview.snapshot.formatVersion,
      exportedAt: preview.snapshot.exportedAt,
      works: preview.snapshot.works,
      documents: preview.snapshot.documents,
      bookmarks: preview.snapshot.bookmarks,
      highlights: preview.snapshot.highlights,
      memos: preview.snapshot.memos,
      settings: currentSettings, // ← 既存設定を保持
    );
    await _repo.mergeAll(snapshotWithCurrentSettings);
  }
}

// ────────────────────────────────────────────
// 値オブジェクト
// ────────────────────────────────────────────

/// インポート前のプレビュー情報
///
/// UI はこれを受け取って内容を表示し、
/// ユーザーが確認してから importReplace / importMerge を呼ぶ。
class ImportPreview {
  final RepositorySnapshot snapshot;

  const ImportPreview({required this.snapshot});

  Map<String, int> get counts => snapshot.counts;
  String get formatVersion => snapshot.formatVersion;
  DateTime get exportedAt => snapshot.exportedAt;

  String get exportedAtLabel {
    final d = exportedAt;
    return '${d.year}/${_z(d.month)}/${_z(d.day)} ${_z(d.hour)}:${_z(d.minute)}';
  }

  String _z(int n) => n.toString().padLeft(2, '0');
}

/// エクスポートデータのサマリー（UI 表示用）
class TransferSummary {
  final Map<String, int> counts;
  final DateTime exportedAt;

  const TransferSummary({required this.counts, required this.exportedAt});

  factory TransferSummary.fromCounts(Map<String, int> counts, DateTime at) =>
      TransferSummary(counts: counts, exportedAt: at);

  String get exportedAtLabel {
    final d = exportedAt;
    return '${d.year}/${_z(d.month)}/${_z(d.day)} ${_z(d.hour)}:${_z(d.minute)}';
  }

  String _z(int n) => n.toString().padLeft(2, '0');
}

/// インポートパース時のエラー
class ImportParseException implements Exception {
  final String message;
  const ImportParseException(this.message);

  @override
  String toString() => message;
}
