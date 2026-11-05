import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/providers.dart';
import '../../models/employee_model.dart';
import '../../models/user_model.dart';
import '../../models/models.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (subtitle != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  subtitle!,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class EmployeeAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const EmployeeAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final provider = _imageProvider(photoUrl!);
      if (provider != null) {
        return CircleAvatar(radius: radius, backgroundImage: provider);
      }
    }
    final initials = name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.6,
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String url) {
    if (url.startsWith('data:')) {
      final comma = url.indexOf(',');
      if (comma == -1) return null;
      final base64 = url.substring(comma + 1);
      final bytes = base64Decode(base64);
      return MemoryImage(bytes);
    }
    return CachedNetworkImageProvider(url);
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.$1.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.$1.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.$2,
        style: TextStyle(
          color: config.$1,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, String) _getConfig(String s) {
    switch (s.toLowerCase()) {
      case 'actif':
      case 'present':
      case 'approuvé':
      case 'payé':
      case 'validé':
        return (AppColors.success, s);
      case 'suspendu':
      case 'absent':
      case 'refusé':
        return (AppColors.error, s);
      case 'en_attente':
        return (AppColors.warning, 'En attente');
      case 'retard':
        return (AppColors.warning, 'Retard');
      case 'demissionnaire':
        return (Colors.grey, 'Démissionnaire');
      case 'conge':
        return (AppColors.info, 'Congé');
      default:
        return (Colors.grey, s);
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmer',
    this.confirmColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

void showSnack(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
    ),
  );
}

Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => ConfirmDialog(title: title, message: message),
      ) ??
      false;
}

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final unread = user != null
        ? ref.watch(unreadNotificationsCountProvider(user.id))
        : 0;
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unread > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Color(0xFF580000),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () => context.go(AppRoutes.notifications),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LIST PAGE LAYOUT - Professional list page with search, filter, add button
// ═══════════════════════════════════════════════════════════════════════════════

/// Full-page layout for list screens: header + toolbar + table + pagination
class ListPageLayout extends StatefulWidget {
  final IconData headerIcon;
  final String headerTitle;
  final String headerSubtitle;
  final int totalCount;
  final String searchHint;
  final String addButtonLabel;
  final VoidCallback? onAdd;
  final void Function(String)? onSearch;
  final void Function(DateTimeRange?)? onDateFilter;
  final Widget Function(List<dynamic> pageItems) tableBuilder;
  final List<dynamic> allItems;
  final int pageSize;

  const ListPageLayout({
    super.key,
    required this.headerIcon,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.totalCount,
    required this.searchHint,
    required this.addButtonLabel,
    this.onAdd,
    this.onSearch,
    this.onDateFilter,
    required this.tableBuilder,
    required this.allItems,
    this.pageSize = 10,
  });

  @override
  State<ListPageLayout> createState() => _ListPageLayoutState();
}

