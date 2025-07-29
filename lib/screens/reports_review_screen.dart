import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'single_task_reports_screen.dart';

class ReportsReviewScreen extends StatelessWidget {
  final String gatePass; // of manager

  const ReportsReviewScreen({required this.gatePass, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('status', isEqualTo: 'Completed')
        .where(
          'assignedBy',
          isEqualTo: gatePass,
        ) // <-- Only your assigned tasks
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports to Review',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: tasksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading tasks: ${snapshot.error}'),
              );
            }

            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? '';
              return status == 'Completed';
            }).toList();

            if (docs.isEmpty) {
              return const Center(child: Text('No completed tasks to review.'));
            }

            return ListView.separated(
              itemCount: docs.length,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                final docId = docs[index].id;
                final title = data['title'] ?? 'No Title';
                final assignedTo = data['assignedTo'] ?? 'N/A';
                final assignedBy =
                    data['assignedByName'] ?? data['assignedBy'] ?? '';
                final description = data['description'] ?? '';

                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Assigned to: $assignedTo\nAssigned by: $assignedBy\n$description',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SingleTaskReportsScreen(
                          taskId: docId,
                          taskTitle: title,
                        ),
                      ),
                    );
                  },
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
