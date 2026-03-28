import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final List<Map<String, dynamic>> _profiles = [
    {'name': 'My Profile', 'mode': 'Track Periods', 'active': true, 'color': Colors.pink},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProfileDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Profile'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _profiles.length,
        itemBuilder: (_, i) {
          final profile = _profiles[i];
          final isActive = profile['active'] as bool;
          return Card(
            elevation: isActive ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isActive ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: profile['color'] as Color,
                child: Text((profile['name'] as String)[0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(profile['name'] as String),
              subtitle: Text(profile['mode'] as String),
              trailing: isActive
                  ? Chip(label: const Text('Active'), backgroundColor: theme.colorScheme.primaryContainer)
                  : TextButton(onPressed: () {
                      setState(() {
                        for (var p in _profiles) { p['active'] = false; }
                        _profiles[i]['active'] = true;
                      });
                    }, child: const Text('Switch')),
            ),
          );
        },
      ),
    );
  }

  void _showAddProfileDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Profile'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _profiles.add({
                    'name': controller.text,
                    'mode': 'Track Periods',
                    'active': false,
                    'color': Colors.primaries[_profiles.length % Colors.primaries.length],
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
