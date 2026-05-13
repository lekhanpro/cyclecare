import 'package:flutter/material.dart';
import '../../core/theme/cyclecare_theme.dart';
import '../../widgets/soft_card.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Conditions')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _ConditionCard(
            emoji: '🔵',
            title: 'PCOS',
            subtitle: 'Polycystic Ovary Syndrome',
            description:
                'PCOS is a hormonal disorder common among people of reproductive age. Symptoms may include irregular periods, excess androgen, and polycystic ovaries. Tracking your cycle can help identify patterns.',
            color: Color(0xFFE3F2FD),
          ),
          SizedBox(height: 12),
          _ConditionCard(
            emoji: '🟣',
            title: 'Endometriosis',
            subtitle: 'Pain diary & symptom tracking',
            description:
                'Endometriosis occurs when tissue similar to the uterine lining grows outside the uterus. Logging pain levels, location, and timing can help your doctor understand your experience.',
            color: Color(0xFFF3E5F5),
          ),
          SizedBox(height: 12),
          _ConditionCard(
            emoji: '🟡',
            title: 'PMDD',
            subtitle: 'Premenstrual Dysphoric Disorder',
            description:
                'PMDD is a severe form of PMS with significant mood and physical symptoms in the luteal phase. Consistent daily logging helps identify patterns and supports diagnosis.',
            color: Color(0xFFFFFDE7),
          ),
          SizedBox(height: 12),
          _ConditionCard(
            emoji: '🟠',
            title: 'Perimenopause',
            subtitle: 'Transition tracking',
            description:
                'Perimenopause is the transition to menopause, often starting in the 40s. Cycles may become irregular. Tracking helps you and your provider understand changes.',
            color: Color(0xFFFBE9E7),
          ),
          SizedBox(height: 12),
          _ConditionCard(
            emoji: '⚪',
            title: 'Amenorrhea',
            subtitle: 'Absent periods',
            description:
                'Amenorrhea is the absence of menstruation. CycleCare automatically flags if your period is significantly overdue. Always consult a healthcare provider.',
            color: Color(0xFFF5F5F5),
          ),
          SizedBox(height: 24),
          _DisclaimerCard(),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                    Text(subtitle,
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.inkLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Text(
        '⚕️ CycleCare provides educational information only. None of the content here constitutes a medical diagnosis or treatment recommendation. Please consult a qualified healthcare professional for any health concerns.',
        style: AppTextStyles.textTheme.bodySmall?.copyWith(
          color: AppColors.muted,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }
}
