import 'package:flutter/material.dart';

import '../models/admin_driver_profile.dart';
import '../services/admin_service.dart';

class AdminDriverApprovalsScreen extends StatefulWidget {
  const AdminDriverApprovalsScreen({super.key});

  @override
  State<AdminDriverApprovalsScreen> createState() => _AdminDriverApprovalsScreenState();
}

class _AdminDriverApprovalsScreenState extends State<AdminDriverApprovalsScreen> {
  bool _loading = true;
  String? _error;
  List<AdminDriverProfile> _drivers = const [];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final drivers = await AdminService.getPendingDrivers();
      if (!mounted) return;
      setState(() {
        _drivers = drivers;
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

  Future<void> _handleDecision(AdminDriverProfile driver, String status) async {
    final remarksController = TextEditingController();
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$status Driver'),
          content: TextField(
            controller: remarksController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
          ],
        );
      },
    );

    if (shouldSubmit != true) {
      remarksController.dispose();
      return;
    }

    try {
      await AdminService.approveDriver(
        driverProfileId: driver.id,
        accountStatus: status,
        remarks: remarksController.text,
      );
      remarksController.dispose();
      if (!mounted) return;

      setState(() {
        _drivers = _drivers.where((item) => item.id != driver.id).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver ${driver.id} updated to $status')),
      );
    } catch (e) {
      remarksController.dispose();
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
            ElevatedButton(onPressed: _loadDrivers, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDrivers,
      child: _drivers.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No pending driver approvals')),
              ],
            )
          : ListView.builder(
              itemCount: _drivers.length,
              itemBuilder: (context, index) {
                final driver = _drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.fullName.isEmpty ? 'Driver #${driver.id}' : driver.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Driver Profile ID: ${driver.id}'),
                        if (driver.email != null && driver.email!.isNotEmpty) Text('Email: ${driver.email}'),
                        if (driver.phoneNumber != null && driver.phoneNumber!.isNotEmpty)
                          Text('Phone: ${driver.phoneNumber}'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _handleDecision(driver, 'REJECTED'),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _handleDecision(driver, 'APPROVED'),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

