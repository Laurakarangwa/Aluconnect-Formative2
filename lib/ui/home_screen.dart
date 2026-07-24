import 'package:flutter/material.dart';
import 'package:formative_assignment/models/application.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/models/startup_profile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:formative_assignment/services/firebase_service.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/ui/application_form_screen.dart';
import 'package:formative_assignment/ui/auth_screen.dart';
import 'package:formative_assignment/ui/opportunity_detail_screen.dart';
import 'package:formative_assignment/ui/post_opportunity_screen.dart';
import 'package:formative_assignment/ui/startup_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppState appState;
  const HomeScreen({super.key, required this.appState});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.loadData();
    widget.appState.addListener(_onAppStateChanged);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_onAppStateChanged);
    super.dispose();
  }

  void _onAppStateChanged() {
    final msg = widget.appState.transientMessage;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
      widget.appState.clearTransientMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        if (widget.appState.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: IndexedStack(
            index: widget.appState.selectedTab,
            children: [
              _LandingTab(appState: widget.appState),
              _ExploreTab(appState: widget.appState),
              _ApplicationsTab(appState: widget.appState),
              _ProfileTab(appState: widget.appState),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: widget.appState.selectedTab,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.black54,
            type: BottomNavigationBarType.fixed,
            onTap: (value) => widget.appState.setSelectedTab(value),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
              BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Applications'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
            ],
          ),
        );
      },
    );
  }
}

