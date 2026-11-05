import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/department_model.dart';

class PositionsScreen extends ConsumerStatefulWidget {
  const PositionsScreen({super.key});

  @override
  ConsumerState<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends ConsumerState<PositionsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final positions = ref.watch(positionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Postes'),
        actions: [NotificationBell()],
      ),
      body: positions.when(
        data: (list) {
          var filtered = list;
          if (_search.isNotEmpty) {
            final q = _search.toLowerCase();
            filtered = filtered
                .where((p) =>
                    p.titre.toLowerCase().contains(q) ||
                    (p.departementNom?.toLowerCase().contains(q) ?? false))
                .toList();
          }

          return _PositionsPageContent(
            positions: filtered,
            search: _search,
            onSearch: (v) => setState(() => _search = v),
            onAdd: () => _showForm(context, ref),
            onEdit: (p) async => _showForm(context, ref, p),
            onDelete: (p) async {
              final ok = await showConfirm(
                context,
                title: 'Supprimer',
                message: 'Supprimer le poste "${p.titre}" ?',
              );
              if (ok && context.mounted) {
                await ref.read(positionApiServiceProvider).deletePosition(p.id);
                if (context.mounted) showSnack(context, 'Poste supprimé');
              }
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, [PositionModel? pos]) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: _PositionForm(position: pos),
        ),
      ),
    );
  }
}

/// Page content using new Pro components
class _PositionsPageContent extends ConsumerWidget {
  final List<PositionModel> positions;
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final Future<void> Function(PositionModel) onEdit;
  final Future<void> Function(PositionModel) onDelete;

  const _PositionsPageContent({
    required this.positions,
    required this.search,
    required this.onSearch,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Page Header
            ProPageHeader(
              icon: Icons.work_outline,
              title: 'Liste des postes',
              subtitle: 'Gestion des postes et grilles salariales',
              count: positions.length,
            ),
            const SizedBox(height: 16),
            // Toolbar
            ProListToolbar(
              searchHint: 'Rechercher un poste, département...',
              onSearch: onSearch,
              onFilterDate: () {},
              addLabel: 'Nouveau poste',
              onAdd: onAdd,
            ),
            const SizedBox(height: 16),
            // Data Table
            ProDataTable<PositionModel>(
              minWidth: 950,
              columns: _buildColumns(),
              items: positions,
            ),
          ],
        ),
      ),
    );
  }

  List<ProColumn<PositionModel>> _buildColumns() {
    return [
      ProColumn<PositionModel>(
        label: 'Titre',
        flex: 3,
        cell: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_outline, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                p.titre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
      ProColumn<PositionModel>(
        label: 'Département',
        flex: 2,
        cell: (p) => p.departementNom == null
            ? const Text('—')
            : ProStatusChip(label: p.departementNom!, color: Colors.blue.shade700),
      ),
      ProColumn<PositionModel>(
        label: 'Salaire min',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => p.salaireMini != null
            ? Text('${NumberFormat('#,###').format(p.salaireMini!)} FCFA')
            : const Text('—'),
      ),
      ProColumn<PositionModel>(
        label: 'Salaire max',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => p.salaireMaxi != null
            ? Text('${NumberFormat('#,###').format(p.salaireMaxi!)} FCFA')
            : const Text('—'),
      ),
      ProColumn<PositionModel>(
        label: 'Créé le',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              '${p.createdAt.day.toString().padLeft(2, '0')}/${p.createdAt.month.toString().padLeft(2, '0')}/${p.createdAt.year}',
            ),
          ],
        ),
      ),
      ProColumn<PositionModel>(
        label: 'Actions',
        flex: 2,
        alignment: Alignment.center,
        cell: (p) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProActionIcon(
              icon: Icons.edit_outlined,
              color: Colors.orange.shade800,
              tooltip: 'Modifier',
              onTap: () => onEdit(p),
            ),
            const SizedBox(width: 8),
            ProActionIcon(
              icon: Icons.delete_outline,
              color: Colors.red.shade700,
              tooltip: 'Supprimer',
              onTap: () => onDelete(p),
            ),
          ],
        ),
      ),
    ];
  }
}

class _PositionForm extends ConsumerStatefulWidget {
  final PositionModel? position;
  const _PositionForm({this.position});

  @override
  ConsumerState<_PositionForm> createState() => _PositionFormState();
}

class _PositionFormState extends ConsumerState<_PositionForm> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _miniCtrl = TextEditingController();
  final _maxiCtrl = TextEditingController();
  String? _deptId;
  String? _deptNom;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.position != null) {
      _titreCtrl.text = widget.position!.titre;
      _descCtrl.text = widget.position!.description ?? '';
      _deptId = widget.position!.departementId;
      _deptNom = widget.position!.departementNom;
      _miniCtrl.text = widget.position!.salaireMini?.toString() ?? '';
      _maxiCtrl.text = widget.position!.salaireMaxi?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _miniCtrl.dispose();
    _maxiCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final positionService = ref.read(positionApiServiceProvider);
      final pos = PositionModel(
        id: widget.position?.id ?? '',
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        departementId: _deptId,
        departementNom: _deptNom,
        salaireMini: double.tryParse(_miniCtrl.text),
        salaireMaxi: double.tryParse(_maxiCtrl.text),
        createdAt: widget.position?.createdAt ?? DateTime.now(),
      );
      if (widget.position != null) {
        await positionService.updatePosition(widget.position!.id, pos);
      } else {
        await positionService.createPosition(pos);
      }
      if (mounted) {
        ref.invalidate(positionsProvider);
        Navigator.pop(context);
        showSnack(context, 'Poste enregistré');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final depts = ref.watch(departmentsProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.position == null ? 'Nouveau poste' : 'Modifier le poste',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              AppTextField(label: 'Titre *', controller: _titreCtrl, validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              depts.when(
                data: (list) => AppDropdown<String>(
                  label: 'Département',
                  value: _deptId,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Aucun')),
                    ...list.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nom))),
                  ],
                  onChanged: (v) {
                    final d = v != null ? list.firstWhere((d) => d.id == v) : null;
                    setState(() { _deptId = v; _deptNom = d?.nom; });
                  },
                ),
                loading: () => const SizedBox(),
                error: (e, _) => Text('Erreur: $e', style: const TextStyle(color: AppColors.error)),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(label: 'Salaire min', controller: _miniCtrl, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Salaire max', controller: _maxiCtrl, keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loading ? null : _save, child: const Text('Enregistrer')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}