import 'package:agora_poc/login_page.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: size.height * 0.08),

              // Logo
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.voice_chat_rounded,
                    size: 70,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // App Name
              Text(
                'VoiceConnect',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 8),

              // App Description
              Text(
                'Professional voice calling platform for teams and organizations',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),

              SizedBox(height: size.height * 0.06),

              // Features section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      context,
                      icon: Icons.groups_rounded,
                      title: 'Group Voice Calls',
                      description: 'Host meetings with up to 45 participants',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      icon: Icons.security_rounded,
                      title: 'Secure Meetings',
                      description: 'Password protection and host approval',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      icon: Icons.record_voice_over_rounded,
                      title: 'Advanced Controls',
                      description: 'Recording, speaker focus, and mute options',
                    ),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // Company Description
              Text(
                'By TechSolutions Inc.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Leading provider of communication solutions since 2010',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),

              const Spacer(),

              // Get Started Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text('Get Started'),
              ),

              SizedBox(height: size.height * 0.04),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
