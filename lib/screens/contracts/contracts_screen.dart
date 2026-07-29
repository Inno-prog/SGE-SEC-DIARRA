import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'contract_form.dart';

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(contractsProvider(null));
    return Scaffold(
      appBar: AppBar(title: const Text('Contrats')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau contrat'),
      ),
      body: contracts.when(
        data: (list) {
          final expiring = list.where((c) => c.isExpiringSoon).toList();
          return Column(
            children: [
              if (expiring.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${expiring.length} contrat(s) expirent dans moins de 30 jours',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? EmptyState(
                        message: 'Aucun contrat',
                        icon: Icons.description_outlined,
                        actionLabel: 'Ajouter',
                        onAction: () => _showForm(context, ref),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _ContractTile(contract: list[i]),
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

  void _showForm(
    BuildContext context,
    WidgetRef ref, [
    ContractModel? contract,
  ]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContractForm(contract: contract),
    );
  }
}

class _ContractTile extends ConsumerWidget {
  final ContractModel contract;
  const _ContractTile({required this.contract});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: contract.isExpiringSoon
                ? AppColors.warning.withOpacity(0.1)
                : AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.description_outlined,
            color: contract.isExpiringSoon
                ? AppColors.warning
                : AppColors.primary,
          ),
        ),
        title: Text(
          contract.employeeNom,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              contract.type,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Du ${DateFormat('dd/MM/yyyy').format(contract.dateDebut)}${contract.dateFin != null ? ' au ${DateFormat('dd/MM/yyyy').format(contract.dateFin!)}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
            if (contract.isExpiringSoon)
              const Text(
                '⚠️ Expire bientôt',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
          trailing: contract.isExpiringSoon
              ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
              : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: () {
            if (contract.id.isEmpty) return;
            debugPrint('Navigating to contract detail: ${contract.id}');
            context.go('/contracts/${contract.id}');
          },
      ),
    );
  }
}

