import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arbormed_core/arbormed_core.dart';
import '../../application/admin_service.dart';

class AdminECGListScreen extends StatefulWidget {
  const AdminECGListScreen({super.key});

  @override
  State<AdminECGListScreen> createState() => _AdminECGListScreenState();
}

class _AdminECGListScreenState extends State<AdminECGListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminService>().fetchECGCases();
      context.read<AdminService>().fetchECGDiagnoses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminService = context.watch<AdminService>();

    return Scaffold(
      backgroundColor: CozyTheme.of(context).background,
      appBar: AppBar(
        title: const Text('ECG Case Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () {
              // TODO: Implement Create Case
            },
          ),
        ],
      ),
      body: adminService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminService.ecgCases.length,
              itemBuilder: (context, index) {
                final ecg = adminService.ecgCases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(ecg.imageUrl, width: 60, height: 40, fit: BoxFit.cover, 
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      ),
                    ),
                    title: Text(ecg.diagnosisName ?? 'Unknown Diagnosis'),
                    subtitle: Text('Level: ${ecg.difficulty} | Code: ${ecg.diagnosisCode ?? 'N/A'}'),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () {
                      // TODO: Implement Edit
                    },
                  ),
                );
              },
            ),
    );
  }
}
