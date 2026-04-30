import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_provider.dart';
import '../services/transfer_service.dart';
import '../theme/app_theme.dart';

/// データ転送画面
///
/// ## エクスポート
/// - 全データ（作品・文書・しおり・ハイライト・メモ・読書位置・表示設定）を
///   JSON テキストとしてクリップボードにコピー
///
/// ## インポート仕様
/// | モード      | 既存データ | 重複時の扱い |
/// |------------|-----------|------------|
/// | 全置換      | 全削除     | snapshot 側で上書き（旧データは消える） |
/// | マージ      | 保持       | ID が同じなら snapshot 側が優先 |
///
/// ### 共通ルール
/// - 表示設定はマージモードでは上書きしない（既存設定を保持）
/// - 全置換でも表示設定は snapshot に含まれていれば上書きされる
/// - 読書位置は Document の `lastReadPosition` フィールドに含まれる
///
/// ## 将来の同期拡張について
/// - UI 層は TransferService / AppRepository インターフェースのみに依存
/// - Firebase 等への切り替えは HiveRepository → FirebaseRepository の
///   差し替えのみで対応可能（この画面は変更不要）
class DataTransferScreen extends StatefulWidget {
  const DataTransferScreen({super.key});

  @override
  State<DataTransferScreen> createState() => _DataTransferScreenState();
}

