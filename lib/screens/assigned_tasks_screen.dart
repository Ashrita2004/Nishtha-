import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'report_submission_screen.dart';

class AssignedTasksScreen extends StatelessWidget {
  final String gatePass;

  const AssignedTasksScreen({required this.gatePass, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedTo', isEqualTo: gatePass)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Assigned Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
        elevation: 2,
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

            // Exclude 'Completed' and 'Approved' tasks
            final docs = (snapshot.data?.docs ?? []).where((doc) {
              final m = doc.data() as Map<String, dynamic>;
              final status = m['status']?.toString() ?? "";
              final assignedTo = m['assignedTo']?.toString() ?? "";
              // Double check for assignment and status (prevent "leaks")
              return assignedTo == gatePass &&
                  status != 'Completed' &&
                  status != 'Approved';
            }).toList();

            if (docs.isEmpty) {
              return const Center(child: Text('No tasks assigned to you.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 9),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;
                final docId = docs[index].id;
                final title = data['title'] ?? 'No Title';
                final description = data['description'] ?? '';
                final status = data['status'] ?? '';
                final assignedByName =
                    data['assignedByName'] ?? data['assignedBy'] ?? '';
                final isHazardous = data['isHazardous'] == true;
                final rejectionReason = data['rejectionReason'] ?? '';

                // Handle due date
                DateTime? dueDate;
                if (data['dueDate'] != null) {
                  if (data['dueDate'] is Timestamp) {
                    dueDate = (data['dueDate'] as Timestamp).toDate();
                  } else if (data['dueDate'] is DateTime) {
                    dueDate = data['dueDate'];
                  }
                }

                return Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(13),
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (status == "Rejected")
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Chip(
                              label: const Text(
                                "Rejected",
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red.shade400,
                              labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                description,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (dueDate != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                'Due Date: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                                style: TextStyle(
                                  color: Colors.blue.shade900,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          Text(
                            'Assigned by: $assignedByName',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Hazardous: ${isHazardous ? "Yes" : "No"}',
                            style: TextStyle(
                              color: isHazardous ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Status: $status',
                            style: TextStyle(
                              color: status == 'Rejected'
                                  ? Colors.red
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (status == "Rejected" &&
                              rejectionReason.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Rejection Reason: $rejectionReason",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      icon: const Icon(Icons.assignment_turned_in_outlined),
                      label: Text(
                        status == "Rejected" ? 'Resubmit' : 'Submit Report',
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportSubmissionScreen(
                              taskId: docId,
                              taskTitle: title,
                              gatePass: gatePass,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
