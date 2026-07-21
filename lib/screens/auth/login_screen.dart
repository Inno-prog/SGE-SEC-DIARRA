import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../core/constants/app_constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signIn(_emailCtrl.text.trim(), _passCtrl.text);
    } catch (e) {
      if (mounted)
        showSnack(context, 'Email ou mot de passe incorrect', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _seedUsers() async {
    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      final db = FirebaseFirestore.instance;

      final users = [
        {
          'email': ' ',
          'password': 'Admin123!',
          'nom': 'Admin',
          'prenom': 'SGE',
          'role': AppConstants.roleAdmin,
        },
        {
          'email': 'rh@secdiarra.com',
          'password': 'Rh123!',
          'nom': 'Dupont',
          'prenom': 'Marie',
          'role': AppConstants.roleRH,
        },
        {
          'email': 'director@secdiarra.com',
          'password': 'Director123!',
          'nom': 'Martin',
          'prenom': 'Pierre',
          'role': AppConstants.roleDirector,
        },
        {
          'email': 'chef@secdiarra.com',
          'password': 'Chef123!',
          'nom': 'Bernard',
          'prenom': 'Sophie',
          'role': AppConstants.roleChefService,
        },
        {
          'email': 'employee@secdiarra.com',
          'password': 'Employee123!',
          'nom': 'Petit',
          'prenom': 'Jean',
          'role': AppConstants.roleEmployee,
        },
      ];

      for (final u in users) {
        try {
          final cred = await auth.createUserWithEmailAndPassword(
            email: u['email']!,
            password: u['password']!,
          );
          await db.collection(AppConstants.colUsers).doc(cred.user!.uid).set({
            'email': u['email'],
            'nom': u['nom'],
            'prenom': u['prenom'],
            'role': u['role'],
            'employeeId': null,
            'photoUrl': null,
            'isActive': true,
            'twoFactorEnabled': false,
            'createdAt': Timestamp.now(),
            'lastLogin': null,
            'permissions': [],
          });
          await auth.signOut();
        } catch (e) {
          // User might already exist, continue
        }
      }
      if (mounted) showSnack(context, '', isError: false);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel
          if (MediaQuery.of(context).size.width >= 800)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business, size: 80, color: Colors.white),
                    SizedBox(height: 24),
                    Text(
                      'SGE SEC DIARRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Système de Gestion des Employés\nModerne · Efficace · Sécurisé',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Right panel
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bienvenue sur SGE Secdiarra',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        AppTextField(
                          label: 'Email',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Email invalide'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Mot de passe',
                          controller: _passCtrl,
                          obscureText: _obscure,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mot de passe trop court'
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loading ? null : _seedUsers,
                          child: const Text(
                            '',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
