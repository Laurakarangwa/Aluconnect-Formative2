import 'package:flutter_test/flutter_test.dart';
import 'package:formative_assignment/models/application.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/models/startup_profile.dart';
import 'package:formative_assignment/services/firebase_service.dart';
import 'package:formative_assignment/state/app_state.dart';

void main() {
  test('updateProfilePhoto updates the current user profile photo', () async {
    final appState = AppState();
    await appState.signIn('student@example.com', 'password');

    await appState.updateProfilePhoto('https://example.com/photo.png');

    expect(appState.currentUser?.photoUrl, 'https://example.com/photo.png');
  });

  test('validatePasswordConfirmation rejects mismatched passwords', () {
    final error = FirebaseService.instance.validatePasswordConfirmation('Password123', 'Password124');

    expect(error, 'Passwords do not match');
  });

  test('normalizeRoles returns both roles for dual-role selection', () {
    final roles = FirebaseService.instance.normalizeRoles('both');

    expect(roles, ['student', 'startup']);
  });

  test('demo mode keeps startup, opportunity, and application records in memory', () async {
    final service = FirebaseService.instance;
    final startup = StartupProfile(
      id: 'startup-1',
      ownerId: 'owner-1',
      name: 'Demo Startup',
      description: 'A demo startup',
      sector: 'AI',
      location: 'Kigali',
      createdAt: DateTime.now(),
    );
    final opportunity = Opportunity(
      id: 'opportunity-1',
      startupId: startup.id,
      title: 'Demo opportunity',
      description: 'Build something useful',
      category: 'Engineering',
      location: 'Remote',
      commitment: 'Part-time',
      stipend: '250',
      createdAt: DateTime.now(),
    );
    final application = ApplicationModel(
      id: 'application-1',
      opportunityId: opportunity.id,
      startupId: startup.id,
      studentId: 'student-1',
      studentName: 'Demo Student',
      faculty: 'BSE',
      intakeYear: '2025',
      schoolEmail: 'student@alustudent.com',
      phoneNumber: '123456789',
      coverLetterUrl: 'local-demo://cover.pdf',
      cvUrl: 'local-demo://cv.pdf',
      appliedAt: DateTime.now(),
    );

    await service.createStartup(startup);
    await service.createOpportunity(opportunity);
    await service.applyToOpportunity(application);

    final startups = await service.startups().first;
    final opportunities = await service.opportunities().first;
    final applications = await service.applicationsForStartup(startup.id).first;

    expect(startups.any((item) => item.id == startup.id), isTrue);
    expect(opportunities.any((item) => item.id == opportunity.id), isTrue);
    expect(applications.any((item) => item.id == application.id), isTrue);
  });
}
