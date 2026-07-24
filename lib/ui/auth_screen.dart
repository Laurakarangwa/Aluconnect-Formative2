import 'package:flutter/material.dart';
import 'package:formative_assignment/state/app_state.dart';
import 'package:formative_assignment/ui/home_screen.dart';

class AuthScreen extends StatefulWidget {
  final AppState appState;
  const AuthScreen({super.key, required this.appState});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = 'student';
  bool _isSignUp = false;
  bool _isStartupSelected = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final maroon = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [maroon.withOpacity(0.95), const Color(0xFF4E0C15)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFF7E6E8), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Text(
                                _isSignUp ? 'Create your ALU account' : 'Welcome back to Connect',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: maroon),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bridge internships and startup opportunities across ALU.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B2430)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isSignUp)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Full name'),
                            validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Use your school email, for example student123@alustudent.com',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Enter your email';
                            }
                            final email = value.trim().toLowerCase();
                            if (!email.endsWith('@alustudent.com')) {
                              return 'Please use your school email ending in @alustudent.com';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                          validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        if (_isSignUp)
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              suffixIcon: IconButton(
                                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        if (_isSignUp)
                          const SizedBox(height: 12),
                        if (_isSignUp)
                          DropdownButtonFormField<String>(
                            value: _role,
                            items: const [
                              DropdownMenuItem(value: 'student', child: Text('Student')),
                              DropdownMenuItem(value: 'startup', child: Text('Startup owner')),
                              DropdownMenuItem(value: 'both', child: Text('Both student and startup owner')),
                            ],
                            onChanged: (value) => setState(() => _role = value ?? 'student'),
                            decoration: const InputDecoration(labelText: 'Account type'),
                          ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose your experience',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: maroon),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Student'),
                                  selected: _role == 'student',
                                  onSelected: (_) => setState(() => _role = 'student'),
                                ),
                                ChoiceChip(
                                  label: const Text('Startup owner'),
                                  selected: _role == 'startup',
                                  onSelected: (_) => setState(() => _role = 'startup'),
                                ),
                                ChoiceChip(
                                  label: const Text('Both'),
                                  selected: _role == 'both',
                                  onSelected: (_) => setState(() => _role = 'both'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              if (_isSignUp) {
                                if (_passwordController.text != _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Passwords do not match')),
                                  );
                                  return;
                                }
                                final succeeded = await widget.appState.signUp(
                                  _nameController.text,
                                  _emailController.text,
                                  _passwordController.text,
                                  _role,
                                );
                                if (succeeded) {
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
                                    (route) => false,
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(widget.appState.error ?? 'Could not complete this request.')),
                                  );
                                }
                              } else {
                                final succeeded = await widget.appState.signIn(
                                  _emailController.text,
                                  _passwordController.text,
                                  _role,
                                );
                                if (succeeded) {
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => HomeScreen(appState: widget.appState)),
                                    (route) => false,
                                  );
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(widget.appState.error ?? 'Could not sign in.')),
                                  );
                                }
                              }
                            }
                          },
                          child: Text(_isSignUp ? 'Create account' : 'Sign in'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(_isSignUp ? 'Already have an account? Sign in' : 'New here? Create account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
