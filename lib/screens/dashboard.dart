import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'assigned_tasks_screen.dart';
import 'task_assignment_screen.dart';
import 'task_reassign_screen.dart';
import 'reports_review_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String gatePass;
  const DashboardScreen({required this.gatePass, super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  bool? _isAvailable;

  static const Set<String> _managerRoles = {
    'General Manager',
    'HOD',
    'HOD - IS',
    'HOD - Productions',
    'HOD - Security',
    'Chief Manager',
    'Chief Manager - IS',
    'Chief Manager - Productions',
    'Chief Manager - Security',
    'Manager',
    'Manager - IS',
    'Manager - Productions',
    'Manager - Security',
    'Officer',
    'Officer - IS',
    'Officer - Productions',
    'Officer - Security',
  };

  bool _hasManagerPermission(String? role) {
    if (role == null) return false;
    return _managerRoles.contains(role.trim());
  }

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.gatePass)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final accent = theme.colorScheme.secondary;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || !(snap.data?.exists ?? false)) {
          return const Scaffold(
            body: Center(child: Text('User record not found')),
          );
        }
        final data = snap.data!.data()!;
        final String name = data['name'] ?? '';
        final String role = data['role'] ?? 'Staff';
        _isAvailable ??= (data['available'] as bool?) ?? true;

        // Tiles for the dashboard
        final List<_Tile> tiles = [
          _Tile(
            label: 'My Assigned Tasks',
            icon: Icons.assignment_outlined,
            color: primary,
            onTap: () =>
                _navigate(context, AssignedTasksScreen(gatePass: widget.gatePass)),
          ),
        ];

        if (_hasManagerPermission(role)) {
          tiles.addAll([
            _Tile(
              label: 'Assign Task',
              icon: Icons.add_task_rounded,
              color: accent,
              onTap: () => _navigate(
                context,
                TaskAssignmentScreen(
                  assignedByGatePass: widget.gatePass, 
                  assignedByName: name,
                ),
              ),
            ),
            _Tile(
              label: 'Review Reports',
              icon: Icons.task_alt_outlined,
              color: Colors.teal.shade400,
              onTap: () => _navigate(
                context,
                ReportsReviewScreen(gatePass: widget.gatePass),
              ),
            ),
            _Tile(
              label: 'Reassign Task',
              icon: Icons.swap_horiz,
              color: Colors.purple.shade400,
              onTap: () => _navigate(
                context,
                TaskReassignScreen(gatePass: widget.gatePass),
              ),
            ),
          ]);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
            ),
            elevation: 2,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: Colors.black87,
            centerTitle: true,
          ),
          body: SafeArea(
            child: Container(
              width: double.infinity,
              color: theme.colorScheme.surface.withOpacity(0.97),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primary.withOpacity(0.16),
                          radius: 26,
                          child: Icon(Icons.account_circle, size: 46, color: primary),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $name',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            ),
                            Text(
                              'Role: $role',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Gate Pass: ${widget.gatePass}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Availability toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                        title: const Text(
                          'Available for Assignment',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        trailing: Switch(
                          value: _isAvailable ?? true,
                          activeColor: primary,
                          onChanged: (val) async {
                            setState(() => _isAvailable = val);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.gatePass)
                                .update({'available': val});
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  // Dashboard Tiles grid
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        itemCount: tiles.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 22,
                          childAspectRatio: 1.02,
                        ),
                        itemBuilder: (ctx, i) => _DashboardCard(tile: tiles[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigate(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

// Dashboard tile descriptor
class _Tile {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _Tile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// Dashboard action card
class _DashboardCard extends StatelessWidget {
  final _Tile tile;
  const _DashboardCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shadowColor: tile.color.withOpacity(0.23),
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: tile.color.withOpacity(0.14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [tile.color.withOpacity(0.12), Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: tile.color.withOpacity(0.16)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tile.icon, size: 42, color: tile.color),
              const SizedBox(height: 12),
              Text(
                tile.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
