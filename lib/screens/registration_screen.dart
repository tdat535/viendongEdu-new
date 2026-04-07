import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/app_session.dart';

// ── Models ─────────────────────────────────────────────
class _Semester {
  final int id;
  final String ma;
  final String ten;
  const _Semester({required this.id, required this.ma, required this.ten});
}

class _DotDangKy {
  final int id;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;

  _DotDangKy.fromJson(Map<String, dynamic> j)
      : id = j['id'] as int,
        ngayBatDau = DateTime.parse(j['ngayBatDau'] as String).toLocal(),
        ngayKetThuc = DateTime.parse(j['ngayKetThuc'] as String).toLocal();

  bool get isOpen {
    final now = DateTime.now();
    return now.isAfter(ngayBatDau) && now.isBefore(ngayKetThuc);
  }

  String get thoiGian {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(ngayBatDau)} – ${fmt(ngayKetThuc)}';
  }
}

class _MonHoc {
  final int mhid;
  final String mhma;
  final String mhten;
  final int sotc;
  final int sotclt;
  final int sotcth;
  final String gvten;
  final String csten;

  _MonHoc.fromJson(Map<String, dynamic> j)
      : mhid = j['mhid'] as int,
        mhma = j['mhma'] as String? ?? '',
        mhten = j['mhten'] as String? ?? '',
        sotc = j['mhsotc'] as int? ?? 0,
        sotclt = j['mhsotclt'] as int? ?? 0,
        sotcth = j['mhsotcth'] as int? ?? 0,
        gvten = j['gvten'] as String? ?? '',
        csten = j['csten'] as String? ?? '';
}

