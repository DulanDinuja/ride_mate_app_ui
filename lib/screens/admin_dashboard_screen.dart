import 'package:flutter/material.dart';

import '../services/token_service.dart';
import 'admin_driver_approvals_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'get_started_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await TokenService.clearAll();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const GetStartedScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Console'),
          actions: [
            IconButton(
              tooltip: 'Logout',
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Users', icon: Icon(Icons.people_alt_outlined)),
              Tab(text: 'Drivers', icon: Icon(Icons.verified_user_outlined)),
              Tab(text: 'Reports', icon: Icon(Icons.report_problem_outlined)),
              Tab(text: 'Feedback', icon: Icon(Icons.reviews_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminUsersScreen(),
            AdminDriverApprovalsScreen(),
            AdminReportsScreen(),
            AdminFeedbackScreen(),
          ],
        ),
      ),
    );
  }
}

