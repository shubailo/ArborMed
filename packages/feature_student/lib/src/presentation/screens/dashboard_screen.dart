import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../services/student_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StudentService _studentService;

  @override
  void initState() {
    super.initState();
    _studentService = GetIt.I<StudentService>();
    // Default user for now
    _studentService.loadProfile('current_user');
  }

  @override
  Widget build(BuildContext context) {
    final theme = CozyTheme.of(context);

    return ChangeNotifierProvider.value(
      value: _studentService,
      child: Scaffold(
        backgroundColor: theme.background,
        drawer: const Drawer(), // Placeholder for now
        appBar: AppBar(
          title: Text(
            'ArborMed Dashboard',
            style: theme.textTheme.titleMedium.copyWith(color: theme.primary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            _buildStatChip(context),
            const SizedBox(width: 16),
          ],
        ),
        body: Consumer<StudentService>(
          builder: (context, service, child) {
            final profile = service.profile;
            if (profile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(profile, theme),
                  const SizedBox(height: 24),
                  Text(
                    'Topics',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildTopicList(theme),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context) {
    final theme = CozyTheme.of(context);
    final service = context.watch<StudentService>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monetization_on, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            '${service.profile?.coins ?? 0}',
            style: theme.textTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(profile, theme) {
    return Card(
      color: theme.surfaceSecondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.primary.withOpacity(0.2),
                  child: Icon(Icons.person, color: theme.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.displayName ?? 'Student', style: theme.textTheme.titleLarge),
                      Text('Level ${profile.level}', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (profile.xp % 100) / 100,
              backgroundColor: theme.background,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
            ),
            const SizedBox(height: 8),
            Text('${profile.xp} XP', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicList(theme) {
    // These should come from Isar in a real app
    final topics = [
      {'slug': 'anatomy', 'name': 'Anatomy'},
      {'slug': 'physiology', 'name': 'Physiology'},
      {'slug': 'pathology', 'name': 'Pathology'},
    ];

    return ListView.builder(
      itemCount: topics.length,
      itemBuilder: (context, index) {
        final topic = topics[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(topic['name']!),
            trailing: Icon(Icons.chevron_right, color: theme.primary),
            onPressed: () {
              // Navigate to Quiz
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Starting ${topic['name']} Quiz...')),
              );
            },
          ),
        );
      },
    );
  }
}
