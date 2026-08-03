import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';

// ─── Notifications ───────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              final user = ref.read(currentUserProvider)!;
              ref
                  .read(firestoreServiceProvider)
                  .markAllNotificationsRead(user.id);
            },
            child: const Text(
              'Tout lire',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: notifs.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                message: 'Aucune notification',
                icon: Icons.notifications_none_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _NotifTile(notif: list[i]),
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

class _NotifTile extends ConsumerWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  IconData get _icon {
    switch (notif.type) {
      case 'conge':
        return Icons.beach_access_outlined;
      case 'contrat':
        return Icons.description_outlined;
      case 'anniversaire':
        return Icons.cake_outlined;
      case 'absence':
        return Icons.event_busy_outlined;
      case 'document':
        return Icons.folder_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: notif.isRead
            ? Colors.white
            : AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notif.isRead
              ? Colors.transparent
              : AppColors.primary.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_icon, color: AppColors.primary, size: 20),
        ),
        title: Text(
          notif.titre,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.message, style: const TextStyle(fontSize: 12)),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notif.createdAt),
              style: const TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: !notif.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!notif.isRead) {
            ref.read(firestoreServiceProvider).markNotificationRead(notif.id);
          }
        },
      ),
    );
  }
}

// ─── Messaging ───────────────────────────────────────────────────────────────
class MessagingScreen extends ConsumerWidget {
  const MessagingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Messagerie'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversation(context, ref),
        child: const Icon(Icons.edit_outlined),
      ),
      body: conversations.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                message: 'Aucune conversation',
                icon: Icons.chat_outlined,
              )
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final conv = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        (conv['nom'] as String? ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      conv['nom'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      conv['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: conv['lastMessageAt'] != null
                        ? Text(
                            DateFormat('HH:mm').format(
                              (conv['lastMessageAt'] as dynamic).toDate(),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          )
                        : null,
                    onTap: () => _openConversation(
                      context,
                      conv['id'],
                      conv['nom'] ?? '',
                    ),
                  );
                },
              ),
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  void _openConversation(BuildContext context, String id, String nom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ConversationScreen(conversationId: id, nom: nom),
      ),
    );
  }

  void _showNewConversation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewConversationSheet(),
    );
  }
}

