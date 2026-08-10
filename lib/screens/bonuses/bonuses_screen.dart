import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

class BonusesScreen extends ConsumerWidget {
  const BonusesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(allEmployeesProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Primes'),
        actions: [NotificationBell()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle prime'),
      ),
      body: employees.when(
        data: (list) {
          final withSalary = list.where((e) => e.salaire > 0).toList();
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Types de primes',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        Text(
                          'Gestion des primes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.star_outline,
                      color: AppColors.gold,
                      size: 40,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SectionHeader(title: 'Types de primes disponibles'),
                    const SizedBox(height: 12),
                    ...[
                      (
                        'Prime de rendement',
                        Icons.trending_up,
                        AppColors.success,
                        'Basée sur les performances',
                      ),
                      (
                        'Prime de risque',
                        Icons.warning_amber_outlined,
                        AppColors.warning,
                        'Pour les postes à risque',
                      ),
                      (
                        'Prime exceptionnelle',
                        Icons.star_outline,
                        AppColors.gold,
                        'Attribution ponctuelle',
                      ),
                      (
                        'Prime d\'ancienneté',
                        Icons.history_outlined,
                        AppColors.info,
                        'Selon les années de service',
                      ),
                    ].map(
                      (p) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: p.$3.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(p.$2, color: p.$3),
                          ),
                          title: Text(
                            p.$1,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(p.$4),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.primary,
                            ),
                            onPressed: () =>
                                _showForm(context, ref, type: p.$1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {String? type}) {
    final montantCtrl = TextEditingController();
    final motifCtrl = TextEditingController();
    String? employeeId;
    String? employeeNom;
    String selectedType = type ?? 'Prime de rendement';
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final employees = ref.watch(allEmployeesProvider);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Attribuer une prime',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  employees.when(
                    data: (list) => AppDropdown<String>(
                      label: 'Employé *',
                      value: employeeId,
                      items: list
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.fullName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        final emp = list.firstWhere((e) => e.id == v);
                        setModalState(() {
                          employeeId = v;
                          employeeNom = emp.fullName;
                        });
                      },
                    ),
                    loading: () => const SizedBox(),
                    error: (e, _) => Center(
                      child: Text(
                        "Erreur: $e",
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppDropdown<String>(
                    label: 'Type de prime',
                    value: selectedType,
                    items:
                        [
                              'Prime de rendement',
                              'Prime de risque',
                              'Prime exceptionnelle',
                              'Prime d\'ancienneté',
                            ]
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                    onChanged: (v) => setModalState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Montant (FCFA) *',
                    controller: montantCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Motif',
                    controller: motifCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: loading
                        ? null
                        : () async {
                            if (employeeId == null ||
                                montantCtrl.text.isEmpty) {
                              showSnack(
                                context,
                                'Remplissez tous les champs requis',
                                isError: true,
                              );
                              return;
                            }
                            Navigator.pop(context);
                            final user = ref.read(currentUserProvider);
                            await ref
                                .read(firestoreServiceProvider)
                                .addBonus(
                              BonusModel(
                                id: '',
                                employeeId: employeeId!,
                                employeeNom: employeeNom ?? '',
                                type: selectedType,
                                montant: double.tryParse(
                                  montantCtrl.text,
                                ) ??
                                    0,
                                motif: motifCtrl.text,
                                dateAttribution: DateTime.now(),
                                statut: 'active',
                                createdAt: DateTime.now(),
                                createdBy: user?.id ?? '',
                              ),
                            );
                            if (context.mounted) {
                              showSnack(
                                context,
                                'Prime de ${NumberFormat('#,###').format(double.tryParse(montantCtrl.text) ?? 0)} FCFA attribuée à $employeeNom',
                              );
                            }
                          },
                    child: const Text('Attribuer la prime'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