class _ListPageLayoutState extends State<ListPageLayout> {
  int _page = 0;
  int _pageSize = 10;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _pageSize = widget.pageSize;
  }

  List<dynamic> get _pageItems {
    final start = _page * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.allItems.length);
    if (start >= widget.allItems.length) return [];
    return widget.allItems.sublist(start, end);
  }

  int get _totalPages => (widget.allItems.length / _pageSize).ceil().clamp(1, 9999);

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    setState(() => _dateRange = picked);
    widget.onDateFilter?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.headerIcon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.headerTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.headerSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.totalCount} enregistrement(s)',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Toolbar ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8E9ED)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: widget.onSearch,
                    decoration: InputDecoration(
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    _dateRange == null
                        ? 'Filtrer par date'
                        : '${DateFormat('dd/MM').format(_dateRange!.start)} – ${DateFormat('dd/MM').format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      setState(() => _dateRange = null);
                      widget.onDateFilter?.call(null);
                    },
                    icon: const Icon(Icons.close, size: 16),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (widget.onAdd != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(widget.addButtonLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Table ────────────────────────────────────────────────────────
          Expanded(child: widget.tableBuilder(_pageItems)),
          const SizedBox(height: 12),
          // ── Pagination ───────────────────────────────────────────────────
          _PaginationBar(
            currentPage: _page,
            totalPages: _totalPages,
            totalItems: widget.allItems.length,
            pageSize: _pageSize,
            onPageChanged: (p) => setState(() => _page = p),
            onPageSizeChanged: (s) => setState(() {
              _pageSize = s;
              _page = 0;
            }),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final void Function(int) onPageChanged;
  final void Function(int) onPageSizeChanged;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalItems == 0 ? 0 : currentPage * pageSize + 1;
    final end = ((currentPage + 1) * pageSize).clamp(0, totalItems);
    return Row(
      children: [
        Text(
          'Affichage de $start à $end sur $totalItems éléments',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const Spacer(),
        const Text('Éléments par page :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        DropdownButton<int>(
          value: pageSize,
          underline: const SizedBox(),
          isDense: true,
          items: [5, 10, 20, 50]
              .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
              .toList(),
          onChanged: (v) => v != null ? onPageSizeChanged(v) : null,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          style: IconButton.styleFrom(
            foregroundColor: currentPage > 0 ? AppColors.textPrimary : Colors.grey.shade300,
          ),
        ),
        ...List.generate(totalPages.clamp(0, 5), (i) {
          final page = i;
          final isActive = page == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onPageChanged(page),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${page + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          style: IconButton.styleFrom(
            foregroundColor: currentPage < totalPages - 1 ? AppColors.textPrimary : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA TABLE COMPONENTS - Custom Row/Expanded table (pixel-perfect alignment)
// ═══════════════════════════════════════════════════════════════════════════════

/// flex weight for each column
enum DataColumnSize { S, M, L, xL }

/// Configuration for a data column
class DataColumnConfig<T> {
  final String label;
  final DataColumnSize size;
  final String Function(T item) getValue;
  final TextAlign align;
  final String Function(T item)? badgeValue;
  final Color? badgeColor;
  final (String, String?) Function(T item)? showAvatar;
  final String Function(T item)? avatarSubtitle;

  const DataColumnConfig({
    required this.label,
    this.size = DataColumnSize.M,
    required this.getValue,
    this.align = TextAlign.start,
    this.badgeValue,
    this.badgeColor,
    this.showAvatar,
    this.avatarSubtitle,
  });

  int get flex {
    switch (size) {
      case DataColumnSize.S:  return 70;
      case DataColumnSize.M:  return 100;
      case DataColumnSize.L:  return 140;
      case DataColumnSize.xL: return 180;
    }
  }
}

/// Configuration for an action button
class DataActionConfig<T> {
  final IconData icon;
  final String tooltip;
  final Future<void> Function(T item) onPressed;
  final Color color;
  final Color backgroundColor;

  const DataActionConfig({
    required this.icon,
    this.tooltip = '',
    required this.onPressed,
    required this.color,
    required this.backgroundColor,
  });
}

/// Generic professional data table — pure Row/Expanded, no DataTable2
class DataTableWidget<T> extends StatelessWidget {
  final List<T> items;
  final List<DataColumnConfig<T>> columns;
  final List<DataActionConfig<T>> actions;
  final String emptyMessage;
  final IconData emptyIcon;

  const DataTableWidget({
    super.key,
    required this.items,
    required this.columns,
    required this.actions,
    required this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
  });

  // actions column fixed flex
  int get _actionFlex => (actions.length * 42).clamp(100, 160);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(message: emptyMessage, icon: emptyIcon);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E9ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(items.length, (i) => _buildRow(i, items[i])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 48,
      color: const Color(0xFFF0EEEE),
      child: Row(
        children: [
          ...columns.map((col) => Expanded(
            flex: col.flex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                col.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF41434B),
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )),
          Expanded(
            flex: _actionFlex,
            child: const Center(
              child: Text(
                'ACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF41434B),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index, T item) {
    return Material(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEF1)),
          ),
        ),
        child: Row(
          children: [
            ...columns.map((col) => Expanded(
              flex: col.flex,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildCell(item, col),
              ),
            )),
            Expanded(
              flex: _actionFlex,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Tooltip(
                    message: a.tooltip,
                    child: GestureDetector(
                      onTap: () => a.onPressed(item),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: a.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon, size: 17, color: a.color),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(T item, DataColumnConfig<T> col) {
    // Avatar cell
    if (col.showAvatar != null) {
      final (name, photoUrl) = col.showAvatar!(item);
      return Row(
        children: [
          EmployeeAvatar(photoUrl: photoUrl, name: name, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (col.avatarSubtitle != null)
                  Text(
                    col.avatarSubtitle!(item),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      );
    }

    // Badge cell
    if (col.badgeValue != null) {
      final badgeText = col.badgeValue!(item);
      if (badgeText.isEmpty || badgeText == '—') return const Text('—');
      return Align(
        alignment: col.align == TextAlign.center ? Alignment.center : Alignment.centerLeft,
        child: _Badge(text: badgeText, color: col.badgeColor ?? Colors.blueGrey),
      );
    }

    // Plain text cell
    final raw = col.getValue(item).trim();
    final text = raw.isEmpty ? '—' : raw;
    return Align(
      alignment: col.align == TextAlign.center
          ? Alignment.center
          : col.align == TextAlign.end || col.align == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: col.align == TextAlign.start ? FontWeight.w500 : FontWeight.normal,
          color: col.align == TextAlign.start
              ? const Color(0xFF292D32)
              : const Color(0xFF383C42),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Badge widget for status display
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Employee Data Table - 8 columns: Matricule, Nom complet, Email, Téléphone, Département, Poste, Type Contrat, Statut
/// Actions: Voir, Modifier, Supprimer
class EmployeeDataTable extends ConsumerWidget {
  final List<EmployeeModel> employees;
  final bool canEdit;
  final Future<void> Function(EmployeeModel)? onView;
  final Future<void> Function(EmployeeModel)? onEdit;
  final Future<void> Function(EmployeeModel)? onDelete;

  const EmployeeDataTable({
    super.key,
    required this.employees,
    this.canEdit = true,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = <DataColumnConfig<EmployeeModel>>[
      DataColumnConfig<EmployeeModel>(
        label: 'Matricule',
        size: DataColumnSize.S,
        getValue: (e) => e.matricule,
        align: TextAlign.center,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Nom complet',
        size: DataColumnSize.L,
        getValue: (e) => e.fullName,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Email',
        size: DataColumnSize.L,
        getValue: (e) => e.email,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Téléphone',
        size: DataColumnSize.M,
        getValue: (e) => e.telephone,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Département',
        size: DataColumnSize.M,
        getValue: (e) => e.departementNom,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Poste',
        size: DataColumnSize.M,
        getValue: (e) => e.poste,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Type Contrat',
        size: DataColumnSize.S,
        getValue: (e) => e.typeContrat,
        align: TextAlign.center,
        badgeValue: (e) => e.typeContrat,
        badgeColor: AppColors.primary,
      ),
      DataColumnConfig<EmployeeModel>(
        label: 'Statut',
        size: DataColumnSize.S,
        getValue: (e) => e.statut,
        align: TextAlign.center,
        badgeValue: (e) => e.statut,
        badgeColor: AppColors.success, // Default color, text shows actual status
      ),
    ];

    final actions = <DataActionConfig<EmployeeModel>>[
      if (onView != null)
        DataActionConfig(
          icon: Icons.visibility_outlined,
          onPressed: onView!,
          color: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.12),
        ),
      if (canEdit && onEdit != null)
        DataActionConfig(
          icon: Icons.edit_outlined,
          onPressed: onEdit!,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      if (canEdit && onDelete != null)
        DataActionConfig(
          icon: Icons.delete_outline,
          onPressed: onDelete!,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
        ),
    ];

    return DataTableWidget<EmployeeModel>(
      items: employees,
      columns: columns,
      actions: actions,
      emptyMessage: 'Aucun employé trouvé',
      emptyIcon: Icons.people_outline,
    );
  }
}

/// User Data Table - 6 columns: Nom complet, Email, Rôle, Employee ID, Statut, Dernière connexion, Créé le
/// Actions: Modifier, Activer/Désactiver, Supprimer
class UserDataTable extends ConsumerWidget {
  final List<UserModel> users;
  final Future<void> Function(UserModel)? onEdit;
  final Future<void> Function(UserModel)? onToggleStatus;
  final Future<void> Function(UserModel)? onDelete;

  const UserDataTable({
    super.key,
    required this.users,
    this.onEdit,
    this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = <DataColumnConfig<UserModel>>[
      DataColumnConfig<UserModel>(
        label: 'Nom complet',
        size: DataColumnSize.L,
        getValue: (u) => u.fullName,
      ),
      DataColumnConfig<UserModel>(
        label: 'Email',
        size: DataColumnSize.L,
        getValue: (u) => u.email,
      ),
      DataColumnConfig<UserModel>(
        label: 'Rôle',
        size: DataColumnSize.S,
        getValue: (u) => u.role,
        align: TextAlign.center,
        badgeValue: (u) => u.role,
        badgeColor: AppColors.primary,
      ),
      DataColumnConfig<UserModel>(
        label: 'Employee ID',
        size: DataColumnSize.S,
        getValue: (u) => u.employeeId ?? '—',
        align: TextAlign.center,
      ),
      DataColumnConfig<UserModel>(
        label: 'Statut',
        size: DataColumnSize.S,
        getValue: (u) => u.isActive ? 'Actif' : 'Inactif',
        align: TextAlign.center,
        badgeValue: (u) => u.isActive ? 'Actif' : 'Inactif',
        badgeColor: AppColors.success, // Default to success, will show "Inactif" text in green too
      ),
      DataColumnConfig<UserModel>(
        label: 'Dernière connexion',
        size: DataColumnSize.M,
        getValue: (u) {
          if (u.lastLogin == null) return 'Jamais';
          return '${u.lastLogin!.day.toString().padLeft(2, '0')}/${u.lastLogin!.month.toString().padLeft(2, '0')}/${u.lastLogin!.year} '
              '${u.lastLogin!.hour.toString().padLeft(2, '0')}:${u.lastLogin!.minute.toString().padLeft(2, '0')}';
        },
        align: TextAlign.center,
      ),
      DataColumnConfig<UserModel>(
        label: 'Créé le',
        size: DataColumnSize.S,
        getValue: (u) =>
            '${u.createdAt.day.toString().padLeft(2, '0')}/${u.createdAt.month.toString().padLeft(2, '0')}/${u.createdAt.year}',
        align: TextAlign.center,
      ),
    ];

    final actions = <DataActionConfig<UserModel>>[
      if (onEdit != null)
        DataActionConfig(
          icon: Icons.edit_outlined,
          onPressed: onEdit!,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      if (onToggleStatus != null)
        DataActionConfig(
          icon: Icons.toggle_on_outlined,
          onPressed: onToggleStatus!,
          color: AppColors.warning,
          backgroundColor: AppColors.warning.withValues(alpha: 0.12),
        ),
      if (onDelete != null)
        DataActionConfig(
          icon: Icons.delete_outline,
          onPressed: onDelete!,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
        ),
    ];

    return DataTableWidget<UserModel>(
      items: users,
      columns: columns,
      actions: actions,
      emptyMessage: 'Aucun utilisateur',
      emptyIcon: Icons.manage_accounts_outlined,
    );
  }
}

/// Bonus Data Table - 7 columns: Employé, Type, Montant, Date, Motif, Statut, Créé par
/// Actions: Voir, Modifier, Supprimer
class BonusDataTable extends ConsumerWidget {
  final List<BonusModel> bonuses;
  final Future<void> Function(BonusModel)? onView;
  final Future<void> Function(BonusModel)? onEdit;
  final Future<void> Function(BonusModel)? onDelete;

  const BonusDataTable({
    super.key,
    required this.bonuses,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = <DataColumnConfig<BonusModel>>[
      DataColumnConfig<BonusModel>(
        label: 'Employé',
        size: DataColumnSize.L,
        getValue: (b) => b.employeeNom,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Type',
        size: DataColumnSize.S,
        getValue: (b) => b.type,
        align: TextAlign.center,
        badgeValue: (b) => b.type,
        badgeColor: AppColors.primary,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Montant',
        size: DataColumnSize.M,
        getValue: (b) => '${NumberFormat('#,###').format(b.montant)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Date',
        size: DataColumnSize.S,
        getValue: (b) =>
            '${b.dateAttribution.day.toString().padLeft(2, '0')}/${b.dateAttribution.month.toString().padLeft(2, '0')}/${b.dateAttribution.year}',
        align: TextAlign.center,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Motif',
        size: DataColumnSize.L,
        getValue: (b) => b.motif,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Statut',
        size: DataColumnSize.S,
        getValue: (b) => b.statut,
        align: TextAlign.center,
        badgeValue: (b) => b.statut,
        badgeColor: AppColors.success,
      ),
      DataColumnConfig<BonusModel>(
        label: 'Créé par',
        size: DataColumnSize.S,
        getValue: (b) => b.createdBy,
      ),
    ];

    final actions = <DataActionConfig<BonusModel>>[
      if (onView != null)
        DataActionConfig(
          icon: Icons.visibility_outlined,
          onPressed: onView!,
          color: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.12),
        ),
      if (onEdit != null)
        DataActionConfig(
          icon: Icons.edit_outlined,
          onPressed: onEdit!,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      if (onDelete != null)
        DataActionConfig(
          icon: Icons.delete_outline,
          onPressed: onDelete!,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
        ),
    ];

    return DataTableWidget<BonusModel>(
      items: bonuses,
      columns: columns,
      actions: actions,
      emptyMessage: 'Aucune prime attribuée',
      emptyIcon: Icons.star_outline,
    );
  }
}

/// Contract Data Table - 8 columns: Employé, Type, Date début, Date fin, Durée (mois), Renouvellement, Pièces jointes, Statut
/// Actions: Voir, Modifier, Supprimer
class ContractDataTable extends ConsumerWidget {
  final List<ContractModel> contracts;
  final Future<void> Function(ContractModel)? onView;
  final Future<void> Function(ContractModel)? onEdit;
  final Future<void> Function(ContractModel)? onDelete;

  const ContractDataTable({
    super.key,
    required this.contracts,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = <DataColumnConfig<ContractModel>>[
      DataColumnConfig<ContractModel>(
        label: 'Employé',
        size: DataColumnSize.L,
        getValue: (c) => c.employeeNom,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Type',
        size: DataColumnSize.S,
        getValue: (c) => c.type,
        align: TextAlign.center,
        badgeValue: (c) => c.type,
        badgeColor: AppColors.primary,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Date début',
        size: DataColumnSize.S,
        getValue: (c) =>
            '${c.dateDebut.day.toString().padLeft(2, '0')}/${c.dateDebut.month.toString().padLeft(2, '0')}/${c.dateDebut.year}',
        align: TextAlign.center,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Date fin',
        size: DataColumnSize.S,
        getValue: (c) => c.dateFin != null
            ? '${c.dateFin!.day.toString().padLeft(2, '0')}/${c.dateFin!.month.toString().padLeft(2, '0')}/${c.dateFin!.year}'
            : '—',
        align: TextAlign.center,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Durée (mois)',
        size: DataColumnSize.S,
        getValue: (c) => c.dureeEnMois?.toString() ?? '—',
        align: TextAlign.center,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Renouvellement',
        size: DataColumnSize.S,
        getValue: (c) => c.renouvellement ? 'Oui' : 'Non',
        align: TextAlign.center,
        badgeValue: (c) => c.renouvellement ? 'Oui' : 'Non',
        badgeColor: AppColors.success,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Pièces jointes',
        size: DataColumnSize.S,
        getValue: (c) => '${c.piecesJointes.length}',
        align: TextAlign.center,
      ),
      DataColumnConfig<ContractModel>(
        label: 'Statut',
        size: DataColumnSize.S,
        getValue: (c) => c.statut,
        align: TextAlign.center,
        badgeValue: (c) => c.statut,
        badgeColor: AppColors.info,
      ),
    ];

    final actions = <DataActionConfig<ContractModel>>[
      if (onView != null)
        DataActionConfig(
          icon: Icons.visibility_outlined,
          onPressed: onView!,
          color: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.12),
        ),
      if (onEdit != null)
        DataActionConfig(
          icon: Icons.edit_outlined,
          onPressed: onEdit!,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      if (onDelete != null)
        DataActionConfig(
          icon: Icons.delete_outline,
          onPressed: onDelete!,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
        ),
    ];

    return DataTableWidget<ContractModel>(
      items: contracts,
      columns: columns,
      actions: actions,
      emptyMessage: 'Aucun contrat',
      emptyIcon: Icons.assignment_outlined,
    );
  }
}

/// Payroll Data Table - 10 columns: Employé, Mois/Année, Salaire base, Primes, Bonus, Heures sup, Retenues, Cotisations, Net à payer, Statut
/// Actions: Voir, Modifier, Supprimer
class PayrollDataTable extends ConsumerWidget {
  final List<PayrollModel> payrolls;
  final Future<void> Function(PayrollModel)? onView;
  final Future<void> Function(PayrollModel)? onEdit;
  final Future<void> Function(PayrollModel)? onDelete;

  const PayrollDataTable({
    super.key,
    required this.payrolls,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];

    final columns = <DataColumnConfig<PayrollModel>>[
      DataColumnConfig<PayrollModel>(
        label: 'Employé',
        size: DataColumnSize.L,
        getValue: (p) => p.employeeNom,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Mois/Année',
        size: DataColumnSize.M,
        getValue: (p) => '${months[p.mois]} ${p.annee}',
        align: TextAlign.center,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Salaire base',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.salaireBase)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Primes',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.primes)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Bonus',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.bonus)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Heures sup',
        size: DataColumnSize.M,
        getValue: (p) => '${p.heuresSupp}h @ ${NumberFormat('#,###').format(p.tauxHeureSupp)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Retenues',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.retenues)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Cotisations',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.cotisationsSociales)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Net à payer',
        size: DataColumnSize.M,
        getValue: (p) => '${NumberFormat('#,###').format(p.netAPayer)} FCFA',
        align: TextAlign.end,
      ),
      DataColumnConfig<PayrollModel>(
        label: 'Statut',
        size: DataColumnSize.S,
        getValue: (p) => p.statut,
        align: TextAlign.center,
        badgeValue: (p) => p.statut,
        badgeColor: AppColors.info,
      ),
    ];

    final actions = <DataActionConfig<PayrollModel>>[
      if (onView != null)
        DataActionConfig(
          icon: Icons.visibility_outlined,
          onPressed: onView!,
          color: AppColors.info,
          backgroundColor: AppColors.info.withValues(alpha: 0.12),
        ),
      if (onEdit != null)
        DataActionConfig(
          icon: Icons.edit_outlined,
          onPressed: onEdit!,
          color: AppColors.primary,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        ),
      if (onDelete != null)
        DataActionConfig(
          icon: Icons.delete_outline,
          onPressed: onDelete!,
          color: AppColors.error,
          backgroundColor: AppColors.error.withValues(alpha: 0.12),
        ),
    ];

    return DataTableWidget<PayrollModel>(
      items: payrolls,
      columns: columns,
      actions: actions,
      emptyMessage: 'Aucun bulletin de paie',
      emptyIcon: Icons.payments_outlined,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// REUSABLE TABLE COMPONENTS (Pro pattern)
// ═══════════════════════════════════════════════════════════════════════════════

/// Generic column definition for ProDataTable
class ProColumn<T> {
  final String label;
  final int flex;
  final Alignment alignment;
  final Widget Function(T item) cell;

  const ProColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.alignment = Alignment.centerLeft,
  });
}

/// Reusable data table with aligned columns (same flex in header/rows),
/// horizontal scroll on small screens, and pagination
class ProDataTable<T> extends StatefulWidget {
  final List<ProColumn<T>> columns;
  final List<T> items;
  final double minWidth;
  final String emptyMessage;

  const ProDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.minWidth = 900,
    this.emptyMessage = 'Aucun enregistrement',
  });

  @override
  State<ProDataTable<T>> createState() => _ProDataTableState<T>();
}

class _ProDataTableState<T> extends State<ProDataTable<T>> {
  int _page = 0;
  int _perPage = 10;

  int get _totalPages =>
      widget.items.isEmpty ? 1 : (widget.items.length / _perPage).ceil();

  @override
  Widget build(BuildContext context) {
    if (_page >= _totalPages) _page = _totalPages - 1;
    final total = widget.items.length;
    final start = total == 0 ? 0 : _page * _perPage;
    final end = (start + _perPage).clamp(0, total);
    final pageItems = widget.items.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Horizontal scroll zone for small screens
          LayoutBuilder(builder: (context, c) {
            final width = c.maxWidth < widget.minWidth
                ? widget.minWidth
                : c.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: [
                    _buildHeader(),
                    if (pageItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(widget.emptyMessage,
                            style: const TextStyle(color: AppColors.textSecondary)),
                      )
                    else
                      for (int i = 0; i < pageItems.length; i++)
                        _buildRow(pageItems[i], i),
                  ],
                ),
              ),
            );
          }),
          _buildFooter(total, start, end),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFFEDEDED),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          for (final col in widget.columns)
            Expanded(
              flex: col.flex,
              child: Align(
                alignment: col.alignment,
                child: Text(col.label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: AppColors.textPrimary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(T item, int index) {
    return Material(
      color: index.isEven ? Colors.white : const Color(0xFFF7F8FB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Row(
            children: [
              for (final col in widget.columns)
                Expanded(
                  flex: col.flex,
                  child: Align(alignment: col.alignment, child: col.cell(item)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(int total, int start, int end) {
    final info = total == 0
        ? 'Aucun élément'
        : 'Affichage de ${start + 1} à $end sur $total éléments';

    Widget pageBtn(IconData icon, bool enabled, VoidCallback onTap) => InkWell(
          onTap: enabled ? onTap : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFEDEDED), shape: BoxShape.circle),
            child: Icon(icon,
                size: 20,
                color: enabled ? AppColors.textPrimary : Colors.black26),
          ),
        );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          Text(info, style: const TextStyle(color: AppColors.textSecondary)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('Éléments par page :',
                style: TextStyle(color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD9DCE3)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _perPage,
                  items: const [5, 10, 20, 50]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _perPage = v!;
                    _page = 0;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 14),
            pageBtn(Icons.chevron_left, _page > 0,
                () => setState(() => _page--)),
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Text('${_page + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            pageBtn(Icons.chevron_right, _page < _totalPages - 1,
                () => setState(() => _page++)),
          ]),
        ],
      ),
    );
  }
}

/// Page header with icon, title, subtitle, and count
class ProPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;

  const ProPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.groups, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('$count enregistrement(s)',
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toolbar with search, date filter, and add button
class ProListToolbar extends StatelessWidget {
  final String searchHint;
  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterDate;
  final String addLabel;
  final VoidCallback onAdd;

  const ProListToolbar({
    super.key,
    required this.searchHint,
    required this.onSearch,
    required this.addLabel,
    required this.onAdd,
    this.onFilterDate,
  });

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      onChanged: onSearch,
      decoration: InputDecoration(
        hintText: searchHint,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9DCE3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );

    final filter = OutlinedButton.icon(
      onPressed: onFilterDate,
      icon: const Icon(Icons.calendar_month, size: 18),
      label: const Text('Filtrer par date'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        side: const BorderSide(color: Color(0xFFD9DCE3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final add = ElevatedButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add, size: 20),
      label: Text(addLabel),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(builder: (context, c) {
        if (c.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: filter),
                const SizedBox(width: 10),
                Expanded(child: add),
              ]),
            ],
          );
        }
        return Row(children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          filter,
          const SizedBox(width: 12),
          add,
        ]);
      }),
    );
  }
}

/// Colored status chip/badge
class ProStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const ProStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Round action button (view/edit/delete)
class ProActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  const ProActionIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// Employee cell with avatar (initials) + name + subtitle
class ProEmployeeCell extends StatelessWidget {
  final String name;
  final String subtitle;

  const ProEmployeeCell({super.key, required this.name, required this.subtitle});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary,
          child: Text(_initials,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(subtitle,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
