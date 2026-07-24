import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:formative_assignment/models/application.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/services/firebase_service.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/ui/home_screen.dart';
import 'package:uuid/uuid.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Opportunity opportunity;
  final AppState appState;

  const ApplicationFormScreen({super.key, required this.opportunity, required this.appState});

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedFaculty = 'BSE';
  final _intakeController = TextEditingController();
  final _schoolEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _coverLetterName;
  Uint8List? _coverLetterBytes;
  String? _cvName;
  Uint8List? _cvBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = widget.appState.currentUser;
    if (user != null) {
      _nameController.text = user.name;
      _schoolEmailController.text = user.email;
    }
  }

  Future<void> _pickPdf(bool isCoverLetter) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isCoverLetter) {
          _coverLetterName = result.files.single.name;
          _coverLetterBytes = result.files.single.bytes;
        } else {
          _cvName = result.files.single.name;
          _cvBytes = result.files.single.bytes;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply now')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Apply to ${widget.opportunity.title}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Tell the startup a little about yourself and upload your supporting documents.'),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedFaculty,
                    decoration: const InputDecoration(labelText: 'Faculty'),
                    items: const [
                      DropdownMenuItem(value: 'BSE', child: Text("Bachelor's of Software Engineering (BSE)")),
                      DropdownMenuItem(value: 'BEL', child: Text("Bachelor's of Entrepreneurial Leadership (BEL)")),
                      DropdownMenuItem(value: 'IBT', child: Text("Bachelor's of International Business & Trade (IBT)")),
                    ],
                    onChanged: (value) => setState(() => _selectedFaculty = value ?? 'BSE'),
                    validator: (value) => value == null || value.isEmpty ? 'Select your faculty' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _intakeController,
                    decoration: const InputDecoration(labelText: 'Intake year'),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your intake year' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _schoolEmailController,
                    decoration: const InputDecoration(labelText: 'School email', hintText: 'student123@alustudent.com'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your school email';
                      }
                      final email = value.trim().toLowerCase();
                      if (!email.endsWith('@alustudent.com')) {
                        return 'Use your @alustudent.com email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter your phone number' : null,
                  ),
                  const SizedBox(height: 24),
                  _DocumentPickerRow(
                    label: 'Cover letter (PDF)',
                    fileName: _coverLetterName,
                    onTap: () => _pickPdf(true),
                  ),
                  const SizedBox(height: 12),
                  _DocumentPickerRow(
                    label: 'CV (PDF)',
                    fileName: _cvName,
                    onTap: () => _pickPdf(false),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            if (_coverLetterBytes == null || _cvBytes == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please upload both your cover letter and CV before submitting.')),
                                );
                              }
                              return;
                            }

                            setState(() => _isSubmitting = true);
                            try {
                              final applicationId = const Uuid().v4();
                              String? coverLetterUrl;
                              String? cvUrl;

                              coverLetterUrl = await FirebaseService.instance.uploadFile(
                                _coverLetterBytes!,
                                'applications/$applicationId/cover_letter.pdf',
                                'application/pdf',
                              );

                              cvUrl = await FirebaseService.instance.uploadFile(
                                _cvBytes!,
                                'applications/$applicationId/cv.pdf',
                                'application/pdf',
                              );

                              final application = ApplicationModel(
                                id: applicationId,
                                opportunityId: widget.opportunity.id,
                                startupId: widget.opportunity.startupId,
                                studentId: widget.appState.currentUser?.id ?? 'guest',
                                studentName: _nameController.text.trim(),
                                faculty: _selectedFaculty,
                                intakeYear: _intakeController.text.trim(),
                                schoolEmail: _schoolEmailController.text.trim(),
                                phoneNumber: _phoneController.text.trim(),
                                coverLetterUrl: coverLetterUrl,
                                cvUrl: cvUrl,
                                appliedAt: DateTime.now(),
                              );
                              await widget.appState.applyToOpportunity(application);
                              final isDemoMode = coverLetterUrl!.startsWith('local-demo://') || cvUrl!.startsWith('local-demo://');
                              widget.appState.showTransientMessage(
                                isDemoMode
                                    ? 'Application submitted in demo mode. It is saved locally for now.'
                                    : 'Application submitted!',
                              );
                              widget.appState.setSelectedTab(2);
                              if (!mounted) return;
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
                                (route) => false,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not submit the application right now. Please try again.')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    child: _isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit application'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPickerRow extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const _DocumentPickerRow({required this.label, required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1C2C7)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            const Icon(Icons.attach_file, color: Color(0xFF7A0F1D)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (fileName != null) ...[
                    const SizedBox(height: 6),
                    Text(fileName!, style: const TextStyle(color: Colors.black54)),
                  ] else ...[
                    const SizedBox(height: 6),
                    const Text('Tap to upload a PDF (required)', style: TextStyle(color: Colors.black54)),
                  ]
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF7A0F1D)),
          ],
        ),
      ),
    );
  }
}
