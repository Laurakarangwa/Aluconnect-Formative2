import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:formative_assignment/models/application.dart';
import 'package:formative_assignment/models/app_user.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/models/startup_profile.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  final Map<String, ApplicationModel> _demoApplications = {};

  bool get isConfigured {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get auth => isConfigured ? (_auth ??= FirebaseAuth.instance) : null;
  FirebaseFirestore? get firestore => isConfigured ? (_firestore ??= FirebaseFirestore.instance) : null;
  FirebaseStorage? _storage;
  FirebaseStorage? get storage => isConfigured ? (_storage ??= FirebaseStorage.instance) : null;

  User? get currentUser => auth?.currentUser;

  Stream<User?> get authStateChanges => auth != null ? auth!.authStateChanges() : const Stream.empty();

  Future<void> signIn(String email, String password) async {
    final auth = this.auth;
    if (auth == null) {
      return;
    }
    await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  List<String> normalizeRoles(String role) {
    final normalizedRole = role.toLowerCase();
    if (normalizedRole == 'both' || normalizedRole == 'student_startup' || normalizedRole == 'student+startup') {
      return ['student', 'startup'];
    }
    if (normalizedRole == 'startup') {
      return ['startup'];
    }
    return ['student'];
  }

  String? validatePasswordConfirmation(String password, String confirmation) {
    if (password.isEmpty || confirmation.isEmpty) {
      return null;
    }
    return password == confirmation ? null : 'Passwords do not match';
  }

  Future<void> signUp(String name, String email, String password, String role) async {
    final auth = this.auth;
    if (auth == null) {
      return;
    }
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final roles = normalizeRoles(role);

    final user = AppUser(
      id: credential.user!.uid,
      name: name,
      email: email,
      role: roles.contains('startup') ? 'startup' : 'student',
      roles: roles,
      createdAt: DateTime.now(),
      skills: roles.contains('student') ? ['Research', 'Communication'] : const [],
    );

    await firestore?.collection('users').doc(user.id).set(user.toMap());
  }

  Future<AppUser?> getUser(String uid) async {
    if (!isConfigured) {
      return null;
    }
    final firestore = this.firestore;
    if (firestore == null) {
      return null;
    }
    final snapshot = await firestore.collection('users').doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromMap(snapshot.data()!);
  }

  Future<void> saveUser(AppUser user) async {
    final firestore = this.firestore;
    if (firestore == null) {
      return;
    }
    await firestore.collection('users').doc(user.id).set(user.toMap());
  }

  Future<void> createStartup(StartupProfile startup) async {
    final firestore = this.firestore;
    if (firestore == null) {
      return;
    }
    await firestore.collection('startups').doc(startup.id).set(startup.toMap());
  }

  Stream<List<StartupProfile>> startups() {
    final firestore = this.firestore;
    if (firestore == null) {
      return Stream.value(const <StartupProfile>[]);
    }
    return firestore.collection('startups').orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => StartupProfile.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> createOpportunity(Opportunity opportunity) async {
    final firestore = this.firestore;
    if (firestore == null) {
      return;
    }
    await firestore.collection('opportunities').doc(opportunity.id).set(opportunity.toMap());
  }

  Stream<List<Opportunity>> opportunities() {
    final firestore = this.firestore;
    if (firestore == null) {
      return Stream.value(const <Opportunity>[]);
    }
    return firestore.collection('opportunities').orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Opportunity.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<String> uploadFile(Uint8List bytes, String path, String contentType) async {
    final storage = this.storage;
    if (storage == null) {
      return 'local-demo://$path';
    }

    try {
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': currentUser?.uid ?? 'anonymous',
        },
      );
      final ref = storage.ref().child(path);
      final task = await ref.putData(bytes, metadata).timeout(const Duration(seconds: 10));
      return await task.ref.getDownloadURL().timeout(const Duration(seconds: 8));
    } catch (_) {
      return 'local-demo://$path';
    }
  }

  Future<void> applyToOpportunity(ApplicationModel application) async {
  final firestore = this.firestore;

  print("🔥 Firebase configured: $isConfigured");
  print("🔥 Firestore instance: $firestore");
  print("🔥 Current user: ${currentUser?.uid}");

  if (firestore == null) {
    print("❌ Firestore is NULL - saving locally");
    _demoApplications[application.id] = application;
    return;
  }

  try {
    await firestore
        .collection('applications')
        .doc(application.id)
        .set(application.toMap())
        .timeout(const Duration(seconds: 10));

    print("✅ Application saved to Firestore");
  } catch (e, stackTrace) {
    print("🔥 FIRESTORE ERROR: $e");
    print(stackTrace);
    _demoApplications[application.id] = application;
  }
}

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    final firestore = this.firestore;
    if (firestore == null) {
      final current = _demoApplications[applicationId];
      if (current != null) {
        _demoApplications[applicationId] = current.copyWith(status: status);
      }
      return;
    }

    try {
      await firestore.collection('applications').doc(applicationId).update({'status': status});
    } catch (_) {
      final current = _demoApplications[applicationId];
      if (current != null) {
        _demoApplications[applicationId] = current.copyWith(status: status);
      }
    }
  }

  Stream<List<ApplicationModel>> applicationsForStudent(String studentId) {
    final firestore = this.firestore;
    if (firestore == null) {
      final demoList = _demoApplications.values.where((application) => application.studentId == studentId).toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return Stream.value(demoList);
    }

    try {
      return firestore.collection('applications')
          .where('studentId', isEqualTo: studentId)
          .orderBy('appliedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ApplicationModel.fromMap(doc.data()))
                .toList(),
          );
    } catch (_) {
      final demoList = _demoApplications.values.where((application) => application.studentId == studentId).toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return Stream.value(demoList);
    }
  }

  Stream<List<ApplicationModel>> applicationsForStartup(String startupId) {
    final firestore = this.firestore;
    if (firestore == null) {
      final demoList = _demoApplications.values.where((application) => application.startupId == startupId).toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return Stream.value(demoList);
    }

    try {
      return firestore.collection('applications')
          .where('startupId', isEqualTo: startupId)
          .orderBy('appliedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ApplicationModel.fromMap(doc.data()))
                .toList(),
          );
    } catch (_) {
      final demoList = _demoApplications.values.where((application) => application.startupId == startupId).toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));
      return Stream.value(demoList);
    }
  }

  Future<void> signOut() async {
    final auth = this.auth;
    if (auth == null) {
      return;
    }
    await auth.signOut();
  }
}
