import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';

// ── Model ────────────────────────────────────────────────
class ExamItem {
  final int ltid;
  final DateTime ngayThi;
  final String gioBatDau;
  final int thoiGian;
  final String phongten;
  final String loaiThi;
  final String mhten;
  final String hkma;
  final String hkten;

  ExamItem.fromJson(Map<String, dynamic> j)
      : ltid = j['ltid'] as int,
        ngayThi = DateTime.parse(j['ngayThi'] as String),
        gioBatDau = j['gioBatDau'] as String? ?? '',
        thoiGian = j['thoiGian'] as int? ?? 0,
        phongten = j['phongten'] as String? ?? '',
        loaiThi = j['loaiThi'] as String? ?? '',
        mhten = j['mhten'] as String? ?? '',
        hkma = j['hkma'] as String? ?? '',
        hkten = j['hkten'] as String? ?? '';

  String get ngayThiFormatted =>
      '${ngayThi.day.toString().padLeft(2, '0')}/'
      '${ngayThi.month.toString().padLeft(2, '0')}/'
      '${ngayThi.year}';
}

// ── Screen ───────────────────────────────────────────────
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  List<ExamItem> _allExams = [];
  List<({String hkma, String hkten})> _semesters = [];
  String _selectedHkma = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Lấy ngaybatdau sớm nhất từ danh sách học kỳ
      final hockyList = await ApiService.getHocKy();
      String ngayBD = '2010-01-01';
      if (hockyList.isNotEmpty) {
        final starts = hockyList
            .map((e) => e['ngaybatdau'] as String?)
            .whereType<String>()
            .map((s) => s.substring(0, 10))
            .toList()..sort();
        if (starts.isNotEmpty) ngayBD = starts.first;
      }
      final data = await ApiService.getExams(ngayBD);

      final exams = data.map((e) => ExamItem.fromJson(e as Map<String, dynamic>)).toList();
      // Sắp xếp theo ngày thi
      exams.sort((a, b) => a.ngayThi.compareTo(b.ngayThi));

      // Lấy danh sách học kỳ duy nhất, giữ thứ tự mới → cũ
      final seen = <String>{};
      final semesters = exams
          .map((e) => (hkma: e.hkma, hkten: e.hkten))
          .where((s) => seen.add(s.hkma))
          .toList()
          .reversed
          .toList();

      if (!mounted) return;
      setState(() {
        _allExams = exams;
        _semesters = semesters;
        _selectedHkma = semesters.isNotEmpty ? semesters.first.hkma : '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  List<ExamItem> get _filtered =>
      _allExams.where((e) => e.hkma == _selectedHkma).toList();

  @override
  Widget build(BuildContext context) {
    final exams = _filtered;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Lịch thi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Text(
                //   'MSSV: ${AppSession.instance.hocVien?.mshv ?? ''}',
                //   style: const TextStyle(color: Colors.white70, fontSize: 13),
                // ),
                const SizedBox(height: 16),

                // Semester chips
                if (!_loading && _semesters.isNotEmpty)
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _semesters.length,
                      itemBuilder: (context, i) {
                        final sem = _semesters[i];
                        final isSelected = sem.hkma == _selectedHkma;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedHkma = sem.hkma),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              sem.hkten,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Color(0xFFE65100)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE65100)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color.fromARGB(255, 0, 0, 0)),
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchExams,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFE65100)),
                              child: const Text('Thử lại',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      )
                    : exams.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.event_busy,
                                    size: 64, color: Color.fromARGB(255, 0, 0, 0)),
                                SizedBox(height: 12),
                                Text('Không có lịch thi',
                                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            itemCount: exams.length,
                            itemBuilder: (context, i) =>
                                _ExamCard(exam: exams[i]),
                          ),
          ),
        ],
      )),
    );
  }
}

// ── Exam Card ─────────────────────────────────────────────
class _ExamCard extends StatelessWidget {
  final ExamItem exam;
  const _ExamCard({required this.exam});

  Color get _loaiColor => exam.loaiThi.contains('Giữa')
      ? const Color(0xFF2196F3)
      : const Color(0xFFFF8C00);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Thanh màu trái
          Container(
            width: 5,
            height: 100,
            decoration: BoxDecoration(
              color: _loaiColor,
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên môn + badge loại thi
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exam.mhten,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: _loaiColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          exam.loaiThi,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _loaiColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Ngày + giờ
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(exam.ngayThiFormatted,
                          style: const TextStyle(
                              fontSize: 12, color: Color.fromARGB(255, 0, 0, 0))),
                      const SizedBox(width: 14),
                      const Icon(Icons.access_time,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(exam.gioBatDau,
                          style: const TextStyle(
                              fontSize: 12, color: Color.fromARGB(255, 0, 0, 0))),
                      const SizedBox(width: 14),
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text('${exam.thoiGian} phút',
                          style: const TextStyle(
                              fontSize: 12, color: Color.fromARGB(255, 0, 0, 0))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Phòng thi
                  Row(
                    children: [
                      const Icon(Icons.room,
                          size: 13, color: Color(0xFFE65100)),
                      const SizedBox(width: 4),
                      Text(exam.phongten,
                          style: const TextStyle(
                              fontSize: 12, color: Color.fromARGB(255, 0, 0, 0))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
