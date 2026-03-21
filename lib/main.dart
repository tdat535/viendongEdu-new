import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/hv_home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/exam_screen.dart';
import 'screens/tuition_screen.dart';
import 'screens/grades_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/lephi_screen.dart';
import 'screens/gv_home_screen.dart';
import 'screens/gv_schedule_screen.dart';
import 'screens/gv_lophoc_screen.dart';
import 'screens/gv_lichthi_screen.dart';
import 'screens/gv_quanly_lop_screen.dart';
import 'screens/capbu_screen.dart';
import 'screens/change_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ViendongEdu',
      theme: ThemeData(primarySwatch: Colors.orange),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/schedule': (context) => const ScheduleScreen(),
        '/exam': (context) => const ExamScreen(),
        '/tuition': (context) => const TuitionScreen(),
        '/grades': (context) => const GradesScreen(),
        '/classes': (context) => const ClassesScreen(),
        '/lephi': (context) => const LePhiScreen(),
        '/gv_home': (context) => const GvHomeScreen(),
        '/gv_schedule': (context) => const GvScheduleScreen(),
        '/gv_lophoc': (context) => const GvLopHocScreen(),
        '/gv_lichthi': (context) => const GvLichThiScreen(),
        '/gv_quanly_lop': (context) => const GvQuanLyLopScreen(),
        '/capbu': (context) => const CapBuScreen(),
        '/change_password': (context) => const ChangePasswordScreen(),
      },
    );
  }
}