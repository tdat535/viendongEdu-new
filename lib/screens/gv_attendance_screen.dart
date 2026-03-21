import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/snack.dart';

String _vnSort(String s) => s.toLowerCase()
    .replaceAll(RegExp(r'[àáảãạăắặằẳẵâấầẩẫậ]'), 'a')
    .replaceAll(RegExp(r'[èéẻẽẹêếềểễệ]'), 'e')
    .replaceAll(RegExp(r'[ìíỉĩị]'), 'i')
    .replaceAll(RegExp(r'[òóỏõọôốồổỗộơớờởỡợ]'), 'o')
    .replaceAll(RegExp(r'[ùúủũụưứừửữự]'), 'u')
    .replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y')
    .replaceAll(RegExp(r'[đ]'), 'dz'); // đ nằm sau d, trước e

class GvAttendanceScreen extends StatefulWidget {
  final String subject;
  final String classCode;
  final String ngay;
  final List<dynamic> students;
  final Map<String, dynamic> tkbParams;

  const GvAttendanceScreen({
    super.key,
    required this.subject,
    required this.classCode,
    required this.ngay,
    required this.students,
    required this.tkbParams,
  });

  @override
  State<GvAttendanceScreen> createState() => _GvAttendanceScreenState();
}

class _GvAttendanceScreenState extends State<GvAttendanceScreen> {
  // hocvienid → hiendienyn
  late Map<int, bool> _attendance;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.students.sort((a, b) {
      final ta = _vnSort((a as Map<String, dynamic>)['ten']?.toString() ?? '');
      final tb = _vnSort((b as Map<String, dynamic>)['ten']?.toString() ?? '');
      return ta.compareTo(tb);
    });
    _attendance = {
      for (final s in widget.students)
        (s as Map<String, dynamic>)['hocvienid'] as int:
            (s['hiendienyn'] as bool? ?? false),
    };
  }

  void _toggle(int hocvienid) =>
      setState(() => _attendance[hocvienid] = !(_attendance[hocvienid] ?? false));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final hocviens = widget.students.map((s) {
        final m = s as Map<String, dynamic>;
        final id = m['hocvienid'] as int;
        return {
          'hocvienid': id,
          'mshv': m['mshv'] ?? '',
          'ho': m['ho'] ?? '',
          'ten': m['ten'] ?? '',
          'hinhanh': m['hinhanh'],
          'diemdanhid': m['diemdanhid'],
          'hiendienyn': _attendance[id] ?? false,
        };
      }).toList();

      await ApiService.postDiemDanhLuu(
        tkb: widget.tkbParams,
        hocviens: hocviens,
      );

      if (!mounted) return;
      showSuccessSnack(context, 'Lưu điểm danh thành công');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;
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
                      'Điểm danh',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(widget.subject,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(widget.classCode,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                // Thống kê nhanh
                Row(
                  children: [
                    _StatChip(
                        label: 'Có mặt',
                        value: '$presentCount',
                        color: const Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    _StatChip(
                        label: 'Vắng',
                        value: '${total - presentCount}',
                        color: const Color(0xFFF44336)),
                    const SizedBox(width: 8),
                    _StatChip(
                        label: 'Tổng',
                        value: '$total',
                        color: Colors.white),
                  ],
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: widget.students.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Không có sinh viên',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: widget.students.length,
                    itemBuilder: (ctx, i) {
                      final s =
                          widget.students[i] as Map<String, dynamic>;
                      final id = s['hocvienid'] as int;
                      final present = _attendance[id] ?? false;
                      return _StudentRow(
                        index: i + 1,
                        data: s,
                        present: present,
                        onTap: () => _toggle(id),
                      );
                    },
                  ),
          ),

          // ── Save button ──
          if (widget.students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text(
                    'Lưu điểm danh',
                    style: TextStyle(
                        fontSize: 16,
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

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: $value',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final bool present;
  final VoidCallback onTap;
  const _StudentRow(
      {required this.index,
      required this.data,
      required this.present,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ho = data['ho']?.toString() ?? '';
    final ten = data['ten']?.toString() ?? '';
    final name = '$ho $ten'.trim().isEmpty ? '–' : '$ho $ten'.trim();
    final mssv = data['mshv']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: present
              ? const Color(0xFFE8F5E9)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: present
                ? const Color(0xFF4CAF50)
                : const Color(0xFFEEEEEE),
            width: present ? 1.5 : 1,
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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: present
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('$index',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: present
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE65100))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (mssv.isNotEmpty)
                    Text(mssv,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(
              present ? Icons.check_circle : Icons.radio_button_unchecked,
              color: present
                  ? const Color(0xFF4CAF50)
                  : Colors.grey[400],
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
