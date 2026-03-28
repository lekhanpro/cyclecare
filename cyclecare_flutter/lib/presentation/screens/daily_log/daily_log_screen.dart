import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyLogScreen extends ConsumerStatefulWidget {
  const DailyLogScreen({super.key});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          _buildSection('Flow', [
            _buildChip('Light'),
            _buildChip('Medium'),
            _buildChip('Heavy'),
            _buildChip('Spotting'),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSection('Mood', [
            _buildChip('Happy'),
            _buildChip('Sad'),
            _buildChip('Anxious'),
            _buildChip('Calm'),
            _buildChip('Irritable'),
          ]),
          
          const SizedBox(height: 24),
          
          _buildSection('Symptoms', [
            _buildChip('Cramps'),
            _buildChip('Headache'),
            _buildChip('Bloating'),
            _buildChip('Fatigue'),
            _buildChip('Acne'),
            _buildChip('Breast Tenderness'),
          ]),
          
          const SizedBox(height: 24),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Add any additional notes...',
            ),
            maxLines: 4,
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Save log
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log saved successfully')),
                );
              },
              child: const Text('Save Log'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        // TODO: Handle selection
      },
    );
  }
}
