import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class ContractForm extends ConsumerStatefulWidget {
  final ContractModel? contract;
  const ContractForm({this.contract});

  @override
  ConsumerState<ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends ConsumerState<ContractForm> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  String _type = AppConstants.contractCDI;
  String _statut = AppConstants.contractValidated;
  DateTime _dateDebut = DateTime.now();
  DateTime? _dateFin;
  bool _renouvellement = false;
  bool _loading = false;
  List<String> _contractDocuments = [];
  bool _uploadingDoc = false;

  @override
  void initState() {
    super.initState();
    if (widget.contract != null) {
      _employeeId = widget.contract!.employeeId;
      _employeeNom = widget.contract!.employeeNom;
      _type = widget.contract!.type;
      _statut = widget.contract!.statut;
      _dateDebut = widget.contract!.dateDebut;
      _dateFin = widget.contract!.dateFin;
      _renouvellement = widget.contract!.renouvellement;
      _notesCtrl.text = widget.contract!.notes ?? '';
      _contractDocuments = List.from(widget.contract!.piecesJointes);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickContractDocument() async {
    if (_employeeId == null) {
      if (mounted) showSnack(context, 'Veuillez sélectionner un employé d\'abord', isError: true);
      return;
    }
    final file = await openFile(
      acceptedTypeGroups: const [XTypeGroup(extensions: ['pdf'])],
    );
    if (file == null) return;
    setState(() => _uploadingDoc = true);
    try {
      final documentService = ref.read(documentApiServiceProvider);
      dynamic docFile;
      if (kIsWeb) {
        docFile = await file.readAsBytes();
      } else {
        docFile = File(file.path);
      }

      // Read file bytes
      final bytes = kIsWeb
          ? docFile as Uint8List
          : await (docFile as File).readAsBytes();

      // For contract documents, we use the employee ID (not contract ID)
      // If it's a new entity without employee, we can't upload documents yet
      final String employeeIdForUpload = _employeeId ?? '';
      if (employeeIdForUpload.isEmpty) {
        if (mounted) showSnack(context, 'Impossible d\'uploader: aucun employé associé', isError: true);
        return;
      }

      final response = await documentService.uploadDocument(
        employeeIdForUpload,
        'contrat',  // Prisma enum: contrat
        file.name,
        bytes,
      );
      final fileId = response['document']['id'] as String?;

      if (fileId != null) {
        setState(() {
          _contractDocuments.add(fileId);
        });
        if (mounted) showSnack(context, 'Document uploadé');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _uploadingDoc = false);
    }
  }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null)
      setState(() => isDebut ? _dateDebut = picked : _dateFin = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_employeeId == null) {
      showSnack(context, 'Veuillez sélectionner un employé', isError: true);
      return;
    }

    final String employeeId = _employeeId!;
    final String employeeNom = _employeeNom!;

    setState(() => _loading = true);
    try {
      final contractService = ref.read(contractApiServiceProvider);
      final user = ref.read(currentUserProvider)!;
      // Calculer la durée en mois automatiquement
      int? dureeCalculee;
      if (_type == AppConstants.contractCDI) {
        dureeCalculee = null; // CDI = durée indéterminée (pas de durée fixe)
      } else if (_dateFin != null) {
        final diff = _dateFin!.difference(_dateDebut).inDays;
        dureeCalculee = (diff / 30).ceil(); // Approximation en mois
        if (dureeCalculee < 1) dureeCalculee = 1;
      }

      final c = ContractModel(
        id: widget.contract?.id ?? '',
        employeeId: employeeId,
        employeeNom: employeeNom,
        type: _type,
        dateDebut: _dateDebut,
        dateFin: _type == AppConstants.contractCDI ? null : _dateFin,
        dureeEnMois: dureeCalculee,
        renouvellement: _renouvellement,
        notes: _notesCtrl.text.trim(),
        piecesJointes: _contractDocuments,
        statut: _statut,
        createdAt: widget.contract?.createdAt ?? DateTime.now(),
        createdBy: user.id,
      );
      if (widget.contract != null) {
        await contractService.updateContract(widget.contract!.id, c);
      } else {
        await contractService.createContract(c);
      }
      if (mounted) {
        // contractsProvider is a family provider with employeeId parameter
        ref.invalidate(contractsProvider(_employeeId));
        ref.invalidate(contractsProvider(null)); // for all contracts list
        ref.invalidate(expiringContractsProvider);
        Navigator.pop(context);
        showSnack(context, 'Contrat enregistré');
      }
    } on DioException catch (e) {
      // Gestion spécifique des erreurs Dio
      String errorMsg = 'Erreur lors de la création du contrat';
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map && data['error'] != null) {
          errorMsg = data['error'].toString();
        } else if (data is Map && data['details'] != null) {
          // Erreurs de validation Zod
          final details = data['details'] as List;
          errorMsg = details.map((d) => '${d['field']}: ${d['message']}').join('\n');
        }
      }
      if (mounted) showSnack(context, errorMsg, isError: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(allEmployeesProvider);
    final bool isLocked = widget.contract != null &&
        (widget.contract!.statut == AppConstants.contractValidated ||
         widget.contract!.statut == AppConstants.contractActive);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: isLocked,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.contract == null
                      ? 'Nouveau contrat'
                      : 'Modifier le contrat',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline, color: AppColors.warning, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Contrat validé, modifications bloquées',
                            style: TextStyle(color: AppColors.warning, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                employees.when(
                  data: (list) => AppDropdown<String>(
                    label: 'Employé / Société',
                    value: _employeeId,
                    items: list
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.fullName),
                            ),
                          )
                          .toList(),
                    onChanged: (String? v) {
                      if (v != null) {
                        final emp = list.firstWhere((e) => e.id == v);
                        setState(() {
                          _employeeId = v;
                          _employeeNom = emp.fullName;
                        });
                      }
                    },
                    validator: (String? v) {
                      if (v == null) return 'Requis';
                      return null;
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
                  label: 'Type de contrat',
                  value: _type,
                  items:
                      [
                            AppConstants.contractCDI,
                            AppConstants.contractCDD,
                            AppConstants.contractStage,
                            AppConstants.contractFreelance,
                          ]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                  onChanged: (String? v) {
                    if (v == null) return;
                    setState(() {
                      _type = v;
                      if (v == AppConstants.contractCDI) {
                        _dateFin = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Statut'),
                  value: _statut,
                  items: const [
                    DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                    DropdownMenuItem(value: 'actif', child: Text('Actif')),
                    DropdownMenuItem(value: 'expire', child: Text('Expiré')),
                    DropdownMenuItem(value: 'resilie', child: Text('Résilié')),
                  ],
                  onChanged: (String? v) {
                    if (!isLocked && v != null) setState(() => _statut = v);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Date de début',
                        controller: TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_dateDebut),
                        ),
                        readOnly: true,
                        onTap: () => _pickDate(true),
                      ),
                    ),
                    if (_type != AppConstants.contractCDI) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: 'Date de fin',
                          controller: TextEditingController(
                            text: _dateFin != null
                                ? DateFormat('dd/MM/yyyy').format(_dateFin!)
                                : '',
                          ),
                          readOnly: true,
                          onTap: () => _pickDate(false),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Renouvellement automatique'),
                  value: _renouvellement,
                  onChanged: (v) => setState(() => _renouvellement = v),
                  activeColor: AppColors.primary,
                  contentPadding: EdgeInsets.zero,
                ),
                AppTextField(label: 'Notes', controller: _notesCtrl, maxLines: 3),
                const SizedBox(height: 12),
                const Text(
                  'Documents du contrat',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.error),
                    title: Text(
                      _contractDocuments.isEmpty
                          ? 'Aucun document'
                          : '${_contractDocuments.length} document(s)',
                    ),
                    trailing: _uploadingDoc
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.add, color: AppColors.primary),
                            onPressed: _uploadingDoc || isLocked ? null : _pickContractDocument,
                          ),
                  ),
                ),
                if (_contractDocuments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ..._contractDocuments.map(
                    (docId) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              docId,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            onPressed: isLocked
                                ? null
                                : () {
                                    setState(() {
                                      _contractDocuments.remove(docId);
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: const Text('Enregistrer'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
