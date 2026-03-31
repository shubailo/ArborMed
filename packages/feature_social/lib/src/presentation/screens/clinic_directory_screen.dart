import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feature_social/src/application/social_service.dart';

class ClinicDirectoryScreen extends StatefulWidget {
  const ClinicDirectoryScreen({super.key});

  @override
  State<ClinicDirectoryScreen> createState() => _ClinicDirectoryScreenState();
}

class _ClinicDirectoryScreenState extends State<ClinicDirectoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialService>().loadDirectory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinic Directory'),
        centerTitle: true,
      ),
      body: Consumer<SocialService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.clinics.isEmpty) {
            return const Center(child: Text('No clinics available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: service.clinics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final clinic = service.clinics[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.local_hospital,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    clinic.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(clinic.specialty),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(child: Text(clinic.address, style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // Navigate to details if needed
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
