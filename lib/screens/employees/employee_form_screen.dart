import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final String? employeeId;
  const EmployeeFormScreen({super.key, this.employeeId});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  dynamic _photoFile;

  // Controllers
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _posteCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _salaireCtrl = TextEditingController();
  final _urgNomCtrl = TextEditingController();
  final _urgTelCtrl = TextEditingController();
  final _urgRelCtrl = TextEditingController();
  final _nationaliteCtrl = TextEditingController();

  String _sexe = 'Masculin';
  String _situation = 'Célibataire';
  String _typeContrat = AppConstants.contractCDI;
  String _statut = AppConstants.statusActive;
  String? _departementId;
  String? _departementNom;
  DateTime _dateNaissance = DateTime(1990, 1, 1);
  DateTime _dateEmbauche = DateTime.now();

  // Documents
  dynamic _contratSigneFile;
  dynamic _demandeFile;
  dynamic _cvFile;
  dynamic _diplomeFile;
  String? _contratSigneName;
  String? _demandeName;
  String? _cvName;
  String? _diplomeName;

  EmployeeModel? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.employeeId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEmployee();
      });
    }
  }

  Future<void> _loadEmployee() {
    final list = ref.read(allEmployeesProvider).value;
    if (list == null) return Future.value();
    final found = list.where((e) => e.id == widget.employeeId).toList();
    if (found.isEmpty) return Future.value();
    final emp = found.first;
    _existing = emp;
    _nomCtrl.text = emp.nom;
    _prenomCtrl.text = emp.prenom;
    _adresseCtrl.text = emp.adresse;
    _telCtrl.text = emp.telephone;
    _emailCtrl.text = emp.email;
    _posteCtrl.text = emp.poste;
    _serviceCtrl.text = emp.service;
    _gradeCtrl.text = emp.grade;
    _salaireCtrl.text = emp.salaire.toString();
    _sexe = emp.sexe;
    _situation = emp.situationMatrimoniale;
    _nationaliteCtrl.text = emp.nationalite;
    _typeContrat = emp.typeContrat;
    _statut = emp.statut;
    _departementId = emp.departementId;
    _departementNom = emp.departementNom;
    _dateNaissance = emp.dateNaissance;
    _dateEmbauche = emp.dateEmbauche;
    if (emp.contactUrgence != null) {
      _urgNomCtrl.text = emp.contactUrgence!.nom;
      _urgTelCtrl.text = emp.contactUrgence!.telephone;
      _urgRelCtrl.text = emp.contactUrgence!.relation;
    }
    setState(() {});
    return Future.value();
  }

  @override
  void dispose() {
    for (final c in [
      _nomCtrl,
      _prenomCtrl,
      _adresseCtrl,
      _telCtrl,
      _emailCtrl,
      _posteCtrl,
      _serviceCtrl,
      _gradeCtrl,
      _salaireCtrl,
      _urgNomCtrl,
      _urgTelCtrl,
      _urgRelCtrl,
      _nationaliteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        imageQuality: 70,
      );
      if (img != null) {
        if (kIsWeb) {
          final bytes = await img.readAsBytes();
          setState(() => _photoFile = bytes);
        } else {
          setState(() => _photoFile = File(img.path));
        }
      }
    } catch (e) {
      if (mounted)
        showSnack(context, 'Erreur sélection photo: $e', isError: true);
    }
  }

  Future<void> _pickPdf(String type) async {
    const typeMap = {
      'contrat': [
        XTypeGroup(extensions: ['pdf']),
      ],
      'demande': [
        XTypeGroup(extensions: ['pdf']),
      ],
      'cv': [
        XTypeGroup(extensions: ['pdf']),
      ],
      'diplome': [
        XTypeGroup(extensions: ['pdf']),
      ],
    };
    final file = await openFile(
      acceptedTypeGroups:
          typeMap[type] ??
          [
            XTypeGroup(extensions: ['pdf']),
          ],
    );
    if (file == null) return;
    final name = file.name;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      setState(() {
        switch (type) {
          case 'contrat':
            _contratSigneFile = bytes;
            _contratSigneName = name;
            break;
          case 'demande':
            _demandeFile = bytes;
            _demandeName = name;
            break;
          case 'cv':
            _cvFile = bytes;
            _cvName = name;
            break;
          case 'diplome':
            _diplomeFile = bytes;
            _diplomeName = name;
            break;
        }
      });
    } else {
      setState(() {
        switch (type) {
          case 'contrat':
            _contratSigneFile = File(file.path);
            _contratSigneName = name;
            break;
          case 'demande':
            _demandeFile = File(file.path);
            _demandeName = name;
            break;
          case 'cv':
            _cvFile = File(file.path);
            _cvName = name;
            break;
          case 'diplome':
            _diplomeFile = File(file.path);
            _diplomeName = name;
            break;
        }
      });
    }
  }

  Future<void> _pickDate(bool isNaissance) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isNaissance ? _dateNaissance : _dateEmbauche,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => isNaissance ? _dateNaissance = picked : _dateEmbauche = picked,
      );
    }
  }

  Future<T> _uploadWithRetry<T>(
    Future<T> Function() uploadFn,
    int maxRetries,
    String label,
  ) async {
    var lastError;
    for (var i = 0; i < maxRetries; i++) {
      try {
        return await uploadFn();
      } catch (e) {
        lastError = e;
        if (mounted)
          showSnack(
            context,
            'Upload $label: tentative ${i + 1}/$maxRetries échouée ($e)',
            isError: true,
          );
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
        }
      }
    }
    throw Exception(
      'Upload $label échoué après $maxRetries tentatives: $lastError',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_departementId == null) {
      showSnack(context, 'Veuillez sélectionner un département', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider)!;

      String? photoUrl = _existing?.photoUrl;
      String? contratSigneFileId = _existing?.contratSigneFileId;
      String? demandeFileId = _existing?.demandeFileId;
      String? cvFileId = _existing?.cvFileId;
      String? diplomeFileId = _existing?.diplomeFileId;

      final matricule =
          _existing?.matricule ?? await service.generateMatricule();

      final uploads = <Future<void>>[];

      if (_photoFile != null) {
        // Encode photo directly as base64 data URL (avoids chunk storage issues).
        // Image is already compressed (300px, 70% quality) so it's well under 1MB.
        final bytes = _photoFile is Uint8List
            ? _photoFile as Uint8List
            : await (_photoFile as File).readAsBytes();
        final base64Str = base64Encode(bytes);
        photoUrl = 'data:image/jpeg;base64,$base64Str';
      }

      if (_contratSigneFile != null) {
        uploads.add(
          _uploadWithRetry(
            () async {
              final fileId = await service.uploadDocument(
                _contratSigneFile!,
                '${AppConstants.storageDocuments}/$matricule/contrat_signe.pdf',
              );
              contratSigneFileId = fileId;
            },
            3,
            'contrat signé',
          ),
        );
      }

      if (_demandeFile != null) {
        uploads.add(
          _uploadWithRetry(
            () async {
              final fileId = await service.uploadDocument(
                _demandeFile!,
                '${AppConstants.storageDocuments}/$matricule/demande.pdf',
              );
              demandeFileId = fileId;
            },
            3,
            'demande',
          ),
        );
      }

      if (_cvFile != null) {
        uploads.add(
          _uploadWithRetry(
            () async {
              final fileId = await service.uploadDocument(
                _cvFile!,
                '${AppConstants.storageDocuments}/$matricule/cv.pdf',
              );
              cvFileId = fileId;
            },
            3,
            'CV',
          ),
        );
      }

      if (_diplomeFile != null) {
        uploads.add(
          _uploadWithRetry(
            () async {
              final fileId = await service.uploadDocument(
                _diplomeFile!,
                '${AppConstants.storageDocuments}/$matricule/diplome.pdf',
              );
              diplomeFileId = fileId;
            },
            3,
            'diplôme',
          ),
        );
      }

      try {
        if (mounted)
          showSnack(
            context,
            'Upload des documents en cours...',
            isError: false,
          );
        await Future.wait(uploads).timeout(const Duration(minutes: 5));
        if (mounted)
          showSnack(
            context,
            'Uploads terminés, enregistrement...',
            isError: false,
          );
      } on TimeoutException {
        throw TimeoutException('Délai d\'upload dépassé (timeout)');
      }

      final emp = EmployeeModel(
        id: _existing?.id ?? '',
        matricule: matricule,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        sexe: _sexe,
        dateNaissance: _dateNaissance,
        photoUrl: photoUrl,
        adresse: _adresseCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        situationMatrimoniale: _situation,
        nationalite: _nationaliteCtrl.text.trim(),
        contactUrgence: _urgNomCtrl.text.isNotEmpty
            ? EmergencyContact(
                nom: _urgNomCtrl.text,
                telephone: _urgTelCtrl.text,
                relation: _urgRelCtrl.text,
              )
            : null,
        poste: _posteCtrl.text.trim(),
        service: _serviceCtrl.text.trim(),
        departementId: _departementId!,
        departementNom: _departementNom!,
        grade: _gradeCtrl.text.trim(),
        dateEmbauche: _dateEmbauche,
        typeContrat: _typeContrat,
        salaire: double.tryParse(_salaireCtrl.text) ?? 0,
        statut: _statut,
        createdAt: _existing?.createdAt ?? DateTime.now(),
        createdBy: user.id,
        contratSigneFileId: contratSigneFileId,
        demandeFileId: demandeFileId,
        cvFileId: cvFileId,
        diplomeFileId: diplomeFileId,
      );

      if (_existing != null) {
        await service.updateEmployee(emp.copyWith());
        await service.addAuditLog(
          userId: user.id,
          userNom: user.fullName,
          action: 'modification',
          collection: AppConstants.colEmployees,
          documentId: emp.id,
          description: 'Modification de ${emp.fullName}',
        );
        if (mounted) showSnack(context, 'Employé mis à jour');
      } else {
        final id = await service.addEmployee(emp);
        await service.addAuditLog(
          userId: user.id,
          userNom: user.fullName,
          action: 'ajout',
          collection: AppConstants.colEmployees,
          documentId: id,
          description: 'Ajout de ${emp.fullName}',
        );
        if (mounted) showSnack(context, 'Employé ajouté avec succès');
      }
      if (mounted) context.go(AppRoutes.employees);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canEdit = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Vous n\'avez pas les droits pour modifier les informations des employés.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    final depts = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.employeeId == null ? 'Nouvel employé' : 'Modifier l\'employé',
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => context.go(AppRoutes.employees),
            child: const Text(
              'Liste',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _photoFile != null
                          ? (kIsWeb && _photoFile is Uint8List
                                ? MemoryImage(_photoFile as Uint8List)
                                : FileImage(_photoFile as File))
                          : null,
                      child: _photoFile == null
                          ? const Icon(
                              Icons.person_outline,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _Section(
              title: 'Informations personnelles',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Nom *',
                        controller: _nomCtrl,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Prénom *',
                        controller: _prenomCtrl,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Sexe',
                        value: _sexe,
                        items: ['Masculin', 'Féminin']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _sexe = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Situation matrimoniale',
                        value: _situation,
                        items:
                            [
                                  'Célibataire',
                                  'Marié(e)',
                                  'Divorcé(e)',
                                  'Veuf/Veuve',
                                ]
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _situation = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Date de naissance',
                  controller: TextEditingController(
                    text: DateFormat('dd/MM/yyyy').format(_dateNaissance),
                  ),
                  readOnly: true,
                  prefixIcon: const Icon(Icons.cake_outlined),
                  onTap: () => _pickDate(true),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Adresse',
                  controller: _adresseCtrl,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Téléphone *',
                        controller: _telCtrl,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Email *',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            _Section(
              title: 'Documents',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Nationalité *',
                        controller: _nationaliteCtrl,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DocUploadTile(
                  label: 'Contrat signé',
                  fileName: _contratSigneName,
                  onPick: () => _pickPdf('contrat'),
                ),
                const SizedBox(height: 8),
                _DocUploadTile(
                  label: 'Demande',
                  fileName: _demandeName,
                  onPick: () => _pickPdf('demande'),
                ),
                const SizedBox(height: 8),
                _DocUploadTile(
                  label: 'CV',
                  fileName: _cvName,
                  onPick: () => _pickPdf('cv'),
                ),
                const SizedBox(height: 8),
                _DocUploadTile(
                  label: 'Diplôme',
                  fileName: _diplomeName,
                  onPick: () => _pickPdf('diplome'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _Section(
              title: 'Informations professionnelles',
              children: [
                depts.when(
                  data: (list) => AppDropdown<String>(
                    label: 'Département *',
                    value: _departementId,
                    items: list
                        .map(
                          (d) =>
                              DropdownMenuItem(value: d.id, child: Text(d.nom)),
                        )
                        .toList(),
                    onChanged: (v) {
                      final dept = list.firstWhere((d) => d.id == v);
                      setState(() {
                        _departementId = v;
                        _departementNom = dept.nom;
                      });
                    },
                    validator: (v) => v == null ? 'Requis' : null,
                  ),
                  loading: () => const LoadingWidget(),
                  error: (e, _) => Center(
                    child: Text(
                      "Erreur: $e",
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Poste *',
                        controller: _posteCtrl,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Service',
                        controller: _serviceCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Grade',
                        controller: _gradeCtrl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Type de contrat',
                        value: _typeContrat,
                        items:
                            [
                                  AppConstants.contractCDI,
                                  AppConstants.contractCDD,
                                  AppConstants.contractStage,
                                  AppConstants.contractConsultant,
                                  AppConstants.contractPrestataire,
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _typeContrat = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Date d\'embauche',
                        controller: TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(_dateEmbauche),
                        ),
                        readOnly: true,
                        prefixIcon: const Icon(Icons.work_outline),
                        onTap: () => _pickDate(false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Salaire de base (FCFA)',
                        controller: _salaireCtrl,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: 'Statut',
                  value: _statut,
                  items:
                      [
                            AppConstants.statusActive,
                            AppConstants.statusSuspended,
                            AppConstants.statusResigned,
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _statut = v!),
                ),
              ],
            ),

            const SizedBox(height: 16),
            _Section(
              title: 'Contact d\'urgence',
              children: [
                AppTextField(label: 'Nom', controller: _urgNomCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Téléphone',
                        controller: _urgTelCtrl,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Relation',
                        controller: _urgRelCtrl,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _DocUploadTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onPick;
  const _DocUploadTile({
    required this.label,
    this.fileName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(fileName ?? label)),
            if (fileName != null)
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              )
            else
              const Icon(Icons.upload_file_outlined, color: AppColors.info),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}
