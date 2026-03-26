import 'package:flutter/material.dart';

import '../models/admin_feedback.dart';
import '../services/admin_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  bool _loading = true;
  String? _error;
  List<AdminFeedback> _feedbackItems = const [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final feedback = await AdminService.getAllFeedback();
      if (!mounted) return;
      setState(() {
        _feedbackItems = feedback;
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

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
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
            ElevatedButton(onPressed: _loadFeedback, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeedback,
      child: _feedbackItems.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No feedback found')),
              ],
            )
          : ListView.builder(
              itemCount: _feedbackItems.length,
              itemBuilder: (context, index) {
                final item = _feedbackItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.userFullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('User ID: ${item.userId} | Category: ${item.category}'),
                        const SizedBox(height: 6),
                        _buildStars(item.rating),
                        const SizedBox(height: 8),
                        Text(item.feedbackText),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

