import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

String _vnSort(String s) => s.toLowerCase()
    .replaceAll(RegExp(r'[àáảãạăắặằẳẵâấầẩẫậ]'), 'a')
    .replaceAll(RegExp(r'[èéẻẽẹêếềểễệ]'), 'e')
    .replaceAll(RegExp(r'[ìíỉĩị]'), 'i')
    .replaceAll(RegExp(r'[òóỏõọôốồổỗộơớờởỡợ]'), 'o')
    .replaceAll(RegExp(r'[ùúủũụưứừửữự]'), 'u')
    .replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y')
    .replaceAll(RegExp(r'[đ]'), 'dz');

// ═══════════════════════════════════════════════════════
// SCREEN 1 — QR Scanner
// ═══════════════════════════════════════════════════════
class GvQrAttendanceScreen extends StatefulWidget {
  final String subject;
  final String classCode;
  final String ngay;
  final Map<String, dynamic> tkbParams;

  const GvQrAttendanceScreen({
    super.key,
    required this.subject,
    required this.classCode,
    required this.ngay,
    required this.tkbParams,
  });

  @override
  State<GvQrAttendanceScreen> createState() => _GvQrAttendanceScreenState();
}

class _GvQrAttendanceScreenState extends State<GvQrAttendanceScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  List<Map<String, dynamic>> _students = [];
  Map<int, bool> _attendance = {};
  bool _loadingList = true;
  String? _lastScanned;
  String? _scanMessage;
  bool _scanSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final list = await ApiService.postDiemDanhDanhSach(
        tkbid: widget.tkbParams['tkbid'].toString(),
        lopid: widget.tkbParams['lopid'].toString(),
        phongid: widget.tkbParams['phongid'].toString(),
        ngay: widget.tkbParams['ngay'].toString(),
        thoigianbd: widget.tkbParams['thoigianbd'].toString(),
        thoigiankt: widget.tkbParams['thoigiankt'].toString(),
      );
      final students = list.map((e) => e as Map<String, dynamic>).toList();
      students.sort((a, b) {
        final ta = _vnSort(a['ten']?.toString() ?? '');
        final tb = _vnSort(b['ten']?.toString() ?? '');
        return ta.compareTo(tb);
      });
      if (!mounted) return;
      setState(() {
        _students = students;
        _attendance = {
          for (final s in students)
            s['hocvienid'] as int: s['hiendienyn'] as bool? ?? false,
        };
        _loadingList = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingList = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code == _lastScanned) return;

    final mssv = code.contains('|') ? code.split('|').last.trim() : code.trim();

    final student = _students.cast<Map<String, dynamic>?>().firstWhere(
          (s) => s?['mshv']?.toString() == mssv,
          orElse: () => null,
        );

    if (student == null) {
      setState(() {
        _lastScanned = code;
        _scanMessage = 'Không tìm thấy: $mssv';
        _scanSuccess = false;
      });
    } else {
      final id = student['hocvienid'] as int;
      final ho = student['ho']?.toString() ?? '';
      final ten = student['ten']?.toString() ?? '';
      setState(() {
        _lastScanned = code;
        _attendance[id] = true;
        _scanMessage = '$ho $ten'.trim();
        _scanSuccess = true;
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _lastScanned = null; _scanMessage = null; });
    });
  }

  void _goToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _QrReviewScreen(
          subject: widget.subject,
          classCode: widget.classCode,
          students: _students,
          attendance: _attendance,
          tkbParams: widget.tkbParams,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;
    final total = _students.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(top: false, child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Điểm danh bằng QR · ${widget.ngay}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                if (!_loadingList)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$presentCount/$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          // ── Camera ──
          Expanded(
            child: _loadingList
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF8C00)))
                : Stack(
                    children: [
                      MobileScanner(
                        controller: _scanner,
                        onDetect: _onDetect,
                      ),
                      // Khung ngắm
                      Center(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _scanMessage != null
                                  ? (_scanSuccess
                                      ? const Color(0xFF4CAF50)
                                      : Colors.red)
                                  : const Color(0xFFFF8C00),
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      // Góc khung
                      Center(child: _ScanFrame(success: _scanSuccess, hasMessage: _scanMessage != null)),
                      // Feedback scan
                      if (_scanMessage != null)
                        Positioned(
                          bottom: 100,
                          left: 32,
                          right: 32,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: _scanSuccess
                                  ? const Color(0xFF4CAF50)
                                  : Colors.red,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 12,
                                    offset: Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _scanSuccess
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _scanMessage!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // Hướng dẫn
                      const Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Text(
                          'Đưa mã QR vào khung để điểm danh',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Nút xem danh sách ──
          if (!_loadingList)
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _goToReview,
                  icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
                  label: Text(
                    'Xem danh sách ($presentCount/$total đã điểm)',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}

// ═══════════════════════════════════════════════════════
// SCREEN 2 — Review & Save
// ═══════════════════════════════════════════════════════
class _QrReviewScreen extends StatefulWidget {
  final String subject;
  final String classCode;
  final List<Map<String, dynamic>> students;
  final Map<int, bool> attendance;
  final Map<String, dynamic> tkbParams;

  const _QrReviewScreen({
    required this.subject,
    required this.classCode,
    required this.students,
    required this.attendance,
    required this.tkbParams,
  });

  @override
  State<_QrReviewScreen> createState() => _QrReviewScreenState();
}

class _QrReviewScreenState extends State<_QrReviewScreen> {
  bool _saving = false;

  int get _presentCount =>
      widget.attendance.values.where((v) => v).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final hocviens = widget.students.map((s) {
        final id = s['hocvienid'] as int;
        return {
          'hocvienid': id,
          'mshv': s['mshv'] ?? '',
          'ho': s['ho'] ?? '',
          'ten': s['ten'] ?? '',
          'hinhanh': s['hinhanh'],
          'diemdanhid': s['diemdanhid'],
          'hiendienyn': widget.attendance[id] ?? false,
        };
      }).toList();

      await ApiService.postDiemDanhLuu(
        tkb: widget.tkbParams,
        hocviens: hocviens,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lưu điểm danh thành công'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      // Pop cả 2 màn hình về schedule
      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.students.length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(top: false, child: Column(
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text('Xác nhận điểm danh',
                          style:
                              TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                // Stats
                _StatChip(
                  icon: Icons.check_circle,
                  label: '$_presentCount có mặt',
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.cancel,
                  label: '${total - _presentCount} vắng',
                  color: Colors.red,
                ),
              ],
            ),
          ),

          // ── Danh sách ──
          Expanded(
            child: widget.students.isEmpty
                ? const Center(
                    child: Text('Không có sinh viên',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: widget.students.length,
                    itemBuilder: (ctx, i) {
                      final s = widget.students[i];
                      final id = s['hocvienid'] as int;
                      final present = widget.attendance[id] ?? false;
                      final ho = s['ho']?.toString() ?? '';
                      final ten = s['ten']?.toString() ?? '';
                      final mssv = s['mshv']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () => setState(
                            () => widget.attendance[id] = !present),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: present
                                ? const Color(0xFFE8F5E9)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: present
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFEEEEEE),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('${i + 1}.',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[400])),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('$ho $ten'.trim(),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(mssv,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey)),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  present
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked,
                                  key: ValueKey(present),
                                  color: present
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[400],
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Nút lưu ──
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, color: Colors.white),
                label: const Text('Lưu điểm danh',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// ── Widgets phụ ────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final bool hasMessage;
  final bool success;
  const _ScanFrame({required this.hasMessage, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = hasMessage
        ? (success ? const Color(0xFF4CAF50) : Colors.red)
        : const Color(0xFFFF8C00);
    const size = 220.0;
    const corner = 24.0;
    const thick = 4.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(top: 0, left: 0,
              child: _Corner(color: color, thick: thick, corner: corner,
                  top: true, left: true)),
          // Top-right
          Positioned(top: 0, right: 0,
              child: _Corner(color: color, thick: thick, corner: corner,
                  top: true, left: false)),
          // Bottom-left
          Positioned(bottom: 0, left: 0,
              child: _Corner(color: color, thick: thick, corner: corner,
                  top: false, left: true)),
          // Bottom-right
          Positioned(bottom: 0, right: 0,
              child: _Corner(color: color, thick: thick, corner: corner,
                  top: false, left: false)),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final Color color;
  final double thick;
  final double corner;
  final bool top;
  final bool left;
  const _Corner({
    required this.color,
    required this.thick,
    required this.corner,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: corner,
      height: corner,
      child: CustomPaint(
        painter: _CornerPainter(
            color: color, thick: thick, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool top;
  final bool left;
  const _CornerPainter(
      {required this.color,
      required this.thick,
      required this.top,
      required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.thick != thick;
}
