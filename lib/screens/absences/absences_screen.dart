import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../models/user_model.dart';

// ─── Absences ────────────────────────────────────────────────────────────────
class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider(const AttendanceParams()));
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Absences'),
      ),
      body: attendance.when(
        data: (list) {
          final absences = list.where((a) => a.statut == 'absent').toList();
          return absences.isEmpty
              ? const EmptyState(
                  message: 'Aucune absence enregistrée',
                  icon: Icons.event_busy_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: absences.length,
                  itemBuilder: (_, i) {
                    final a = absences[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: EmployeeAvatar(
                          photoUrl: a.employeePhoto,
                          name: a.employeeNom,
                          radius: 22,
                        ),
                        title: Text(
                          a.employeeNom,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(DateFormat('dd/MM/yyyy').format(a.date)),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            StatusBadge(status: a.statut),
                            if (a.justification != null)
                              const Text(
                                'Justifiée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                ),
                              )
                            else
                              const Text(
                                'Non justifiée',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.error,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
