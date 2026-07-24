import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:formative_assignment/models/app_user.dart';
import 'package:formative_assignment/models/application.dart';
import 'package:formative_assignment/models/opportunity.dart';
import 'package:formative_assignment/models/startup_profile.dart';
import 'package:formative_assignment/services/firebase_service.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _init();
  }

  final FirebaseService _service = FirebaseService.instance;
  final Map<String, Map<String, dynamic>> _demoAccounts = {};

  AppUser? _currentUser;
  List<StartupProfile> _startups = [];
  List<Opportunity> _opportunities = [];
  List<ApplicationModel> _applications = [];
  bool _loading = true;
  String? _error;
  int _selectedTab = 0;
  String? _transientMessage;
  StreamSubscription<List<StartupProfile>>? _startupSubscription;
  StreamSubscription<List<Opportunity>>? _opportunitySubscription;
  StreamSubscription<List<ApplicationModel>>? _applicationSubscription;

  AppUser? get currentUser => _currentUser;
  List<StartupProfile> get startups => _startups;
  List<Opportunity> get opportunities => _opportunities;
  List<ApplicationModel> get applications => _applications;
  bool get loading => _loading;
  String? get error => _error;
  int get selectedTab => _selectedTab;
  String? get transientMessage => _transientMessage;
  String? get startupLookupKey => _currentUser?.startupId ?? _currentUser?.id;
  bool get isStudent => _currentUser?.roles.contains('student') == true || _currentUser?.role == 'student';
  bool get isStartupOwner => _currentUser?.roles.contains('startup') == true || _currentUser?.role == 'startup';

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid school email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account was found with this email. Please create an account first.';
      case 'wrong-password':
        return 'The password is incorrect. Please try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      case 'configuration-not-found':
        return 'Firebase Auth configuration is missing or not linked to this app. Reconfigure Firebase for the current platform.';
      default:
        return error.message ?? 'Firebase authentication failed. Please check the Firebase project setup.';
    }
  }

  String _demoAccountKey(String email) => email.trim().toLowerCase();

  AppUser _buildDemoUser({required String name, required String email, required String role}) {
    final roles = _service.normalizeRoles(role);
    return AppUser(
      id: 'demo-${_demoAccountKey(email)}',
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
      role: roles.contains('startup') ? 'startup' : 'student',
      roles: roles,
      createdAt: DateTime.now(),
    );
  }

  void setSelectedTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void showTransientMessage(String message) {
    _transientMessage = message;
    notifyListeners();
  }

  void clearTransientMessage() {
    _transientMessage = null;
    notifyListeners();
  }

  Future<void> _init() async {
    _service.authStateChanges.listen((user) async {
      if (user == null) {
        _currentUser = null;
        _loading = false;
        notifyListeners();
        return;
      }

      try {
        _currentUser = await _service.getUser(user.uid);
        _loading = false;
        notifyListeners();
        await loadData();
      } catch (e) {
        _error = e.toString();
        _loading = false;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password, [String preferredRole = 'student']) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.signIn(email, password);
      final firebaseUser = _service.currentUser;
      if (firebaseUser != null) {
        final user = await _service.getUser(firebaseUser.uid);
        final roles = user?.roles.isNotEmpty == true ? user!.roles : _service.normalizeRoles(preferredRole);
        _currentUser = user ?? AppUser(
          id: firebaseUser.uid,
          name: email.isNotEmpty ? email.split('@').first : 'Firebase User',
          email: email,
          role: roles.contains('startup') ? 'startup' : 'student',
          roles: roles,
          createdAt: DateTime.now(),
        );
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      }

      if (!_service.isConfigured) {
        final key = _demoAccountKey(email);
        final account = _demoAccounts[key];
        if (account != null && account['password'] == password) {
          _currentUser = _buildDemoUser(
            name: account['name'] as String,
            email: email,
            role: account['role'] as String,
          );
          _loading = false;
          notifyListeners();
          await loadData();
          return true;
        }

        _demoAccounts[key] = {
          'name': email.split('@').first,
          'password': password,
          'role': preferredRole,
        };
        _currentUser = _buildDemoUser(
          name: email.split('@').first,
          email: email,
          role: preferredRole,
        );
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      }

      _error = 'Unable to sign in with Firebase.';
      _currentUser = null;
    } catch (error) {
      if (!_service.isConfigured) {
        final key = _demoAccountKey(email);
        final account = _demoAccounts[key];
        if (account != null && account['password'] == password) {
          _currentUser = _buildDemoUser(
            name: account['name'] as String,
            email: email,
            role: account['role'] as String,
          );
          _loading = false;
          notifyListeners();
          await loadData();
          return true;
        }

        _demoAccounts[key] = {
          'name': email.split('@').first,
          'password': password,
          'role': preferredRole,
        };
        _currentUser = _buildDemoUser(
          name: email.split('@').first,
          email: email,
          role: preferredRole,
        );
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      } else if (error is FirebaseAuthException) {
        _error = _mapFirebaseAuthError(error);
      } else {
        _error = error.toString();
      }
      _currentUser = null;
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<bool> signUp(String name, String email, String password, String role) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (!_service.isConfigured) {
        final key = _demoAccountKey(email);
        _demoAccounts[key] = {
          'name': name,
          'password': password,
          'role': role,
        };
        _currentUser = _buildDemoUser(name: name, email: email, role: role);
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      }

      await _service.signUp(name, email, password, role);
      final firebaseUser = _service.currentUser;
      if (firebaseUser != null) {
        final user = await _service.getUser(firebaseUser.uid);
        final roles = user?.roles.isNotEmpty == true ? user!.roles : _service.normalizeRoles(role);
        _currentUser = user ?? AppUser(
          id: firebaseUser.uid,
          name: name.isNotEmpty ? name : 'Firebase User',
          email: email,
          role: roles.contains('startup') ? 'startup' : 'student',
          roles: roles,
          createdAt: DateTime.now(),
        );
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      }

      _error = 'Unable to sign up with Firebase.';
      _currentUser = null;
    } catch (error) {
      if (!_service.isConfigured) {
        final key = _demoAccountKey(email);
        _demoAccounts[key] = {
          'name': name,
          'password': password,
          'role': role,
        };
        _currentUser = _buildDemoUser(name: name, email: email, role: role);
        _loading = false;
        notifyListeners();
        await loadData();
        return true;
      }
      if (error is FirebaseAuthException) {
        _error = _mapFirebaseAuthError(error);
      } else {
        _error = error.toString();
      }
      _currentUser = null;
    }

    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    _startupSubscription?.cancel();
    _opportunitySubscription?.cancel();
    _applicationSubscription?.cancel();

    try {
      await _service.signOut();
    } catch (_) {
      // Keep the UI in a safe logged-out state even when Firebase is unavailable.
    }

    _currentUser = null;
    _startups = [];
    _opportunities = [];
    _applications = [];
    _selectedTab = 0;
    _error = null;
    notifyListeners();
  }

  Future<void> createStartup(StartupProfile startup) async {
    await _service.createStartup(startup);
    if (_currentUser != null && (_currentUser!.roles.contains('startup'))) {
      _currentUser = _currentUser!.copyWith(startupId: startup.id);
      await _service.saveUser(_currentUser!);
    }
    _startups.add(startup);
    notifyListeners();
    await loadData();
  }

  Future<void> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return;
    final updatedUser = _currentUser!.copyWith(photoUrl: photoUrl);
    _currentUser = updatedUser;
    await _service.saveUser(updatedUser);
    notifyListeners();
  }

  Future<void> createOpportunity(Opportunity opportunity) async {
    await _service.createOpportunity(opportunity);
    _opportunities.add(opportunity);
    notifyListeners();
    await loadData();
  }

  Future<void> applyToOpportunity(ApplicationModel application) async {
    await _service.applyToOpportunity(application);
    _applications.add(application);
    notifyListeners();
  }

  Future<void> updateApplicationStatus(String applicationId, String status) async {
    await _service.updateApplicationStatus(applicationId, status);
    _applications = _applications.map((application) {
      if (application.id == applicationId) {
        return application.copyWith(status: status);
      }
      return application;
    }).toList();
    notifyListeners();
  }

  Future<void> _restartApplicationSubscription() async {
    _applicationSubscription?.cancel();
    _applicationSubscription = null;

    final userId = _currentUser?.id ?? _service.currentUser?.uid;
    if (userId == null) {
      return;
    }

    if (isStartupOwner) {
      final startupId = startupLookupKey ?? userId;
      _applicationSubscription = _service.applicationsForStartup(startupId).listen((applications) {
        _applications = applications;
        notifyListeners();
      });
    } else {
      _applicationSubscription = _service.applicationsForStudent(userId).listen((applications) {
        _applications = applications;
        notifyListeners();
      });
    }
  }

  Future<void> _syncStartupContext() async {
    if (_currentUser == null || !isStartupOwner) {
      return;
    }

    if (_currentUser!.startupId != null) {
      return;
    }

    for (final startup in _startups) {
      if (startup.ownerId == _currentUser!.id) {
        final updatedUser = _currentUser!.copyWith(startupId: startup.id);
        _currentUser = updatedUser;
        await _service.saveUser(updatedUser);
        notifyListeners();
        break;
      }
    }
  }

  Future<void> loadData() async {
    _startupSubscription?.cancel();
    _opportunitySubscription?.cancel();
    _applicationSubscription?.cancel();

    _startupSubscription = _service.startups().listen((startups) async {
      _startups = startups;
      await _syncStartupContext();
      await _restartApplicationSubscription();
      notifyListeners();
    });

    _opportunitySubscription = _service.opportunities().listen((opportunities) {
      _opportunities = opportunities;
      notifyListeners();
    });

    final userId = _currentUser?.id ?? _service.currentUser?.uid;
    if (userId == null) {
      return;
    }

    await _syncStartupContext();
    await _restartApplicationSubscription();
  }
}
