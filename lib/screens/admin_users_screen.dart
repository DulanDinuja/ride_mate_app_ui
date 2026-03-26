import 'package:flutter/material.dart';

import '../models/admin_user.dart';
import '../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _loading = true;
  String? _error;
  String _selectedRole = 'ALL';
  List<AdminUser> _users = const [];

  static const _roles = ['ALL', 'PASSENGER', 'DRIVER', 'ADMIN'];
  static const _statusActions = ['ACTIVE', 'INACTIVE', 'PENDING'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final role = _selectedRole == 'ALL' ? null : _selectedRole;
      final users = await AdminService.getAllUsers(role: role);
      if (!mounted) return;
      setState(() {
        _users = users;
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

  Future<void> _updateStatus(AdminUser user, String status) async {
    try {
      final updated = await AdminService.updateUserStatus(userId: user.id, status: status);
      if (!mounted) return;
      setState(() {
        _users = _users
            .map((item) => item.id == user.id ? item.copyWith(status: updated.status) : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated ${user.fullName} to $status')),
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

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.blueGrey;
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
            ElevatedButton(onPressed: _loadUsers, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text('Role Filter: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: _roles
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRole = value);
                    _loadUsers();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _users.isEmpty
                ? const Center(child: Text('No users found'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(user.fullName.isEmpty ? user.email : user.fullName),
                          subtitle: Text('${user.email}\nRole: ${user.userRole}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (status) => _updateStatus(user, status),
                            itemBuilder: (context) => _statusActions
                                .map((status) => PopupMenuItem(value: status, child: Text('Set $status')))
                                .toList(),
                            child: Chip(
                              label: Text(user.status),
                              backgroundColor: _statusColor(user.status).withValues(alpha: 0.15),
                              labelStyle: TextStyle(color: _statusColor(user.status)),
                            ),
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

