import 'package:agora_poc/controllers/auth_controller.dart';
import 'package:agora_poc/create_meet_page.dart';
import 'package:agora_poc/join_call_dialog.dart';
import 'package:agora_poc/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/meeting_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final meetingService = Provider.of<MeetingService>(context);
    final user = authService.currentUser;

    // If user is not logged in, redirect to login
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Determine pages based on user role
    final List<Widget> pages = _getPagesForUserRole(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VoiceConnect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton:
          user.isMember
              ? FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateCallDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Call'),
                backgroundColor: theme.colorScheme.primary,
              )
              : FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const JoinCallDialog(),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Join Call'),
                backgroundColor: theme.colorScheme.primary,
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _getNavigationItemsForUserRole(user),
      ),
    );
  }

  List<Widget> _getPagesForUserRole(User user) {
    if (user.isAdmin) {
      return [
        const DashboardPage(),
        const MeetingsPage(),
        const AdminPage(),
        const ProfilePage(),
      ];
    } else if (user.isMember) {
      return [const DashboardPage(), const MeetingsPage(), const ProfilePage()];
    } else {
      // Regular user
      return [const DashboardPage(), const ProfilePage()];
    }
  }

  List<BottomNavigationBarItem> _getNavigationItemsForUserRole(User user) {
    final commonItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
    ];

    if (user.isAdmin || user.isMember) {
      commonItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups),
          label: 'Meetings',
        ),
      );
    }

    if (user.isAdmin) {
      commonItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    commonItems.add(
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    );

    return commonItems;
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: Icon(
                    Icons.person,
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        user?.name ?? 'User',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user != null
                              ? (user.isMember
                                  ? 'Member'
                                  : user.isAdmin
                                  ? 'Admin'
                                  : 'User')
                              : 'User',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  icon: Icons.login,
                  title: 'Join Meeting',
                  color: theme.colorScheme.primary,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => const JoinCallDialog(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  context,
                  icon:
                      (user != null && user.isMember)
                          ? Icons.add
                          : Icons.history,
                  title:
                      (user != null && user.isMember)
                          ? 'Create Meeting'
                          : 'Recent Calls',
                  color: theme.colorScheme.secondary,
                  onTap: () {
                    if (user != null && user.isMember) {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateCallDialog(),
                      );
                    } else {
                      // Show recent calls
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Upcoming meetings
          Text(
            'Upcoming Meetings',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Placeholder for upcoming meetings
          _buildUpcomingMeetings(context),

          const SizedBox(height: 24),

          // App features
          Text(
            'Key Features',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          _buildFeaturesList(context),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to proceed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingMeetings(BuildContext context) {
    // This would normally fetch from the service
    // For demo, we'll show placeholder data

    final theme = Theme.of(context);

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Team Sync',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Today, 3:00 PM',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      child: const Text('Join'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text('8 Participants', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text('60 minutes', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Planning',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Tomorrow, 10:00 AM',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      child: const Text('Join'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text('12 Participants', style: theme.textTheme.bodySmall),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text('90 minutes', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFeatureItem(
              context,
              icon: Icons.group,
              title: 'Group Voice Calls',
              description: 'Host meetings with up to 45 participants',
            ),
            const Divider(),
            _buildFeatureItem(
              context,
              icon: Icons.record_voice_over,
              title: 'Call Recording',
              description: 'Record meetings for future reference',
            ),
            const Divider(),
            _buildFeatureItem(
              context,
              icon: Icons.meeting_room,
              title: 'Private Rooms',
              description: '1-on-1 breakout rooms during group calls',
            ),
            const Divider(),
            _buildFeatureItem(
              context,
              icon: Icons.mic_off,
              title: 'Host Controls',
              description: 'Mute participants and manage requests',
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.tertiary, size: 24),
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
      ),
    );
  }
}

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Meetings Page - Coming soon'));
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin Page - Coming soon'));
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Page - Coming soon'));
  }
}