class _DataTransferScreenState extends State<DataTransferScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // エクスポート
  bool _isExporting = false;
  String? _exportedJson;
  String? _exportSummaryText;

  // インポート
  final TextEditingController _importCtrl = TextEditingController();
  ImportPreview? _preview;
  String? _parseError;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────── エクスポート ─────────────────────────

  Future<void> _doExport() async {
    setState(() { _isExporting = true; _exportedJson = null; });
    try {
      final repo = context.read<AppProvider>().repo;
      final svc  = TransferService(repo);
      final json = await svc.exportToJson();
      final sum  = await svc.getExportSummary();
      setState(() {
        _exportedJson = json;
        _exportSummaryText =
            '作品 ${sum.counts['works']}件 ／ '
            '文書 ${sum.counts['documents']}件 ／ '
            'しおり ${sum.counts['bookmarks']}件 ／ '
            'ハイライト ${sum.counts['highlights']}件 ／ '
            'メモ ${sum.counts['memos']}件\n'
            '書き出し日時：${sum.exportedAtLabel}';
      });
    } catch (e) {
      if (mounted) _showError('書き出しに失敗しました。\n$e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_exportedJson == null) return;
    await Clipboard.setData(ClipboardData(text: _exportedJson!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('クリップボードにコピーしました'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ───────────────────────── インポート ─────────────────────────

  void _parseInput() {
    final text = _importCtrl.text.trim();
    if (text.isEmpty) {
      setState(() { _preview = null; _parseError = null; });
      return;
    }
    try {
      final repo    = context.read<AppProvider>().repo;
      final svc     = TransferService(repo);
      final preview = svc.parseJson(text);
      setState(() { _preview = preview; _parseError = null; });
    } on ImportParseException catch (e) {
      setState(() { _preview = null; _parseError = e.message; });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _importCtrl.text = data!.text!;
      _parseInput();
    }
  }

  void _showImportConfirm({required bool isReplace}) {
    if (_preview == null) return;
    final mode = isReplace ? '全置換' : 'マージ';
    final c    = _preview!.counts;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'インポート確認（$mode）',
          style: GoogleFonts.notoSerif(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isReplace) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '既存のデータはすべて削除されます。\nこの操作は取り消せません。',
                        style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _infoRow('作品', c['works'] ?? 0),
            _infoRow('文書', c['documents'] ?? 0),
            _infoRow('しおり', c['bookmarks'] ?? 0),
            _infoRow('ハイライト', c['highlights'] ?? 0),
            _infoRow('メモ', c['memos'] ?? 0),
            const SizedBox(height: 8),
            Text(
              '書き出し日時：${_preview!.exportedAtLabel}',
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12,
              ),
            ),
            if (!isReplace) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'ID が同じデータは読み込み側が優先されます。\n表示設定は現在の設定を保持します。',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReplace ? Colors.red.shade600 : AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isReplace ? '全置換する' : 'マージする'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _executeImport(isReplace: isReplace);
    });
  }

  Future<void> _executeImport({required bool isReplace}) async {
    if (_preview == null) return;
    setState(() => _isImporting = true);
    try {
      final provider = context.read<AppProvider>();
      final repo = provider.repo;
      final svc  = TransferService(repo);
      if (isReplace) {
        await svc.importReplace(_preview!);
      } else {
        await svc.importMerge(_preview!);
      }
      await provider.reloadAfterImport();
      if (!mounted) return;
      setState(() {
        _importCtrl.clear();
        _preview   = null;
        _parseError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isReplace ? '全置換インポートが完了しました' : 'マージインポートが完了しました'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) _showError('インポートに失敗しました。\n$e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ───────────────────────── UI ─────────────────────────

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _infoRow(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text('$count 件', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: Text(
          'データ転送',
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '書き出し（エクスポート）'),
            Tab(text: '読み込み（インポート）'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(),
          _buildImportTab(),
        ],
      ),
    );
  }

  // ── エクスポートタブ ──
  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('データの書き出し'),
          const SizedBox(height: 6),
          Text(
            '作品・文書・しおり・ハイライト・メモ・読書位置・表示設定を\nJSON テキストとして書き出します。',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),

          // 書き出しボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isExporting ? null : _doExport,
              icon: _isExporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload_outlined),
              label: Text(_isExporting ? '書き出し中...' : 'JSONを書き出す'),
            ),
          ),

          if (_exportSummaryText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 6),
                      Text('書き出し完了', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_exportSummaryText!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6)),
                ],
              ),
            ),
          ],

          if (_exportedJson != null) ...[
            const SizedBox(height: 12),
            // クリップボードコピーボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('クリップボードにコピー'),
              ),
            ),
            const SizedBox(height: 12),

            // JSON プレビュー
            Container(
              width: double.infinity,
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EBE2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportedJson!,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 28),
          _specCard(),
        ],
      ),
    );
  }

  // ── インポートタブ ──
  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('データの読み込み'),
          const SizedBox(height: 6),
          Text(
            '書き出した JSON テキストを貼り付けてインポートします。\n全置換またはマージを選択できます。',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 16),

          // 貼り付けボタン
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _pasteFromClipboard,
              icon: const Icon(Icons.paste, size: 18),
              label: const Text('クリップボードから貼り付け'),
            ),
          ),
          const SizedBox(height: 12),

          // テキスト入力エリア
          TextField(
            controller: _importCtrl,
            maxLines: 10,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'ここにJSONを貼り付けてください...',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF0EBE2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: (_) => _parseInput(),
          ),

          // パースエラー表示
          if (_parseError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 12, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // プレビュー表示
          if (_preview != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 6),
                      Text('JSONを確認できました', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _infoRow('作品', _preview!.counts['works'] ?? 0),
                  _infoRow('文書', _preview!.counts['documents'] ?? 0),
                  _infoRow('しおり', _preview!.counts['bookmarks'] ?? 0),
                  _infoRow('ハイライト', _preview!.counts['highlights'] ?? 0),
                  _infoRow('メモ', _preview!.counts['memos'] ?? 0),
                  const Divider(color: AppColors.divider, height: 16),
                  Text('書き出し日時：${_preview!.exportedAtLabel}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // インポートモード選択ボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isImporting ? null : () => _showImportConfirm(isReplace: true),
                    child: const Text('全置換', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isImporting ? null : () => _showImportConfirm(isReplace: false),
                    child: _isImporting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('マージ', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 28),
          _importSpecCard(),
        ],
      ),
    );
  }

  // ── 仕様カード（エクスポート） ──
  Widget _specCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _specTitle('保存対象'),
          const SizedBox(height: 8),
          _specBullet('作品・文書・本文テキスト'),
          _specBullet('しおり・ハイライト・メモ'),
          _specBullet('読書位置（各文書の最終読了位置）'),
          _specBullet('表示設定（フォント・サイズ・背景トーン等）'),
          const SizedBox(height: 12),
          _specTitle('ストレージ'),
          const SizedBox(height: 8),
          _specBullet('現在：端末内ローカル保存（IndexedDB / Hive）'),
          _specBullet('PC とスマホは独立したストレージ（同期なし）'),
          _specBullet('このページで JSON を手動でコピー＆ペーストすることで\n端末間のデータ移行が可能'),
          const SizedBox(height: 12),
          _specTitle('将来の同期拡張について'),
          const SizedBox(height: 8),
          _specBullet('Firebase / 独自サーバーなどへの対応を検討中'),
          _specBullet('保存層（AppRepository）とUI層は分離済みのため\n実装を追加するだけで自動同期に移行可能'),
        ],
      ),
    );
  }

  // ── 仕様カード（インポート） ──
  Widget _importSpecCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _specTitle('インポートモードの違い'),
          const SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: AppColors.divider, width: 0.8),
            columnWidths: const {
              0: FlexColumnWidth(1.8),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: const Color(0xFFEDE5D6)),
                children: [
                  _tableHeader('モード'),
                  _tableHeader('既存データ'),
                  _tableHeader('ID重複時'),
                ],
              ),
              TableRow(children: [
                _tableCell('全置換', bold: true),
                _tableCell('全削除'),
                _tableCell('読み込み側で上書き'),
              ]),
              TableRow(children: [
                _tableCell('マージ', bold: true),
                _tableCell('保持'),
                _tableCell('読み込み側が優先'),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          _specTitle('共通ルール'),
          const SizedBox(height: 8),
          _specBullet('マージ時、表示設定は現在の設定を保持します'),
          _specBullet('全置換時、表示設定も JSON の値で上書きされます'),
          _specBullet('読書位置は文書データに含まれます'),
          _specBullet('インポート後、作品一覧は自動的に更新されます'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) => Text(
    text,
    style: GoogleFonts.notoSerif(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  Widget _specTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.accent,
      letterSpacing: 0.5,
    ),
  );

  Widget _specBullet(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('・', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.6),
          ),
        ),
      ],
    ),
  );

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
  );

  Widget _tableCell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: AppColors.textSecondary,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}
