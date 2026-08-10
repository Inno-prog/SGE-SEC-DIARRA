import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      showSnack(context, 'Minimum 6 caractères', isError: true);
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      showSnack(context, 'Les mots de passe ne correspondent pas', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      // Re-authenticate before updating password
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && _oldPassCtrl.text.isNotEmpty) {
        final credential = EmailAuthProvider.credential(
          email: firebaseUser.email!,
          password: _oldPassCtrl.text,
        );
        await firebaseUser.reauthenticateWithCredential(credential);
      }
      final authService = ref.read(authServiceProvider);
      await authService.updatePassword(_newPassCtrl.text);
      // Clear mustChangePassword if set
      final user = ref.read(currentUserProvider);
      if (user != null && user.mustChangePassword) {
        await authService.updateUser(user.copyWith(mustChangePassword: false));
        ref.invalidate(authStateProvider);
      }
      if (mounted) {
        showSnack(context, 'Mot de passe modifié avec succès');
        _oldPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        final msg = e.code == 'wrong-password' || e.code == 'invalid-credential'
            ? 'Mot de passe actuel incorrect'
            : 'Erreur: ${e.message}';
        showSnack(context, msg, isError: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingWidget();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Sécurité'),
        actions: [NotificationBell()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user.mustChangePassword)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Veuillez changer le mot de passe par défaut et mettre le vôtre.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Changer le mot de passe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  AppTextField(
                    label: 'Ancien mot de passe',
                    controller: _oldPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Nouveau mot de passe',
                    controller: _newPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmPassCtrl,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _changePassword,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Modifier le mot de passe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Double authentification (2FA)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    title: const Text('Activer le 2FA'),
                    subtitle: const Text(
                      'Sécurisez votre compte avec une vérification en deux étapes',
                    ),
                    value: user.twoFactorEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (v) async {
                      await ref
                          .read(authServiceProvider)
                          .updateUser(user.copyWith(twoFactorEnabled: v));
                      if (context.mounted)
                        showSnack(context, v ? '2FA activé' : '2FA désactivé');
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Journal de connexion',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.login, color: AppColors.success),
                    title: const Text('Dernière connexion'),
                    subtitle: Text(
                      user.lastLogin != null
                          ? DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(user.lastLogin!)
                          : 'Inconnue',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
