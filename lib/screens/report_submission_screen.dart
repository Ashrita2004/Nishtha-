import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ReportSubmissionScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;
  final String gatePass;

  const ReportSubmissionScreen({
    required this.taskId,
    required this.taskTitle,
    required this.gatePass,
    super.key,
  });

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _reportText;
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    final imagePath =
        'task_reports/${widget.taskId}_${widget.gatePass}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(imagePath);
    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete the report description.'),
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _uploadImage();
      }

      // Proper atomic transaction: Write report, then update status
      final taskRef = FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.taskId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final reportRef = taskRef.collection('reports').doc();
        transaction.set(reportRef, {
          'reportText': _reportText,
          'submittedAt': FieldValue.serverTimestamp(),
          'submittedBy': widget.gatePass,
          'photoUrl': photoUrl,
        });
        transaction.update(taskRef, {
          'status': 'Completed',
          'rejectionReason': FieldValue.delete(),
        });
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Submit Report: ${widget.taskTitle}'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Report for: ${widget.taskTitle}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  minLines: 4,
                  maxLines: 7,
                  decoration: const InputDecoration(
                    labelText: 'Describe actions taken',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Please enter details'
                      : null,
                  onSaved: (val) => _reportText = val?.trim(),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo),
                  label: const Text('Select Photo (optional)'),
                  onPressed: _isLoading ? null : _pickImage,
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, height: 180),
                    ),
                  ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit Report'),
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