class _NewConversationSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState extends ConsumerState<_NewConversationSheet> {
  final _nomCtrl = TextEditingController();
  final List<String> _selectedIds = [];
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nomCtrl.text.isEmpty || _selectedIds.isEmpty) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final participants = [user.id, ..._selectedIds];
      await ref
          .read(firestoreServiceProvider)
          .createConversation(participants, _nomCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Conversation créée');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(usersProvider);
    final me = ref.watch(currentUserProvider)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
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
              'Nouvelle conversation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppTextField(label: 'Nom de la conversation', controller: _nomCtrl),
            const SizedBox(height: 12),
            const Text(
              'Participants:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            users.when(
              data: (list) => SizedBox(
                height: 200,
                child: ListView(
                  children: list
                      .where((u) => u.id != me.id)
                      .map(
                        (u) => CheckboxListTile(
                          title: Text(u.fullName),
                          subtitle: Text(u.role),
                          value: _selectedIds.contains(u.id),
                          activeColor: AppColors.primary,
                          onChanged: (v) => setState(
                            () => v!
                                ? _selectedIds.add(u.id)
                                : _selectedIds.remove(u.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Text(
                  "Erreur: $e",
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _create,
              child: const Text('Créer'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ConversationScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String nom;
  const _ConversationScreen({required this.conversationId, required this.nom});

  @override
  ConsumerState<_ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<_ConversationScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider)!;
    final msg = MessageModel(
      id: '',
      conversationId: widget.conversationId,
      senderId: user.id,
      senderNom: user.fullName,
      senderPhoto: user.photoUrl,
      contenu: _msgCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    _msgCtrl.clear();
    await ref.read(firestoreServiceProvider).sendMessage(msg);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients)
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(messagesProvider(widget.conversationId));
    final me = ref.watch(currentUserProvider)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: Text(widget.nom),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (list) => ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[i];
                  final isMe = m.senderId == me.id;
                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Text(
                              m.senderNom,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          Text(
                            m.contenu,
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(m.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white60 : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Text(
                  "Erreur: $e",
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Agenda ──────────────────────────────────────────────────────────────────
class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(agendaProvider);
    final user = ref.watch(currentUserProvider);
    final canCreateEvent = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH ||
            user.role == AppConstants.roleChefService);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
          ),
          title: const Text('Agenda'),
        ),
        body: const Center(
          child: Text('Vous devez être connecté pour voir l\'agenda.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => ref.read(drawerKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Agenda'),
      ),
      floatingActionButton: canCreateEvent
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Nouvel événement'),
            )
          : null,
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
              onDaySelected: (selected, focused) => setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              }),
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accentLight,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              eventLoader: (day) {
                return events.value
                        ?.where((e) => isSameDay(e.dateDebut, day))
                        .toList() ??
                    [];
              },
            ),
          ),
          Expanded(
            child: events.when(
              data: (list) {
                final filtered = _selectedDay != null
                    ? list
                          .where((e) => isSameDay(e.dateDebut, _selectedDay))
                          .toList()
                    : list;
                return filtered.isEmpty
                    ? const EmptyState(
                        message: 'Aucun événement',
                        icon: Icons.event_outlined,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _EventTile(event: filtered[i]),
                      );
              },
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erreur: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AgendaForm(initialDate: _selectedDay),
    );
  }
}

class _EventTile extends ConsumerWidget {
  final AgendaModel event;
  const _EventTile({required this.event});

  Color get _color {
    switch (event.type) {
      case 'reunion':
        return AppColors.primary;
      case 'rdv':
        return AppColors.info;
      case 'conge':
        return AppColors.success;
      case 'evenement':
        return AppColors.gold;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final canDelete = user != null &&
        (user.role == AppConstants.roleAdmin ||
            user.role == AppConstants.roleDirector ||
            user.role == AppConstants.roleRH);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          event.titre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('HH:mm').format(event.dateDebut)} → ${DateFormat('HH:mm').format(event.dateFin)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                event.type,
                style: TextStyle(color: _color, fontSize: 11),
              ),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: () async {
                  final ok = await showConfirm(
                    context,
                    title: 'Supprimer',
                    message: 'Supprimer cet événement ?',
                  );
                  if (ok && context.mounted) {
                    await ref
                        .read(firestoreServiceProvider)
                        .deleteAgendaEvent(event.id);
                    ref.invalidate(agendaProvider);
                    if (context.mounted) showSnack(context, 'Événement supprimé');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _AgendaForm extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  const _AgendaForm({this.initialDate});

  @override
  ConsumerState<_AgendaForm> createState() => _AgendaFormState();
}

class _AgendaFormState extends ConsumerState<_AgendaForm> {
  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'reunion';
  late DateTime _dateDebut;
  late DateTime _dateFin;
  TimeOfDay _heureDebut = TimeOfDay.now();
  TimeOfDay _heureFin = TimeOfDay.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _dateDebut = widget.initialDate ?? DateTime.now();
    _dateFin = _dateDebut.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider)!;
      final dateDebut = DateTime(
        _dateDebut.year,
        _dateDebut.month,
        _dateDebut.day,
        _heureDebut.hour,
        _heureDebut.minute,
      );
      final dateFin = DateTime(
        _dateFin.year,
        _dateFin.month,
        _dateFin.day,
        _heureFin.hour,
        _heureFin.minute,
      );
      await ref
          .read(firestoreServiceProvider)
          .addAgendaEvent(
            AgendaModel(
              id: '',
              titre: _titreCtrl.text.trim(),
              description: _descCtrl.text.trim(),
              type: _type,
              dateDebut: dateDebut,
              dateFin: dateFin,
              createdBy: user.id,
              createdAt: DateTime.now(),
            ),
          );
      ref.invalidate(agendaProvider);
      if (mounted) {
        Navigator.pop(context);
        showSnack(context, 'Événement ajouté');
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nouvel événement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Titre *',
                controller: _titreCtrl,
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: 'Type',
                value: _type,
                items: ['reunion', 'rdv', 'conge', 'evenement']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Description',
                controller: _descCtrl,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _heureDebut,
                        );
                        if (picked != null) setState(() => _heureDebut = picked);
                      },
                      icon: const Icon(Icons.access_time_outlined),
                      label: Text('Début: ${_heureDebut.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _heureFin,
                        );
                        if (picked != null) setState(() => _heureFin = picked);
                      },
                      icon: const Icon(Icons.access_time_outlined),
                      label: Text('Fin: ${_heureFin.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: const Text('Ajouter'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
