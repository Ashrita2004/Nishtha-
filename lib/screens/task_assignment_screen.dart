import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskAssignmentScreen extends StatefulWidget {
  final String assignedByGatePass;
  final String assignedByName;

  const TaskAssignmentScreen({
    required this.assignedByGatePass,
    required this.assignedByName,
    super.key,
  });

  @override
  State<TaskAssignmentScreen> createState() => _TaskAssignmentScreenState();
}

class _TaskAssignmentScreenState extends State<TaskAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedUser;
  String? _taskTitle;
  String? _taskDescription;
  bool _isHazardous = false;
  bool _isLoading = false;
  DateTime? _dueDate;
  String _searchTerm = '';
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    final usersQuery = await FirebaseFirestore.instance
        .collection('users')
        .get();
    List<Map<String, dynamic>> users = [];
    for (final doc in usersQuery.docs) {
      if (doc.id == widget.assignedByGatePass) continue; // Don't assign to self
      final data = doc.data();
      users.add({
        'gatePass': doc.id,
        'name': data['name'] ?? '',
        'role': data['role'] ?? '',
        'department': data['department'] ?? '',
        'available': data['available'] ?? true, // optional, default to true
      });
    }
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
    });
  }

  void _filterUsers(String search) {
    setState(() {
      _searchTerm = search;
      if (search.trim().isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        final lower = search.toLowerCase();
        _filteredUsers = _allUsers.where((user) {
          return user['name'].toString().toLowerCase().contains(lower) ||
              user['role'].toString().toLowerCase().contains(lower) ||
              user['department'].toString().toLowerCase().contains(lower) ||
              user['gatePass'].toString().toLowerCase().contains(lower);
        }).toList();
      }
      // If the selection gets filtered out, clear it
      if (_selectedUser != null &&
          !_filteredUsers.any((u) => u['gatePass'] == _selectedUser)) {
        _selectedUser = null;
      }
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _assignTask() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) {
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a due date.')),
        );
      }
      return;
    }
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': _taskTitle,
        'description': _taskDescription,
        'assignedTo': _selectedUser,
        'status': 'Assigned',
        'assignedBy': widget.assignedByGatePass,
        'assignedByName': widget.assignedByName,
        'createdAt': FieldValue.serverTimestamp(),
        'dueDate': Timestamp.fromDate(_dueDate!),
        'isHazardous': _isHazardous,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task assigned successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Task assignment failed! $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort so available users appear above unavailable users (optional)
    _filteredUsers.sort(
      (a, b) =>
          (b['available'] == true ? 1 : 0) - (a['available'] == true ? 1 : 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Assign Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: _allUsers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 18,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Search Employee',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterUsers,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Assign to',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedUser,
                        validator: (value) =>
                            value == null ? 'Please select a user' : null,
                        isExpanded: true,
                        onChanged: (val) => setState(() => _selectedUser = val),
                        items: _filteredUsers.map((user) {
                          final isAvailable = user['available'] == true;
                          return DropdownMenuItem<String>(
                            value: isAvailable ? user['gatePass'] : null,
                            enabled: isAvailable,
                            child: Text(
                              '${user['name']} (${user['role']}${user['department'].toString().isNotEmpty ? ' - ${user['department']}' : ''})'
                              '${isAvailable ? '' : ' (Unavailable)'}',
                              style: TextStyle(
                                color: isAvailable ? null : Colors.grey,
                                fontStyle: isAvailable
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Task Title',
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => _taskTitle = val?.trim(),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Enter task title'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Task Description',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 2,
                        maxLines: 6,
                        onSaved: (val) => _taskDescription = val?.trim(),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Enter task description'
                            : null,
                      ),
                      const SizedBox(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Due Date',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _dueDate != null
                              ? DateFormat('yyyy-MM-dd').format(_dueDate!)
                              : 'Select due date',
                          style: TextStyle(
                            color: _dueDate != null
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _isLoading ? null : _pickDueDate,
                        ),
                        onTap: _isLoading ? null : _pickDueDate,
                      ),
                      const SizedBox(height: 18),
                      SwitchListTile(
                        title: Text(
                          'Mark as Hazardous',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _isHazardous,
                        onChanged: (val) =>
                            setState(() => _isHazardous = val ?? false),
                        activeColor: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_task_rounded),
                          label: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Assign Task',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                          onPressed: _isLoading ? null : _assignTask,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
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
