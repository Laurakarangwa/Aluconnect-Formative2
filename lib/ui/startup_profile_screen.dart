import 'package:flutter/material.dart';
import 'package:formative_assignment/models/startup_profile.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:uuid/uuid.dart';

class StartupProfileScreen extends StatefulWidget {
  final AppState appState;
  const StartupProfileScreen({super.key, required this.appState});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sectorController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create an ALU-recognized startup profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF7A0F1D))),
                      const SizedBox(height: 8),
                      const Text('Build trust with students by showing the mission, sector, and location clearly.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Startup name'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _sectorController, decoration: const InputDecoration(labelText: 'Sector'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website (optional)')),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final startup = StartupProfile(
                      id: const Uuid().v4(),
                      ownerId: widget.appState.currentUser?.id ?? 'guest',
                      name: _nameController.text,
                      description: _descriptionController.text,
                      sector: _sectorController.text,
                      location: _locationController.text,
                      website: _websiteController.text.isEmpty ? null : _websiteController.text,
                      isVerified: true,
                      createdAt: DateTime.now(),
                    );
                    await widget.appState.createStartup(startup);
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save startup profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
