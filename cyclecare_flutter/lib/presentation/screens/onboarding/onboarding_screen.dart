import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  int _periodLength = 5;
  String _selectedGoal = 'track_periods';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    // TODO: Save onboarding data to database
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentPage > 0
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousPage,
              ),
              title: Text('Setup (${_currentPage + 1}/5)'),
            )
          : null,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          _buildWelcomePage(),
          _buildLastPeriodPage(),
          _buildCycleLengthPage(),
          _buildPeriodLengthPage(),
          _buildGoalSelectionPage(),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            size: 80,
            color: Color(0xFFE91E63),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to CycleCare',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your privacy-first companion for menstrual health tracking',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildPrivacyFeature(Icons.lock, '100% Local Storage'),
                  const SizedBox(height: 12),
                  _buildPrivacyFeature(Icons.cloud_off, 'No Cloud Sync'),
                  const SizedBox(height: 12),
                  _buildPrivacyFeature(Icons.security, 'PIN & Biometric Lock'),
                  const SizedBox(height: 12),
                  _buildPrivacyFeature(Icons.block, 'No Ads or Tracking'),
                ],
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }

  Widget _buildLastPeriodPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When did your last period start?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us predict your next cycle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 7)),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _lastPeriodDate = date;
                });
              }
            },
            child: Text(
              _lastPeriodDate != null
                  ? '${_lastPeriodDate!.day}/${_lastPeriodDate!.month}/${_lastPeriodDate!.year}'
                  : 'Select Date',
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _lastPeriodDate != null ? _nextPage : null,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleLengthPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your average cycle length?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The number of days from the first day of one period to the first day of the next',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              '$_cycleLength days',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _cycleLength.toDouble(),
            min: 21,
            max: 45,
            divisions: 24,
            label: '$_cycleLength days',
            onChanged: (value) {
              setState(() {
                _cycleLength = value.toInt();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('21 days', style: Theme.of(context).textTheme.bodySmall),
              Text('45 days', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How long does your period usually last?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The number of days you typically bleed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              '$_periodLength days',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _periodLength.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            label: '$_periodLength days',
            onChanged: (value) {
              setState(() {
                _periodLength = value.toInt();
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('2 days', style: Theme.of(context).textTheme.bodySmall),
              Text('10 days', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSelectionPage() {
    final goals = [
      {
        'id': 'track_periods',
        'title': 'Track Periods',
        'description': 'Monitor your menstrual cycle and symptoms',
      },
      {
        'id': 'trying_to_conceive',
        'title': 'Trying to Conceive',
        'description': 'Track fertility windows and ovulation',
      },
      {
        'id': 'pregnancy',
        'title': 'Pregnancy',
        'description': 'Track pregnancy symptoms and milestones',
      },
      {
        'id': 'perimenopause',
        'title': 'Perimenopause',
        'description': 'Monitor irregular cycles and symptoms',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What\'s your primary goal?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll customize your experience based on your needs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                final isSelected = _selectedGoal == goal['id'];
                
                return Card(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedGoal = goal['id'] as String;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goal['title'] as String,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            goal['description'] as String,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              child: const Text('Complete Setup'),
            ),
          ),
        ],
      ),
    );
  }
}
