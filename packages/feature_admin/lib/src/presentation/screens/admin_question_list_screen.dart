import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/admin_service.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({super.key});

  @override
  State<AdminQuestionListScreen> createState() => _AdminQuestionListScreenState();
}

class _AdminQuestionListScreenState extends State<AdminQuestionListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchAdminQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      appBar: AppBar(
        title: const Text('Question CMS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement Create Question Dialog
            },
          ),
        ],
      ),
      body: adminService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminService.adminQuestions.length,
              itemBuilder: (context, index) {
                final question = adminService.adminQuestions[index];
                return ListTile(
                  title: Text(question.text ?? 'No Text'),
                  subtitle: Text('Topic ID: ${question.topicId} | Stats: ${question.successRate.toStringAsFixed(1)}%'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          // TODO: Implement Edit
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Question?'),
                              content: const Text('This action cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await adminService.deleteQuestion(question.id);
                            adminService.fetchAdminQuestions();
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
