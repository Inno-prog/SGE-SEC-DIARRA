import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider(null));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Documents')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadForm(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Ajouter un document'),
      ),
      body: docs.when(
        data: (list) => list.isEmpty
            ? const EmptyState(message: 'Aucun document', icon: Icons.folder_outlined)
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _DocTile(doc: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showUploadForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _DocumentForm(),
    );
  }
}

class _DocTile extends ConsumerWidget {
  final DocumentModel doc;
  const _DocTile({required this.doc});

  IconData get _icon {
    switch (doc.type) {
      case 'contrat': return Icons.description_outlined;
      case 'diplome': return Icons.school_outlined;
      case 'cv': return Icons.person_outline;
      case 'cni': return Icons.badge_outlined;
      case 'certificat_medical': return Icons.medical_services_outlined;
      default: return Icons.insert_drive_file_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(_icon, color: AppColors.primary),
        ),
        title: Text(doc.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${doc.employeeNom} • ${doc.type}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(doc.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              onPressed: () async {
                final ok = await showConfirm(context, title: 'Supprimer', message: 'Supprimer ce document ?');
                if (ok && context.mounted) {
                  await ref.read(firestoreServiceProvider).deleteDocument(doc.id, doc.url);
                  if (context.mounted) showSnack(context, 'Document supprimé');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentForm extends ConsumerStatefulWidget {
  const _DocumentForm();

  @override
  ConsumerState<_DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends ConsumerState<_DocumentForm> {
  final _nomCtrl = TextEditingController();
  String? _employeeId;
  String? _employeeNom;
  String _type = 'contrat';
  XFile? _file;
  bool _loading = false;

  @override
  void dispose() { _nomCtrl.dispose(); super.dispose(); }

  Future<void> _pickFile() async {
    final file = await openFile(acceptedTypeGroups: const [XTypeGroup(extensions: ['pdf'])]);
    if (file != null) {
      setState(() {
        _file = file;
        if (_nomCtrl.text.isEmpty) _nomCtrl.text = _file!.name;
      });
    }
  }

  Future<void> _save() async {
    if (_employeeId == null || _file == null) {
      showSnack(context, 'Sélectionnez un employé et un fichier', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final service = ref.read(firestoreServiceProvider);
      final user = ref.read(currentUserProvider)!;
      final bytes = await _file!.readAsBytes();
      final url = await service.uploadDocument(
        bytes,
        '${AppConstants.storageDocuments}/$_employeeId/${_file!.name}',
      );
      await service.addDocument(DocumentModel(
        id: '',
        employeeId: _employeeId!,
        employeeNom: _employeeNom!,
        type: _type,
        nom: _nomCtrl.text.trim(),
        url: url,
        tailleFichier: 0,
        createdAt: DateTime.now(),
        createdBy: user.id,
      ));
      if (mounted) { Navigator.pop(context); showSnack(context, 'Document uploadé'); }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(allEmployeesProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ajouter un document', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          employees.when(
            data: (list) => AppDropdown<String>(
              label: 'Employé *',
              value: _employeeId,
              items: list.map((e) => DropdownMenuItem(value: e.id, child: Text(e.fullName))).toList(),
              onChanged: (v) {
                final emp = list.firstWhere((e) => e.id == v);
                setState(() { _employeeId = v; _employeeNom = emp.fullName; });
              },
            ),
            loading: () => const SizedBox(),
            error: (e, _) => Center(child: Text("Erreur: $e", style: const TextStyle(color: AppColors.error))),
          ),
          const SizedBox(height: 12),
          AppDropdown<String>(
            label: 'Type de document',
            value: _type,
            items: ['contrat', 'diplome', 'cv', 'cni', 'certificat_medical']
                .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 12),
          AppTextField(label: 'Nom du document', controller: _nomCtrl),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(_file != null ? _file!.name : 'Choisir un fichier'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Uploader'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
