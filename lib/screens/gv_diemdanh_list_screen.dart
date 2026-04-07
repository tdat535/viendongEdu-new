// import 'package:flutter/material.dart';

// String _vnSortList(String s) => s
//     .toLowerCase()
//     .replaceAll(RegExp(r'[àáảãạăắặằẳẵâấầẩẫậ]'), 'a')
//     .replaceAll(RegExp(r'[èéẻẽẹêếềểễệ]'), 'e')
//     .replaceAll(RegExp(r'[ìíỉĩị]'), 'i')
//     .replaceAll(RegExp(r'[òóỏõọôốồổỗộơớờởỡợ]'), 'o')
//     .replaceAll(RegExp(r'[ùúủũụưứừửữự]'), 'u')
//     .replaceAll(RegExp(r'[ỳýỷỹỵ]'), 'y')
//     .replaceAll(RegExp(r'[đ]'), 'dz');

// List<Map<String, dynamic>> _sorted(List<Map<String, dynamic>> list) =>
//     list
//       ..sort((a, b) {
//         final ta = _vnSortList('${a['ho'] ?? ''} ${a['ten'] ?? ''}');
//         final tb = _vnSortList('${b['ho'] ?? ''} ${b['ten'] ?? ''}');
//         return ta.compareTo(tb);
//       });

// class GvDiemDanhListScreen extends StatefulWidget {
//   final String subject;
//   final String classCode;
//   final String ngay;
//   final Map<int, bool> attendance;
//   final List<dynamic> students;

//   const GvDiemDanhListScreen({
//     super.key,
//     required this.subject,
//     required this.classCode,
//     required this.ngay,
//     required this.attendance,
//     required this.students,
//   });

//   @override
//   State<GvDiemDanhListScreen> createState() => _GvDiemDanhListScreenState();
// }

// class _GvDiemDanhListScreenState extends State<GvDiemDanhListScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   late List<Map<String, dynamic>> _present;
//   late List<Map<String, dynamic>> _absent;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     final all = widget.students.map((s) => s as Map<String, dynamic>).toList();
//     _present = _sorted(
//         all.where((s) => widget.attendance[s['hocvienid'] as int? ?? -1] == true).toList());
//     _absent = _sorted(
//         all.where((s) => widget.attendance[s['hocvienid'] as int? ?? -1] != true).toList());
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         top: false,
//         child: Column(
//           children: [
//             // ── Header ──
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xFFE65100), Color(0xFFFF8C00)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius:
//                     BorderRadius.vertical(bottom: Radius.circular(24)),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: const Icon(Icons.arrow_back_ios,
//                             color: Colors.white, size: 20),
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Danh sách điểm danh',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   // ── TabBar ──
//                   TabBar(
//                     controller: _tabController,
//                     indicatorColor: Colors.white,
//                     indicatorWeight: 3,
//                     labelColor: Colors.white,
//                     unselectedLabelColor: Colors.white60,
//                     labelStyle: const TextStyle(
//                         fontWeight: FontWeight.w700, fontSize: 14),
//                     unselectedLabelStyle: const TextStyle(
//                         fontWeight: FontWeight.w500, fontSize: 14),
//                     tabs: [
//                       Tab(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.check_circle_rounded, size: 16),
//                             const SizedBox(width: 6),
//                             Text('Có mặt  ${_present.length}'),
//                           ],
//                         ),
//                       ),
//                       Tab(
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.cancel_rounded, size: 16),
//                             const SizedBox(width: 6),
//                             Text('Vắng  ${_absent.length}'),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             // ── Content ──
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _StudentList(students: _present, isPresent: true),
//                   _StudentList(students: _absent, isPresent: false),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ── Student List ──────────────────────────────────────────
// class _StudentList extends StatelessWidget {
//   final List<Map<String, dynamic>> students;
//   final bool isPresent;
//   const _StudentList({required this.students, required this.isPresent});

//   @override
//   Widget build(BuildContext context) {
//     final color =
//         isPresent ? const Color(0xFF43A047) : const Color(0xFFE53935);

//     if (students.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               isPresent
//                   ? Icons.how_to_reg_rounded
//                   : Icons.person_off_rounded,
//               size: 64,
//               color: Colors.grey[300],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               isPresent
//                   ? 'Không có sinh viên có mặt'
//                   : 'Không có sinh viên vắng',
//               style: TextStyle(color: Colors.grey[400], fontSize: 14),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
//       itemCount: students.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (_, i) {
//         final s = students[i];
//         final ho = s['ho']?.toString() ?? '';
//         final ten = s['ten']?.toString() ?? '';
//         final name =
//             '$ho $ten'.trim().isEmpty ? '–' : '$ho $ten'.trim();
//         final mssv = s['mshv']?.toString() ?? '';

//         return Container(
//           padding:
//               const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border(
//               left: BorderSide(color: color, width: 4),
//             ),
//             boxShadow: const [
//               BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 4,
//                   offset: Offset(0, 2)),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 30,
//                 height: 30,
//                 decoration: BoxDecoration(
//                   color: color.withValues(alpha: 0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text(
//                     '${i + 1}',
//                     style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.bold,
//                         color: color),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(name,
//                         style: const TextStyle(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600)),
//                     if (mssv.isNotEmpty)
//                       Text(mssv,
//                           style: const TextStyle(
//                               fontSize: 12, color: Colors.grey)),
//                   ],
//                 ),
//               ),
//               Icon(
//                 isPresent
//                     ? Icons.check_circle_rounded
//                     : Icons.cancel_rounded,
//                 color: color,
//                 size: 22,
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
