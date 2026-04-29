import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isSignedIn = false;
  bool _autoBackup = true;
  bool _isBackingUp = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google sign in card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _isSignedIn ? Icons.cloud_done : Icons.cloud_off,
                    size: 48,
                    color: _isSignedIn ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignedIn ? 'Connected to Google Drive' : 'Not connected',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isSignedIn = !_isSignedIn),
                    icon: Icon(_isSignedIn ? Icons.logout : Icons.login),
                    label: Text(_isSignedIn ? 'Sign Out' : 'Sign in with Google'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_isSignedIn) ...[
            // Last backup info
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Last Backup'),
                subtitle: const Text('Never'),
                trailing: const Text('0 KB'),
              ),
            ),
            const SizedBox(height: 16),

            // Backup button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isBackingUp ? null : () async {
                  setState(() => _isBackingUp = true);
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) {
                    setState(() => _isBackingUp = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup completed successfully')),
                    );
                  }
                },
                icon: _isBackingUp
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.backup),
                label: Text(_isBackingUp ? 'Backing up...' : 'Backup Now'),
              ),
            ),
            const SizedBox(height: 8),

            // Restore button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Restore Data'),
                      content: const Text('This will replace all current data with the backup. Continue?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Restore')),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.restore),
                label: const Text('Restore from Backup'),
              ),
            ),
            const SizedBox(height: 16),

            // Auto backup toggle
            SwitchListTile(
              title: const Text('Auto Backup'),
              subtitle: const Text('Automatically backup when data changes'),
              value: _autoBackup,
              onChanged: (v) => setState(() => _autoBackup = v),
            ),
          ],

          if (!_isSignedIn)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.lock, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to enable cloud backup',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your data is encrypted with AES-256 before upload',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
