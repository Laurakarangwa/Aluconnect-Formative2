import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/services/firebase_service.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/ui/home_screen.dart';
import 'package:uuid/uuid.dart';

class PostOpportunityScreen extends StatefulWidget {
  final AppState appState;
  const PostOpportunityScreen({super.key, required this.appState});

  @override
  State<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends State<PostOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _commitmentController = TextEditingController();
  final _stipendController = TextEditingController();
  final _skillsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;
  double? _imageWidth;
  double? _imageHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post opportunity')),
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
                      Text('Share an internship opportunity with ALU students', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF7A0F1D))),
                      const SizedBox(height: 8),
                      const Text('A polished post makes it easier to attract strong applicants.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Role title'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _commitmentController, decoration: const InputDecoration(labelText: 'Commitment'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _stipendController, decoration: const InputDecoration(labelText: 'Stipend'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _skillsController, decoration: const InputDecoration(labelText: 'Required skills (comma separated)')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrlController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Cover image URL (optional)', hintText: 'https://example.com/image.png'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                      if (result == null || result.files.single.bytes == null) return;
                      final bytes = result.files.single.bytes!;
                      // try decode image dimensions
                      try {
                        final codec = await ui.instantiateImageCodec(bytes);
                        final frame = await codec.getNextFrame();
                        final image = frame.image;
                        _imageWidth = image.width.toDouble();
                        _imageHeight = image.height.toDouble();
                      } catch (_) {
                        _imageWidth = null;
                        _imageHeight = null;
                      }
                      setState(() {
                        _imageBytes = bytes;
                        _imageName = result.files.single.name;
                      });
                    },
                    child: const Text('Pick image'),
                  ),
                  const SizedBox(width: 8),
                  if (_imageName != null) Expanded(child: Text(_imageName!, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 8),
              if ((_imageUrlController.text.trim().isNotEmpty) || _imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageBytes != null
                      ? _ImagePreviewAdaptive(bytes: _imageBytes!, width: _imageWidth, height: _imageHeight)
                      : Image.network(
                          _imageUrlController.text.trim(),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: const Color(0xFFF7E6E8),
                            alignment: Alignment.center,
                            child: const Text('Image could not be loaded'),
                          ),
                        ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : () async {
                  if (_formKey.currentState!.validate()) {
                    String? imageUrl = _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim();
                    if (_imageBytes != null) {
                      setState(() => _isUploading = true);
                      try {
                        final ext = (_imageName?.split('.').last) ?? 'jpg';
                        imageUrl = await FirebaseService.instance.uploadFile(_imageBytes!, 'opportunities/${const Uuid().v4()}/cover.$ext', 'image/$ext');
                      } catch (e) {
                        widget.appState.showTransientMessage('Image upload failed');
                      } finally {
                        if (mounted) setState(() => _isUploading = false);
                      }
                    }

                    final opportunity = Opportunity(
                      id: const Uuid().v4(),
                      startupId: widget.appState.currentUser?.startupId ?? widget.appState.currentUser?.id ?? 'demo-startup',
                      title: _titleController.text,
                      description: _descriptionController.text,
                      category: _categoryController.text,
                      location: _locationController.text,
                      commitment: _commitmentController.text,
                      stipend: _stipendController.text,
                      requiredSkills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      imageUrl: imageUrl,
                      createdAt: DateTime.now(),
                    );
                    try {
                      await widget.appState.createOpportunity(opportunity);
                      // Switch to Home and show a short confirmation message
                      widget.appState.showTransientMessage('Opportunity published!');
                      widget.appState.setSelectedTab(0);
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
                        (route) => false,
                      );
                    } catch (e) {
                      widget.appState.showTransientMessage('Failed to publish opportunity');
                    }
                  }
                },
                child: const Text('Publish opportunity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewAdaptive extends StatelessWidget {
  final Uint8List bytes;
  final double? width;
  final double? height;

  const _ImagePreviewAdaptive({required this.bytes, this.width, this.height, super.key});

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width - 64;
    double displayWidth = width ?? maxWidth;
    double displayHeight = height ?? displayWidth;
    if (displayWidth > maxWidth) {
      final ratio = displayHeight / displayWidth;
      displayWidth = maxWidth;
      displayHeight = displayWidth * ratio;
    }
    if (displayWidth < 120) displayWidth = 120;
    if (displayHeight < 80) displayHeight = 80;
    return Image.memory(
      bytes,
      width: displayWidth,
      height: displayHeight,
      fit: BoxFit.contain,
    );
  }
}
