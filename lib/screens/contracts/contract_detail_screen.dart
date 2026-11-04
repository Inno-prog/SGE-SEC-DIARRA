import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../utils/document_viewer_web.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              GoRouter.of(context).pop();
            } else {
              context.go('/contracts');
            }
          },
        ),
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
          final documentsAsync = ref.watch(contractDocumentsProvider(contract.piecesJointes));

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
                          _StatusChip(status: contract.statut),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                        )
                      else
                        _DetailRow(
                          icon: Icons.event_outlined,
                          label: 'Type',
                          value: 'CDI (Durée indéterminée)',
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
                'Documents joints',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              documentsAsync.when(
                data: (documents) {
                  if (documents.isEmpty) {
                    return const EmptyState(
                      message: 'Aucun document',
                      icon: Icons.folder_open_outlined,
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: documents.length,
                    itemBuilder: (_, i) {
                      final doc = documents[i];
                      return _DocumentTile(
                        document: doc,
                        onView: () async {
                          try {
                            // Use document URL directly for web (opens in new tab)
                            if (doc.url.isNotEmpty) {
                              await openDocumentUrl(doc.url, doc.nom);
                            } else {
                              // Fallback to download if no URL
                              final documentService = ref.read(documentApiServiceProvider);
                              final bytes = await documentService.downloadDocument(doc.id);
                              if (context.mounted) {
                                await openDocumentBytes(bytes, documentService.guessMimeType(doc.nom), doc.nom);
                              }
                            }
                          } catch (e) {
                            if (context.mounted) showSnack(context, 'Erreur: $e', isError: true);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const LoadingWidget(),
                error: (e, _) => Center(
                  child: Column(
                    children: [
                      const Text('Erreur lors du chargement des documents'),
                      const SizedBox(height: 12),
                      Text('$e', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                    ],
                  ),
                ),
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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ContractForm(contract: contract),
        ),
      ),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'en_attente':
        color = AppColors.warning;
        label = 'En attente';
        break;
      case 'actif':
        color = AppColors.success;
        label = 'Actif';
        break;
      case 'expire':
        color = AppColors.error;
        label = 'Expiré';
        break;
      case 'resilie':
        color = AppColors.error;
        label = 'Résilié';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final DocumentModel document;
  final VoidCallback onView;

  const _DocumentTile({
    required this.document,
    required this.onView,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) return parts.last.toUpperCase();
    return 'FILE';
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return AppColors.error;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Colors.purple;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getFileColor(document.nom);
    final icon = _getFileIcon(document.nom);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.nom,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getFileExtension(document.nom),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatFileSize(document.tailleFichier),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd/MM/yyyy').format(document.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              onPressed: onView,
              tooltip: 'Voir / Ouvrir',
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}