class _LandingTab extends StatelessWidget {
  final AppState appState;
  const _LandingTab({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final isStudent = appState.currentUser?.roles.contains('student') ?? false;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LandingHeader(isStudent: isStudent),
          const SizedBox(height: 16),
          _InfoBanner(text: isStudent ? 'New opportunities are highlighted automatically for you.' : 'Students can now discover your newest postings instantly.'),
          const SizedBox(height: 16),
          if (!(isStudent && !(appState.currentUser?.roles.contains('startup') ?? false))) ...[
            _SectionHeader(
              title: 'Your startup profile',
              actionLabel: 'Create profile',
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => StartupProfileScreen(appState: appState)));
              },
            ),
            const SizedBox(height: 8),
            if (appState.startups.isEmpty)
              const Text('No startup profile yet. Add one to begin attracting students.'),
            ...appState.startups.map((startup) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _StartupTile(startup: startup))).toList(),
            const SizedBox(height: 16),
          ],
          _SectionHeader(
            title: isStudent ? 'Available opportunities' : 'Open opportunities',
            actionLabel: isStudent && !(appState.currentUser?.roles.contains('startup') ?? false) ? ' ' : 'Post opportunity',
            onPressed: isStudent && !(appState.currentUser?.roles.contains('startup') ?? false)
                ? null
                : () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostOpportunityScreen(appState: appState)));
                  },
          ),
          const SizedBox(height: 8),
          if (appState.opportunities.isEmpty)
            const Text('No opportunities available yet.'),
          ...appState.opportunities.map((opportunity) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _OpportunityCard(opportunity: opportunity, appState: appState, showApplyButton: isStudent))).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ExploreTab extends StatefulWidget {
  final AppState appState;
  const _ExploreTab({required this.appState, super.key});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.appState.opportunities.where((opportunity) {
      final query = _searchController.text.toLowerCase();
      final matchesSearch = query.isEmpty || opportunity.title.toLowerCase().contains(query) || opportunity.description.toLowerCase().contains(query);
      final matchesCategory = _selectedCategory == 'All' || opportunity.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    final categories = ['All', 'Design', 'Engineering', 'Marketing', 'Data', 'Other'];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search opportunities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching opportunities found.'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _OpportunityCard(opportunity: filtered[index], appState: widget.appState, showApplyButton: (widget.appState.currentUser?.roles.contains('student') ?? false)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  final AppState appState;
  const _ApplicationsTab({required this.appState, super.key});

  @override
  Widget build(BuildContext context) {
    final isStartup = appState.currentUser?.roles.contains('startup') ?? false;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isStartup ? 'Applications received' : 'Pending applications', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isStartup ? 'Review students who applied to your opportunities.' : 'Your submitted applications and their current status will appear here.'),
            const SizedBox(height: 16),
            Expanded(
              child: appState.applications.isEmpty
                  ? Center(child: Text(isStartup ? 'No applications received yet.' : 'No applications submitted yet.'))
                  : ListView.builder(
                      itemCount: appState.applications.length,
                      itemBuilder: (context, index) {
                        final application = appState.applications[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(application.studentName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    Chip(label: Text(application.status.toUpperCase())),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('${application.faculty} • ${application.intakeYear}'),
                                const SizedBox(height: 6),
                                Text(application.schoolEmail),
                                if (application.phoneNumber.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(application.phoneNumber),
                                ],
                                if (isStartup) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await appState.updateApplicationStatus(application.id, 'accepted');
                                          appState.showTransientMessage('Application accepted');
                                        },
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text('Accept'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          await appState.updateApplicationStatus(application.id, 'rejected');
                                          appState.showTransientMessage('Application rejected');
                                        },
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text('Reject'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final uri = Uri.parse('mailto:${application.schoolEmail}?subject=Application%20update&body=Hello%20${Uri.encodeComponent(application.studentName)},%0A%0AThank%20you%20for%20your%20application.%20We%20will%20get%20back%20to%20you%20soon.%0A%0ARegards');
                                          if (!await launchUrl(uri)) {
                                            appState.showTransientMessage('Could not open email app');
                                          }
                                        },
                                        icon: const Icon(Icons.email_outlined),
                                        label: const Text('Email'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (application.coverLetterUrl != null)
                                        OutlinedButton.icon(
                                          onPressed: () => launchUrl(Uri.parse(application.coverLetterUrl!)),
                                          icon: const Icon(Icons.description_outlined),
                                          label: const Text('Cover letter'),
                                        ),
                                      if (application.cvUrl != null)
                                        OutlinedButton.icon(
                                          onPressed: () => launchUrl(Uri.parse(application.cvUrl!)),
                                          icon: const Icon(Icons.picture_as_pdf_outlined),
                                          label: const Text('CV'),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
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

class _ProfileTab extends StatefulWidget {
  final AppState appState;
  const _ProfileTab({required this.appState, super.key});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _photoUrlController = TextEditingController();
  bool _isUploading = false;
  Uint8List? _profileImageBytes;
  double? _profileImageWidth;
  double? _profileImageHeight;

  @override
  void initState() {
    super.initState();
    _photoUrlController.text = widget.appState.currentUser?.photoUrl ?? '';
  }

  @override
  void dispose() {
    _photoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.currentUser;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFF7E6E8),
                  backgroundImage: user?.photoUrl != null && user!.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl!) : null,
                  child: user?.photoUrl == null || user!.photoUrl!.isEmpty ? const Icon(Icons.person, size: 32, color: Color(0xFF7A0F1D)) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${user?.name ?? 'User'}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile picture URL', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    // Only allow upload from device (no paste URL)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload profile photo'),
                            onPressed: _isUploading
                                ? null
                                : () async {
                                    if (user == null) return;
                                    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                                    if (result == null || result.files.single.bytes == null) return;
                                    final bytes = result.files.single.bytes!;
                                    // decode image size
                                    try {
                                      final codec = await ui.instantiateImageCodec(bytes);
                                      final frame = await codec.getNextFrame();
                                      final image = frame.image;
                                      _profileImageWidth = image.width.toDouble();
                                      _profileImageHeight = image.height.toDouble();
                                    } catch (_) {
                                      _profileImageWidth = null;
                                      _profileImageHeight = null;
                                    }
                                    setState(() {
                                      _isUploading = true;
                                      _profileImageBytes = bytes;
                                    });
                                    try {
                                      final ext = result.files.single.extension ?? 'jpg';
                                      final path = 'users/${user.id}/photo.$ext';
                                      final url = await FirebaseService.instance.uploadFile(bytes, path, 'image/$ext');
                                      await widget.appState.updateProfilePhoto(url);
                                    } catch (e) {
                                      widget.appState.showTransientMessage('Photo upload failed');
                                    } finally {
                                      if (mounted) setState(() => _isUploading = false);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // display uploaded image (use memory preview if available)
                    if (_profileImageBytes != null)
                      _ProfileImagePreview(bytes: _profileImageBytes!, width: _profileImageWidth, height: _profileImageHeight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Role'),
                subtitle: Text(user?.role ?? 'student'),
                leading: const Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text('Sign out'),
                leading: const Icon(Icons.logout),
                onTap: () async {
                  await widget.appState.signOut();
                  if (!mounted) return;
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => AuthScreen(appState: widget.appState)),
                    (route) => false,
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

class _LandingHeader extends StatelessWidget {
  final bool isStudent;
  const _LandingHeader({required this.isStudent, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isStudent ? Icons.school_rounded : Icons.business_center_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isStudent ? 'Student opportunities' : 'Startup dashboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isStudent
                ? 'Browse verified internships and discover roles that match your study path.'
                : 'Manage your startup profile and post internship opportunities for ALU students.',
            style: TextStyle(color: Colors.white.withOpacity(0.95)),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('Verified startups')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileImagePreview extends StatelessWidget {
  final Uint8List bytes;
  final double? width;
  final double? height;

  const _ProfileImagePreview({required this.bytes, this.width, this.height, super.key});

  @override
  Widget build(BuildContext context) {
    const maxPreviewWidth = 220.0;
    const maxPreviewHeight = 220.0;
    final maxWidth = MediaQuery.of(context).size.width - 64;
    double displayWidth = width ?? maxPreviewWidth;
    double displayHeight = height ?? maxPreviewHeight;

    if (displayWidth > maxWidth) {
      final ratio = (height ?? displayHeight) / displayWidth;
      displayWidth = maxWidth;
      displayHeight = displayWidth * ratio;
    }

    if (displayWidth > maxPreviewWidth) {
      final ratio = displayHeight / displayWidth;
      displayWidth = maxPreviewWidth;
      displayHeight = displayWidth * ratio;
    }

    if (displayHeight > maxPreviewHeight) {
      final ratio = displayWidth / displayHeight;
      displayHeight = maxPreviewHeight;
      displayWidth = displayHeight * ratio;
    }

    if (displayWidth < 48) displayWidth = 48;
    if (displayHeight < 48) displayHeight = 48;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxPreviewWidth, maxHeight: maxPreviewHeight),
          child: Image.memory(
            bytes,
            width: displayWidth,
            height: displayHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback? onPressed;
  const _SectionHeader({required this.title, required this.actionLabel, this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (onPressed != null) TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final Opportunity opportunity;
  final AppState appState;
  final bool showApplyButton;
  const _OpportunityCard({required this.opportunity, required this.appState, required this.showApplyButton, super.key});

  @override
  Widget build(BuildContext context) {
    final hasApplied = showApplyButton && appState.applications.any(
          (application) => application.opportunityId == opportunity.id && application.studentId == appState.currentUser?.id,
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (opportunity.imageUrl != null && opportunity.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: Image.network(
                    opportunity.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (opportunity.imageUrl != null && opportunity.imageUrl!.isNotEmpty) const SizedBox(height: 12),
            Text(opportunity.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('${opportunity.category} • ${opportunity.location}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(opportunity.commitment, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(opportunity.stipend, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 12),
            if (hasApplied)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7E6E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('Applied', style: TextStyle(color: Color(0xFF7A0F1D), fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: hasApplied
                      ? null
                      : () {
                          if (showApplyButton) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationFormScreen(opportunity: opportunity, appState: appState)));
                          } else {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunity: opportunity, appState: appState)));
                          }
                        },
                  child: Text(hasApplied ? 'Applied' : (showApplyButton ? 'Apply now' : 'View details')),
                ),
                if (showApplyButton) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OpportunityDetailScreen(opportunity: opportunity, appState: appState))),
                    child: const Text('More info'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StartupTile extends StatelessWidget {
  final StartupProfile startup;
  const _StartupTile({required this.startup, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFF7E6E8), child: Text(startup.name.substring(0, 1).toUpperCase())),
        title: Text(startup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(startup.description),
        trailing: startup.isVerified ? const Icon(Icons.verified, color: Color(0xFF7A0F1D)) : null,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E6E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1C2C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined, color: Color(0xFF7A0F1D)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF7A0F1D), fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
