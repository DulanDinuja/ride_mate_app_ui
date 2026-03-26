import 'package:flutter/material.dart';

import '../models/admin_report.dart';
import '../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  String? _error;
  String _selectedStatus = 'ALL';
  List<AdminReport> _reports = const [];

  static const _filterStatuses = ['ALL', 'PENDING', 'IN_REVIEW', 'RESOLVED', 'CLOSED'];
  static const _updateStatuses = ['IN_REVIEW', 'RESOLVED', 'CLOSED'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final status = _selectedStatus == 'ALL' ? null : _selectedStatus;
      final reports = await AdminService.getAllReports(status: status);
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(AdminReport report, String status) async {
    try {
      await AdminService.updateReportStatus(reportId: report.id, status: status);
      if (!mounted) return;
      setState(() {
        _reports = _reports
            .map((item) => item.id == report.id ? item.copyWith(status: status) : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report #${report.id} updated to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _loadReports, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Status Filter: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _filterStatuses
                      .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedStatus = value);
                    _loadReports();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _reports.isEmpty
                ? const Center(child: Text('No reports found'))
                : ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(report.subject),
                          subtitle: Text(
                            'User: ${report.userFullName} (#${report.userId})\n'
                            'Category: ${report.category}\n'
                            '${report.description}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (status) => _updateStatus(report, status),
                            itemBuilder: (context) => _updateStatuses
                                .map((status) => PopupMenuItem(value: status, child: Text(status)))
                                .toList(),
                            child: Chip(label: Text(report.status)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

