import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PainMappingScreen extends ConsumerStatefulWidget {
  const PainMappingScreen({super.key});
  @override
  ConsumerState<PainMappingScreen> createState() => _PainMappingScreenState();
}

class _PainMappingScreenState extends ConsumerState<PainMappingScreen> {
  final Map<String, int> _painAreas = {}; // area -> intensity 1-10
  int _selectedIntensity = 5;

  static const _bodyAreas = [
    'Head', 'Neck', 'Shoulders', 'Upper Back', 'Lower Back',
    'Chest', 'Abdomen (Upper)', 'Abdomen (Lower)', 'Pelvis',
    'Left Hip', 'Right Hip', 'Left Leg', 'Right Leg',
    'Left Arm', 'Right Arm',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pain Mapping'),
        actions: [
          TextButton(
            onPressed: _painAreas.isNotEmpty ? () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pain data saved')));
              Navigator.pop(context);
            } : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Intensity selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pain Intensity', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('1'),
                      Expanded(
                        child: Slider(
                          value: _selectedIntensity.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '$_selectedIntensity',
                          activeColor: _intensityColor(_selectedIntensity),
                          onChanged: (v) => setState(() => _selectedIntensity = v.round()),
                        ),
                      ),
                      const Text('10'),
                    ],
                  ),
                  Center(
                    child: Text(
                      _intensityLabel(_selectedIntensity),
                      style: TextStyle(color: _intensityColor(_selectedIntensity), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Body areas
          Text('Tap areas where you feel pain:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bodyAreas.map((area) {
              final intensity = _painAreas[area];
              final hasP = intensity != null;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (hasP && intensity == _selectedIntensity) {
                      _painAreas.remove(area);
                    } else {
                      _painAreas[area] = _selectedIntensity;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: hasP ? _intensityColor(intensity!).withOpacity(0.2) : Colors.grey[100],
                    border: Border.all(
                      color: hasP ? _intensityColor(intensity!) : Colors.grey[300]!,
                      width: hasP ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(area, style: TextStyle(
                        fontWeight: hasP ? FontWeight.bold : FontWeight.normal,
                        color: hasP ? _intensityColor(intensity!) : Colors.grey[700],
                      )),
                      if (hasP) ...[
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: _intensityColor(intensity!),
                          child: Text('$intensity', style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          if (_painAreas.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Selected Pain Points', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._painAreas.entries.map((e) => ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: _intensityColor(e.value),
                child: Text('${e.value}', style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
              title: Text(e.key),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _painAreas.remove(e.key)),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Color _intensityColor(int intensity) {
    if (intensity <= 3) return Colors.green;
    if (intensity <= 6) return Colors.orange;
    return Colors.red;
  }

  String _intensityLabel(int intensity) {
    if (intensity <= 2) return 'Mild';
    if (intensity <= 4) return 'Moderate';
    if (intensity <= 6) return 'Uncomfortable';
    if (intensity <= 8) return 'Severe';
    return 'Extreme';
  }
}
