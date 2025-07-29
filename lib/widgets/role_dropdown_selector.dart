import 'package:flutter/material.dart';

class RoleDropdownSelector extends StatefulWidget {
  final Function(String) onRoleSelected;

  const RoleDropdownSelector({super.key, required this.onRoleSelected});

  @override
  State<RoleDropdownSelector> createState() => _RoleDropdownSelectorState();
}

class _RoleDropdownSelectorState extends State<RoleDropdownSelector> {
  String? _selectedRole;

  final Map<String, List<String>?> roles = {
    'General Manager': null,
    'HOD': ['IS', 'Productions', 'Security'],
    'Chief Manager': ['IS', 'Productions', 'Security'],
    'Manager': ['IS', 'Productions', 'Security'],
    'Officer': ['IS', 'Productions', 'Security'],
    'Staff': ['IS', 'Productions', 'Security'],

  };

  void _showRolePicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: roles.entries.map((entry) {
            String role = entry.key;
            List<String>? subRoles = entry.value;

            if (subRoles == null) {
              return ListTile(
                title: Text(role),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedRole = role;
                  });
                  widget.onRoleSelected(role);
                },
              );
            } else {
              return ExpansionTile(
                title: Text(role),
                children: subRoles.map((subRole) {
                  return ListTile(
                    title: Text('$role - $subRole'),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _selectedRole = '$role - $subRole';
                      });
                      widget.onRoleSelected('$role - $subRole');
                    },
                  );
                }).toList(),
              );
            }
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showRolePicker,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Role',
          border: OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _selectedRole ?? 'Select Role',
          style: TextStyle(
            fontSize: 16,
            color: _selectedRole == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
