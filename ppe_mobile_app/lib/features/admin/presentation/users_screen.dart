import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/labels.dart';
import '../data/admin_repository.dart';

/// Admin: manage roles, supervisor assignment and account status (access review, README Phase 3).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final query = (search: _search, role: _role);
    final users = ref.watch(usersProvider(query));
    return Scaffold(
      appBar: AppBar(
        title: Text(l.usersTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: TextField(
                onSubmitted: (v) => setState(() => _search = v.trim()),
                decoration: InputDecoration(hintText: l.searchUsers, prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(label: Text(l.all), selected: _role == null, onSelected: (_) => setState(() => _role = null)),
                ),
                for (final r in UserRole.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(label: Text(l.roleName(r)), selected: _role == r, onSelected: (_) => setState(() => _role = r)),
                  ),
              ]),
            ),
          ]),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(usersProvider(query).future),
        child: AsyncValueView(
          value: users,
          onRetry: () => ref.invalidate(usersProvider(query)),
          data: (items) => items.isEmpty
              ? ListView(children: [const SizedBox(height: 80), EmptyState(icon: Icons.person_search, message: l.noUsers)])
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final u = items[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(u.initials)),
                      title: Text(u.displayName),
                      subtitle: Text([u.employeeId, if (u.department.isNotEmpty) u.department, if (u.supervisorName != null) '${l.supervisor}: ${u.supervisorName}'].join(' · ')),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Pill(label: l.roleName(u.role), color: AppColors.brand, dense: true),
                        if (!u.isActive) Padding(padding: const EdgeInsets.only(top: 4), child: Pill(label: l.inactive, color: AppColors.neutral, dense: true)),
                      ]),
                      onTap: () => _edit(context, u, query),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, AppUser user, ({String search, UserRole? role}) query) async {
    final l = context.l10n;
    var role = user.role;
    var active = user.isActive;
    int? supervisorId = user.supervisorId;
    final candidates = await runWithProgress(
      context,
      () async => (await ref.read(adminRepositoryProvider).users()).where((u) => u.role.canApprove && u.id != user.id && u.isActive).toList(),
    );
    if (candidates == null || !context.mounted) return;
    if (supervisorId != null && !candidates.any((c) => c.id == supervisorId)) supervisorId = null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('${user.displayName} (${user.employeeId})'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (user.role == UserRole.supervisor && user.teamSize > 0) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.group_outlined),
                label: Text(l.transferTeam(user.teamSize)),
                onPressed: () {
                  Navigator.pop(context, false);
                  _transferTeam(this.context, user, candidates.where((c) => c.role == UserRole.supervisor).toList(), query);
                },
              ),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<UserRole>(
              initialValue: role,
              decoration: InputDecoration(labelText: l.role),
              items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(l.roleName(r)))],
              onChanged: (v) => setState(() => role = v ?? role),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: supervisorId,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.supervisor),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('—')),
                for (final c in candidates) DropdownMenuItem<int?>(value: c.id, child: Text('${c.displayName} (${c.employeeId})', overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => supervisorId = v),
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(l.activeUser), value: active, onChanged: (v) => setState(() => active = v)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.save)),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final result = await runWithProgress(
      context,
      () => ref.read(adminRepositoryProvider).updateUser(user.id, {
        'role': role.apiValue,
        'is_active': active,
        'supervisor': supervisorId,
      }),
    );
    if (result != null && context.mounted) {
      ref.invalidate(usersProvider(query));
      showSuccess(context, l.userUpdated);
    }
  }

  /// A supervisor moves or leaves: hand the whole team to another supervisor in one step.
  Future<void> _transferTeam(BuildContext context, AppUser from, List<AppUser> supervisors, ({String search, UserRole? role}) query) async {
    final l = context.l10n;
    if (supervisors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.noOtherSupervisor), backgroundColor: AppColors.danger));
      return;
    }
    final target = await showDialog<AppUser>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l.transferTeamTo(from.displayName)),
        children: [
          for (final s in supervisors)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Text([s.displayName, s.employeeId, if (s.department.isNotEmpty) s.department].join(' · ')),
            ),
        ],
      ),
    );
    if (target == null || !context.mounted) return;
    final moved = await runWithProgress(context, () => ref.read(adminRepositoryProvider).transferTeam(from.id, target.id));
    if (moved != null && context.mounted) {
      ref.invalidate(usersProvider(query));
      showSuccess(context, l.transferTeamDone(moved));
    }
  }
}
