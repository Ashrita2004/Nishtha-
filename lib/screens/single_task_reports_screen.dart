import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SingleTaskReportsScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const SingleTaskReportsScreen({
    required this.taskId,
    required this.taskTitle,
    super.key,
  });

  @override
  State<SingleTaskReportsScreen> createState() =>
      _SingleTaskReportsScreenState();
}

class _SingleTaskReportsScreenState extends State<SingleTaskReportsScreen> {
  final _remarkController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _processReviewAction(String action, String reportDocId) async {
    if (_isSubmitting) return;
    final remark = _remarkController.text.trim();
    if (action == "Rejected" && remark.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Remark is required to reject.")),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final taskRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId);

      await taskRef.update({
        'status': action,
        if (action == 'Rejected')
          'rejectionReason': remark
        else
          'rejectionReason': FieldValue.delete(),
        if (action == 'Approved') 'approvalRemark': remark,
      });

      // (Optional: mark the report document with the manager's verdict)
      if (action == 'Rejected' || action == 'Approved') {
        final reportRef = taskRef.collection('reports').doc(reportDocId);
        await reportRef.update({
          'managerStatus': action,
          'managerRemark': remark,
          'managerReviewedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Report $action!')));
      Navigator.of(context).pop(); // Go back to review list
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsStream = FirebaseFirestore.instance
        .collection('tasks')
        .doc(widget.taskId)
        .collection('reports')
        .orderBy('submittedAt', descending: true)
        .snapshots();

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Reports for: ${widget.taskTitle}'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading reports.'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No reports submitted for this task.'),
            );
          }
          // We assume only one report per task. If many, you can approve/reject each.
          final data = docs.first.data()! as Map<String, dynamic>;
          final reportDocId = docs.first.id;
          final reportText = data['reportText'] ?? '';
          final photoUrl = data['photoUrl'] as String?;
          final submittedBy = data['submittedBy'] ?? '';
          final timestamp = (data['submittedAt'] as Timestamp?)?.toDate();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "By: $submittedBy",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (timestamp != null)
                  Text(
                    'At: ${timestamp.toLocal()}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const SizedBox(height: 12),
                Text(reportText, style: const TextStyle(fontSize: 16)),
                if (photoUrl != null && photoUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrl,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                TextFormField(
                  controller: _remarkController,
                  decoration: InputDecoration(
                    labelText: "Manager's Remark (required for rejection)",
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 5,
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.check),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Approve'),
                        onPressed: _isSubmitting
                            ? null
                            : () =>
                                  _processReviewAction('Approved', reportDocId),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.close),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Reject'),
                        onPressed: _isSubmitting
                            ? null
                            : () =>
                                  _processReviewAction('Rejected', reportDocId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
