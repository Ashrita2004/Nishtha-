import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TaskReassignScreen extends StatefulWidget {
  final String gatePass;

  const TaskReassignScreen({required this.gatePass, Key? key})
    : super(key: key);

  @override
  State<TaskReassignScreen> createState() => _TaskReassignScreenState();
}

class _TaskReassignScreenState extends State<TaskReassignScreen> {
  String? _selectedTaskId;
  Map<String, dynamic>? _selectedTaskData;
  String? _selectedNewUser;
  DateTime? _newDueDate;
  String? _reason;
  String _userSearchTerm = '';
  bool _isLoading = false;

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
      if (doc.id == widget.gatePass) continue; // skip self
      final data = doc.data();
      users.add({
        'gatePass': doc.id,
        'name': data['name'] ?? '',
        'role': data['role'] ?? '',
        'department': data['department'] ?? '',
        'available': data['available'] ?? true,
      });
    }
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
    });
  }

  void _filterUsers(String search) {
    setState(() {
      _userSearchTerm = search;
      if (search.trim().isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        final lower = search.toLowerCase();
        _filteredUsers = _allUsers
            .where(
              (user) =>
                  user['name'].toString().toLowerCase().contains(lower) ||
                  user['role'].toString().toLowerCase().contains(lower) ||
                  user['department'].toString().toLowerCase().contains(lower) ||
                  user['gatePass'].toString().toLowerCase().contains(lower),
            )
            .toList();
      }
      if (_selectedNewUser != null &&
          !_filteredUsers.any((u) => u['gatePass'] == _selectedNewUser)) {
        _selectedNewUser = null;
      }
    });
  }

  Future<void> _pickDueDate(BuildContext context) async {
    DateTime now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _newDueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _newDueDate = picked);
  }

  Future<void> _reassignTask() async {
    if (_selectedTaskId == null || _selectedNewUser == null) return;
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> updates = {
        'assignedTo': _selectedNewUser,
        'status': 'Assigned',
        'reassignedBy': widget.gatePass,
        'reassignedAt': FieldValue.serverTimestamp(),
      };
      if (_reason != null && _reason!.trim().isNotEmpty) {
        updates['reassignReason'] = _reason!.trim();
      }
      if (_newDueDate != null) {
        updates['dueDate'] = Timestamp.fromDate(_newDueDate!);
      }
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(_selectedTaskId)
          .update(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task reassigned successfully!')),
        );
        setState(() {
          _selectedTaskId = null;
          _selectedTaskData = null;
          _selectedNewUser = null;
          _newDueDate = null;
          _reason = null;
          _userSearchTerm = '';
          _filteredUsers = _allUsers;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reassign task: $e')));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tasksStream = FirebaseFirestore.instance
        .collection('tasks')
        .where('status', whereIn: ['Assigned', 'Rejected'])
        .where('assignedBy', isEqualTo: widget.gatePass)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reassign Task',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tasks to reassign.'));
          }

          // Show list OR show the reassign panel
          if (_selectedTaskId == null) {
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (ctx, i) {
                final data = docs[i].data()! as Map<String, dynamic>;
                final docId = docs[i].id;
                final title = data['title'] ?? '';
                final assignedTo = data['assignedTo'] ?? '';
                final dueDate = (data['dueDate'] is Timestamp)
                    ? (data['dueDate'] as Timestamp).toDate()
                    : null;
                final status = data['status'] ?? '';

                // To show full "Assigned to" info:
                final userInfo = _allUsers.firstWhere(
                  (u) => u['gatePass'] == assignedTo,
                  orElse: () => {
                    'name': assignedTo,
                    'department': '',
                    'role': '',
                  },
                );
                final assignedToDisplay =
                    '${userInfo['name'] ?? assignedTo}'
                    '${userInfo['role'] != null && (userInfo['role'] as String).isNotEmpty ? ' (${userInfo['role']}' : ''}'
                    '${userInfo['department'] != null && (userInfo['department'] as String).isNotEmpty ? ' - ${userInfo['department']})' : (userInfo['role'] != null && (userInfo['role'] as String).isNotEmpty ? ')' : '')}'
                    ' | $assignedTo';

                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status == "Rejected")
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Chip(
                            label: const Text(
                              "Rejected",
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red.shade400,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned to: $assignedToDisplay'),
                      if (dueDate != null)
                        Text(
                          'Due: ${DateFormat('yyyy-MM-dd').format(dueDate)}',
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    child: const Text("Reassign"),
                    onPressed: () {
                      setState(() {
                        _selectedTaskId = docId;
                        _selectedTaskData = data;
                        _selectedNewUser = null;
                        _newDueDate = dueDate;
                        _reason = null;
                        _userSearchTerm = '';
                        _filteredUsers = _allUsers;
                      });
                    },
                  ),
                );
              },
            );
          }

          // --- Reassignment Form (with search bar) ---
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reassign Task: "${_selectedTaskData?['title'] ?? ''}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Search Employee',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterUsers,
                  initialValue: _userSearchTerm,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select new employee',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedNewUser,
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedNewUser = val),
                  validator: (val) => val == null ? 'Select a user' : null,
                  items: _filteredUsers.map((user) {
                    final bool isAvailable = user['available'] == true;
                    return DropdownMenuItem<String>(
                      value: isAvailable ? user['gatePass'] : null,
                      enabled: isAvailable,
                      child: Text(
                        '${user['name']} (${user['role']}${user['department'].toString().isNotEmpty ? ' - ${user['department']}' : ''})'
                        '${isAvailable ? '' : ' (Unavailable)'}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isAvailable ? null : Colors.grey,
                          fontStyle: isAvailable
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'New Due Date',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _newDueDate != null
                        ? DateFormat('yyyy-MM-dd').format(_newDueDate!)
                        : 'Select new due date',
                    style: TextStyle(
                      color: _newDueDate != null
                          ? theme.colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _isLoading ? null : () => _pickDueDate(context),
                  ),
                  onTap: _isLoading ? null : () => _pickDueDate(context),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for reassignment (optional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 3,
                  onChanged: (val) => _reason = val,
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: _isLoading
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm Reassign'),
                      onPressed: _isLoading || _selectedNewUser == null
                          ? null
                          : _reassignTask,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 18,
                        ),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    TextButton.icon(
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Cancel'),
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _selectedTaskId = null;
                              _selectedTaskData = null;
                              _selectedNewUser = null;
                              _newDueDate = null;
                              _reason = null;
                              _userSearchTerm = '';
                              _filteredUsers = _allUsers;
                            }),
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
