import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import 'contract_form.dart';

class ContractDetailScreen extends ConsumerWidget {
  final String contractId;
  const ContractDetailScreen({super.key, required this.contractId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('ContractDetailScreen build: contractId=$contractId');
    final contractsAsync = ref.watch(contractsProvider(null));
    final contractAsync = contractsAsync.whenData(
      (list) => list.firstWhere((c) => c.id == contractId),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail contrat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final contract = switch (contractAsync) {
                AsyncData(:final value) => value,
                _ => null,
              };
              if (contract != null) {
                _showForm(context, ref, contract);
              }
            },
            tooltip: 'Modifier',
          ),
        ],
      ),
      body: contractAsync.when(
        data: (contract) {
          final service = ref.read(firestoreServiceProvider);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        contract.employeeNom,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StatusBadge(status: contract.statut),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Text(
                              contract.type,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date de début',
                        value: DateFormat('dd/MM/yyyy').format(contract.dateDebut),
                      ),
                      if (contract.dateFin != null)
                        _DetailRow(
                          icon: Icons.event_outlined,
                          label: 'Date de fin',
                          value: DateFormat('dd/MM/yyyy').format(contract.dateFin!),
                        ),
                      if (contract.renouvellement)
                        _DetailRow(
                          icon: Icons.autorenew_outlined,
                          label: 'Renouvellement',
                          value: 'Automatique',
                        ),
                      if (contract.notes != null && contract.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(contract.notes!),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              contract.piecesJointes.isEmpty
                  ? const EmptyState(
                      message: 'Aucun document',
                      icon: Icons.folder_open_outlined,
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: contract.piecesJointes.length,
                      itemBuilder: (_, i) {
                        final docId = contract.piecesJointes[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.error,
                            ),
                            title: Text(
                              docId,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.visibility_outlined),
                              onPressed: () async {
                                try {
                                  final url = await service.getDocumentDataUrl(docId);
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DocumentViewerScreen(url: url, fileName: docId),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) showSnack(context, 'Erreur: $e', isError: true);
                                }
                              },
                              tooltip: 'Voir',
                            ),
                          ),
                        );
                      },
                    ),
            ],
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(
          child: Column(
            children: [
              const Text('Contrat introuvable'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.contracts),
                child: const Text('Retour à la liste'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, ContractModel contract) {
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;

  const DocumentViewerScreen({
    super.key,
    required this.url,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName)),
      body: url.startsWith('data:')
          ? Center(
              child: Text(
                'Aperçu indisponible',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          : Center(
              child: Text(
                'Ouverture du document...',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
    );
  }
}
