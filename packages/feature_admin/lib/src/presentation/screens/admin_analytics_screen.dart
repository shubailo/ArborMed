import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/admin_service.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchWallOfPain();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      appBar: AppBar(title: const Text('System Analytics')),
      body: adminService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Wall of Pain', style: CozyTheme.of(context).headingMedium),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: (adminService.wallOfPain['failedQuestions'] as List?)?.length ?? 0,
                      itemBuilder: (context, index) {
                        final q = adminService.wallOfPain['failedQuestions'][index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(q['question_text'] ?? 'Unknown Question'),
                            subtitle: Text('Fail Rate: ${q['fail_rate']}% | Attempts: ${q['attempts']}'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