// ── Screen ─────────────────────────────────────────────
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  List<_Semester> _semesters = [];
  _Semester? _selected;
  _DotDangKy? _dot;
  List<_MonHoc> _monHocs = [];
  // mhid của các môn đã đăng ký
  final Set<int> _registered = {};
  // mhid đang xử lý (loading)
  final Set<int> _processing = {};

  bool _loadingSemesters = true;
  bool _loadingData = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSemesters();
  }

  Future<void> _fetchSemesters() async {
    setState(() { _loadingSemesters = true; _error = null; });
    try {
      final data = await ApiService.getHocKy();
      final sems = data
          .map((e) => _Semester(
                id: e['id'] as int,
                ma: e['ma'] as String? ?? '',
                ten: e['ten'] as String? ?? '',
              ))
          .toList();
      sems.sort((a, b) => b.id.compareTo(a.id));
      if (!mounted) return;
      setState(() { _semesters = sems; _loadingSemesters = false; });
      if (sems.isNotEmpty) _selectSemester(sems.first);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingSemesters = false; _error = e.toString(); });
    }
  }

  Future<void> _selectSemester(_Semester sem) async {
    setState(() {
      _selected = sem;
      _loadingData = true;
      _dot = null;
      _monHocs = [];
      _registered.clear();
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getDotDangKy(sem.id),
        ApiService.getMonHocDuKien(sem.id),
        ApiService.getKetQuaDangKy(sem.id),
      ]);
      if (!mounted) return;
      final dots = results[0] as List<dynamic>;
      final monList = results[1] as List<dynamic>;
      final ketQuaList = results[2] as List<dynamic>;
      final registeredIds = ketQuaList
          .map((e) => (e as Map<String, dynamic>)['monhocid'] as int?)
          .whereType<int>()
          .toSet();
      setState(() {
        _dot = dots.isNotEmpty ? _DotDangKy.fromJson(dots.first as Map<String, dynamic>) : null;
        _monHocs = monList.map((e) => _MonHoc.fromJson(e as Map<String, dynamic>)).toList();
        _registered
          ..clear()
          ..addAll(registeredIds);
        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingData = false; _error = e.toString(); });
    }
  }

  Future<void> _toggleDangKy(_MonHoc mon) async {
    final dot = _dot;
    final hv = AppSession.instance.hocVien;
    if (dot == null || hv == null) return;

    if (!dot.isOpen) {
      _showSnack('Đợt đăng ký chưa mở hoặc đã kết thúc.', isError: true);
      return;
    }

    setState(() => _processing.add(mon.mhid));
    final isRegistered = _registered.contains(mon.mhid);
    try {
      if (isRegistered) {
        await ApiService.deleteDangKyMon(
          hocvienid: hv.id.toString(),
          dotdkid: dot.id.toString(),
          monhocid: mon.mhid.toString(),
          hockyid: _selected!.id.toString(),
        );
        if (!mounted) return;
        setState(() => _registered.remove(mon.mhid));
        _showSnack('Đã hủy đăng ký ${mon.mhten}');
      } else {
        await ApiService.postDangKyMon(
          hocvienid: hv.id.toString(),
          dotdkid: dot.id.toString(),
          monhocid: mon.mhid.toString(),
          hockyid: _selected!.id.toString(),
        );
        if (!mounted) return;
        setState(() => _registered.add(mon.mhid));
        _showSnack('Đăng ký thành công ${mon.mhten}');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _processing.remove(mon.mhid));
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        top: false,
        child: Column(
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
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                        'Đăng ký môn học',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Dropdown học kỳ
                  if (!_loadingSemesters && _semesters.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_Semester>(
                          value: _selected,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          iconEnabledColor: const Color(0xFFE65100),
                          icon: const Icon(Icons.expand_more_rounded, size: 20),
                          isDense: true,
                          style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          selectedItemBuilder: (_) => _semesters
                              .map((s) => Center(
                                    child: Text(s.ten,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Color(0xFFE65100),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600)),
                                  ))
                              .toList(),
                          items: _semesters
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.ten,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (s) {
                            if (s != null) _selectSemester(s);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Dot info ──
            if (_dot != null) _buildDotInfo(),

            // ── Body ──
            Expanded(
              child: _loadingSemesters
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE65100)))
                  : _error != null && _semesters.isEmpty
                      ? _buildError()
                      : _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotInfo() {
    final dot = _dot!;
    final open = dot.isOpen;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: open ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
        border: Border.all(
            color: open ? const Color(0xFF4CAF50) : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            open ? Icons.lock_open_rounded : Icons.lock_rounded,
            color: open ? const Color(0xFF2E7D32) : Colors.grey[600],
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? 'Đang mở đăng ký' : 'Đợt đăng ký đã đóng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: open ? const Color(0xFF2E7D32) : Colors.grey[800],
                  ),
                ),
                Text(
                  dot.thoiGian,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingData) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE65100)));
    }
    if (_error != null) return _buildError();
    if (_dot == null) {
      return const Center(
        child: Text(
          'Không có đợt đăng ký cho học kỳ này.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    if (_monHocs.isEmpty) {
      return const Center(
        child: Text('Không có môn học dự kiến.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _monHocs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _buildMonCard(_monHocs[i]),
    );
  }

  Widget _buildMonCard(_MonHoc mon) {
    final isRegistered = _registered.contains(mon.mhid);
    final isProcessing = _processing.contains(mon.mhid);
    final canRegister = _dot?.isOpen ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRegistered
              ? const Color(0xFF4CAF50)
              : const Color(0xFFEEEEEE),
          width: isRegistered ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    mon.mhten,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (isRegistered) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Đã đăng ký',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            _infoRow(Icons.tag_rounded, mon.mhma),
            _infoRow(Icons.person_outline_rounded,
                mon.gvten.isNotEmpty ? mon.gvten : '–'),
            _infoRow(Icons.location_on_outlined, mon.csten),
            _infoRow(
              Icons.star_border_rounded,
              '${mon.sotc} tín chỉ'
              '${mon.sotclt > 0 ? '  ·  LT: ${mon.sotclt}' : ''}'
              '${mon.sotcth > 0 ? '  ·  TH: ${mon.sotcth}' : ''}',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: isProcessing
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Color(0xFFE65100)),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: canRegister ? () => _toggleDangKy(mon) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isRegistered
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE65100),
                        foregroundColor: isRegistered
                            ? const Color(0xFFC62828)
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: Colors.grey.shade200,
                      ),
                      child: Text(
                        isRegistered ? 'Hủy đăng ký' : 'Đăng ký',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFFE65100)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error ?? 'Có lỗi xảy ra',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchSemesters,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100)),
                child: const Text('Thử lại',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
}
