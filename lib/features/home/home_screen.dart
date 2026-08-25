import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:family_brain/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/brain/brain_activity.dart';
import '../../core/brain/family_brain_ai.dart';
import '../../core/brain/speech_locale.dart';
import '../settings/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/task_card.dart';
import '../../core/widgets/app_notice.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _composer = TextEditingController();
  final _speech = SpeechToText();
  final _picker = ImagePicker();
  var _sending = false;
  var _listening = false;
  var _heardSpeech = false;
  var _localeAttempt = 0;
  List<String?> _localeAttempts = const [null];
  String? _imagePath;
  Timer? _listenWatchdog;

  static const _maxImageBytes = 8 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _listenForShares();
  }

  Future<void> _listenForShares() async {
    const channel = MethodChannel('family_brain/share');
    try {
      final initial = await channel.invokeMethod<Map<dynamic, dynamic>>('getInitial');
      if (initial != null) _applyShare(initial);
      channel.setMethodCallHandler((call) async {
        if (call.method == 'onShare' && call.arguments is Map) {
          _applyShare(Map<dynamic, dynamic>.from(call.arguments as Map));
        }
        return null;
      });
    } catch (_) {}
  }

  void _applyShare(Map<dynamic, dynamic> payload) {
    final text = payload['text']?.toString();
    final path = payload['imagePath']?.toString();
    if (!mounted) return;
    setState(() {
      if (text != null && text.isNotEmpty) _composer.text = text;
      if (path != null && path.isNotEmpty) _imagePath = path;
    });
  }

  @override
  void dispose() {
    _listenWatchdog?.cancel();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final familyAsync = ref.watch(currentFamilyProvider);
    final tasksAsync = ref.watch(familyTasksProvider);
    final membersAsync = ref.watch(familyMembersProvider);
    final unread = ref.watch(unreadCountProvider);

    return userAsync.when(
      loading: () => LoadingView(label: l10n.loading),
      error: (_, _) => ErrorView(
        message: l10n.errorUnavailable,
        retryLabel: l10n.retry,
        onRetry: () => ref.invalidate(currentUserProvider),
      ),
      data: (user) {
        if (user == null) return LoadingView(label: l10n.loading);
        return tasksAsync.when(
          loading: () => LoadingView(label: l10n.loading),
          error: (_, _) => ErrorView(
            message: l10n.errorUnavailable,
            retryLabel: l10n.retry,
            onRetry: () => ref.invalidate(familyTasksProvider),
          ),
          data: (all) {
            final family = familyAsync.valueOrNull;
            final members = membersAsync.valueOrNull ?? const [];
            final tasks =
                all.where((task) => task.isVisibleTo(user.id)).toList();
            final open = tasks.where((task) => task.isOpen).toList();
            final reminders =
                open.where((task) => task.hasReminder).toList();
            final events = open.where((task) => task.dueDate != null).toList();
            final today = _todayItems(open);

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.xxl,
                ),
                children: [
                  AppHeader(
                    title: _greeting(l10n, user.name),
                    subtitle: l10n.appTitle,
                    unreadCount: unread,
                    onNotifications: () => context.push('/notifications'),
                    onSettings: () => context.go('/app/settings'),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.membersLabel,
                        value: members.length,
                        icon: Icons.groups_outlined,
                        color: AppColors.primary,
                        background: AppColors.primarySoft,
                        onTap: () => context.go('/app/family'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.tasks,
                        value: open.length,
                        icon: Icons.check_circle_outline,
                        color: AppColors.action,
                        background: AppColors.actionSoft,
                        onTap: () => context.go('/app/tasks'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.reminders,
                        value: reminders.length,
                        icon: Icons.alarm_outlined,
                        color: AppColors.success,
                        background: AppColors.successSoft,
                        onTap: () => context.push('/tasks/calendar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.events,
                        value: events.length,
                        icon: Icons.event_outlined,
                        color: AppColors.primaryDark,
                        background: AppColors.surface,
                        onTap: () => context.push('/tasks/calendar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  AppSectionHeader(title: l10n.quickAccess),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.calendar,
                          onTap: () => context.push('/tasks/calendar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.checklist_rounded,
                          label: l10n.tasks,
                          onTap: () => context.go('/app/tasks'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.person_outline,
                          label: l10n.mySpace,
                          onTap: () => context.push('/space/personal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.groups_outlined,
                          label: l10n.familySpace,
                          onTap: () => context.push('/space/family'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _ComposerCard(
                    controller: _composer,
                    sending: _sending,
                    listening: _listening,
                    imagePath: _imagePath,
                    onSubmit: () => _submitComposer(context, l10n, members),
                    onAskAi: () => context.push('/brain/ask'),
                    onAttach: () => _pickImage(l10n),
                    onMic: () => _toggleVoice(l10n),
                    onRemoveImage: () => setState(() => _imagePath = null),
                  ),
                  if (BrainActivityLog.entries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.section),
                    AppSectionHeader(title: l10n.recentBrain),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final entry in BrainActivityLog.entries.take(3)) ...[
                            Text(
                              entry.originalText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.summary,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.section),
                  AppSectionHeader(
                    title: l10n.todayActivity,
                    actionLabel: l10n.seeAllTasks,
                    onAction: () => context.go('/app/tasks'),
                  ),
                  if (today.isEmpty)
                    EmptyState(
                      title: l10n.noUpcoming,
                      message: l10n.emptyTasksMessage,
                      actionLabel: l10n.addFirstTask,
                      onAction: () => context.push('/tasks/new'),
                      icon: Icons.wb_sunny_outlined,
                    )
                  else
                    ...today.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TaskCard(
                          task: task,
                          members: members,
                          compact: true,
                          onTap: () => context.push('/tasks/${task.id}'),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  _FamilyMembersRow(
                    members: members,
                    currentUserId: user.id,
                    familyName: family?.name ?? l10n.currentFamily,
                    onViewFamily: () => context.go('/app/family'),
                    onAdd: () => context.go('/app/family'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<TaskItem> _todayItems(List<TaskItem> open) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matches = open.where((task) {
      final created = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );
      if (created == today) return true;
      if (task.dueDate != null) {
        final due = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        if (due == today || task.isOverdue(now)) return true;
      }
      if (task.reminderAt != null) {
        final reminder = DateTime(
          task.reminderAt!.year,
          task.reminderAt!.month,
          task.reminderAt!.day,
        );
        if (reminder == today) return true;
      }
      return task.isUrgent;
    }).toList();
    matches.sort((a, b) {
      final aTime = a.dueDate ?? a.reminderAt ?? a.createdAt;
      final bTime = b.dueDate ?? b.reminderAt ?? b.createdAt;
      return aTime.compareTo(bTime);
    });
    return matches.take(4).toList();
  }

  Future<void> _pickImage(AppLocalizations l10n) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.choosePhotoSource),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: Text(l10n.photoFromGallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: Text(l10n.photoFromCamera),
          ),
        ],
      ),
    );
    if (source == null || !mounted) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (file == null) return;
      final bytes = await file.length();
      if (!mounted) return;
      if (bytes <= 0) {
        AppNotice.show(context, l10n.imageFailed);
        return;
      }
      if (bytes > _maxImageBytes) {
        AppNotice.show(context, l10n.imageTooLarge);
        return;
      }
      setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) AppNotice.show(context, l10n.imageFailed);
    }
  }

  void _sttLog(String message) {
    debugPrint('family_brain_stt $message');
  }

  Future<void> _toggleVoice(AppLocalizations l10n) async {
    if (_listening) {
      await _stopVoice(l10n);
      return;
    }
    try {
      final ready = await _speech.initialize(
        debugLogging: true,
        onError: (error) {
          if (!mounted) return;
          final msg = error.errorMsg;
          _sttLog('error=$msg permanent=${error.permanent}');
          if (_localeAttempt < _localeAttempts.length - 1 &&
              SpeechLocalePicker.isLanguageError(msg)) {
            _localeAttempt += 1;
            _listenCurrent(l10n);
            return;
          }
          setState(() => _listening = false);
          if (msg.contains('permission')) {
            AppNotice.show(context, l10n.voiceDenied);
          } else if (msg.contains('no_match') || msg.contains('speech_timeout')) {
            AppNotice.show(context, l10n.voiceEmpty);
          } else {
            AppNotice.show(context, l10n.voiceFailed);
          }
        },
        onStatus: (status) {
          _sttLog('status=$status');
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            setState(() => _listening = false);
          }
        },
      );
      _sttLog('initialize ready=$ready');
      if (!ready) {
        if (mounted) AppNotice.show(context, l10n.voiceUnavailable);
        return;
      }
      final appLang = ref.read(localeControllerProvider).languageCode;
      _localeAttempts = SpeechLocalePicker.listenAttempts(appLang);
      _localeAttempt = 0;
      _sttLog('appLang=$appLang attempts=$_localeAttempts');
      if (!mounted) return;
      await _listenCurrent(l10n);
    } catch (error) {
      _sttLog('toggle failed $error');
      if (mounted) {
        setState(() => _listening = false);
        AppNotice.show(context, l10n.voiceUnavailable);
      }
    }
  }

  Future<void> _listenCurrent(AppLocalizations l10n) async {
    if (!mounted) return;
    final localeId = _localeAttempts[_localeAttempt];
    setState(() {
      _listening = true;
      _heardSpeech = false;
    });
    _listenWatchdog?.cancel();
    _listenWatchdog = Timer(const Duration(seconds: 8), () {
      _stopVoice(l10n);
    });
    _sttLog('listen locale=${localeId ?? 'device_default'}');
    if (_localeAttempt > 0) {
      try {
        await _speech.cancel();
      } catch (_) {}
    }
    final options = SpeechListenOptions(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      localeId: localeId,
    );
    try {
      await _speech.listen(
        listenOptions: options,
        onResult: (result) {
          if (!mounted) return;
          final text = result.recognizedWords.trim();
          if (text.isEmpty) return;
          _heardSpeech = true;
          _composer.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          if (result.finalResult) {
            _stopVoice(l10n);
          }
        },
      );
    } catch (error) {
      _sttLog('listen threw $error locale=${localeId ?? 'device_default'}');
      if (_localeAttempt < _localeAttempts.length - 1) {
        _localeAttempt += 1;
        await _listenCurrent(l10n);
        return;
      }
      if (mounted) {
        setState(() => _listening = false);
        AppNotice.show(context, l10n.voiceUnavailable);
      }
    }
  }

  Future<void> _stopVoice([AppLocalizations? l10n]) async {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
    try {
      await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    final empty = !_heardSpeech && _composer.text.trim().isEmpty;
    setState(() => _listening = false);
    if (empty && l10n != null) {
      AppNotice.show(context, l10n.voiceEmpty);
    }
  }

  Future<void> _submitComposer(
    BuildContext context,
    AppLocalizations l10n,
    List<AppUser> members,
  ) async {
    if (_sending) return;
    final text = _composer.text.trim();
    final imagePath = _imagePath;
    if (text.isEmpty && imagePath == null) {
      AppNotice.show(context, l10n.emptyBrainInput);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final language = Localizations.localeOf(context).languageCode;
    setState(() => _sending = true);
    try {
      String? imageBase64;
      if (imagePath != null && !kIsWeb) {
        try {
          imageBase64 = base64Encode(await File(imagePath).readAsBytes());
        } catch (_) {}
      }
      final result = await FamilyBrainAi.understand(
        text: text,
        now: DateTime.now(),
        members: members,
        imagePath: imagePath,
        imageBase64: imageBase64,
        mimeType: 'image/jpeg',
        language: language,
      );
      if (!mounted) return;
      if (result.usedFallback && result.error == 'offline') {
        AppNotice.show(context, l10n.brainUsingOnDevice);
      } else if (result.usedFallback) {
        AppNotice.show(context, l10n.brainAiFailed);
      }
      if (!result.isOk) {
        AppNotice.show(context, l10n.brainUnclear);
        return;
      }
      _composer.clear();
      setState(() => _imagePath = null);
      ref.read(pendingBrainDraftsProvider.notifier).state = result.drafts;
      context.push('/brain/confirm');
    } catch (_) {
      if (mounted) AppNotice.show(context, l10n.errorUnavailable);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _greeting(AppLocalizations l10n, String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning(name);
    if (hour < 17) return l10n.greetingAfternoon(name);
    return l10n.greetingEvening(name);
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({
    required this.controller,
    required this.onSubmit,
    required this.onAskAi,
    required this.onAttach,
    required this.onMic,
    required this.onRemoveImage,
    this.sending = false,
    this.listening = false,
    this.imagePath,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onAskAi;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final VoidCallback onRemoveImage;
  final bool sending;
  final bool listening;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.sendToFamilyBrain,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addToFamilyBrainHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (imagePath != null && !kIsWeb) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: AppRadii.card,
                  child: Image.file(
                    File(imagePath!),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                PositionedDirectional(
                  top: 4,
                  end: 4,
                  child: IconButton.filled(
                    tooltip: l10n.removePhoto,
                    onPressed: onRemoveImage,
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.send,
            onSubmitted: sending ? null : (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: l10n.tellFamilyBrain,
              filled: true,
              fillColor: AppColors.card,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              IconButton(
                tooltip: l10n.attachInformation,
                onPressed: sending ? null : onAttach,
                icon: const Icon(Icons.attach_file_outlined),
              ),
              IconButton(
                tooltip: listening ? l10n.listening : l10n.voiceInput,
                onPressed: sending ? null : onMic,
                icon: Icon(
                  listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
                  color: listening ? AppColors.urgent : null,
                ),
              ),
              IconButton(
                tooltip: l10n.askAi,
                onPressed: onAskAi,
                icon: const Icon(Icons.auto_awesome_outlined),
              ),
              const Spacer(),
              IconButton.filled(
                tooltip: l10n.sendToFamilyBrain,
                onPressed: sending ? null : onSubmit,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FamilyMembersRow extends StatelessWidget {
  const _FamilyMembersRow({
    required this.members,
    required this.currentUserId,
    required this.familyName,
    required this.onViewFamily,
    required this.onAdd,
  });

  final List<AppUser> members;
  final String currentUserId;
  final String familyName;
  final VoidCallback onViewFamily;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      onTap: onViewFamily,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.family,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      familyName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                l10n.viewFamily,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.action,
                    ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.action,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: members.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (index == members.length) {
                  return _MemberAvatar(
                    label: l10n.addFamilyMember,
                    onTap: onAdd,
                    isAdd: true,
                  );
                }
                final member = members[index];
                return _MemberAvatar(
                  label: member.id == currentUserId
                      ? l10n.you
                      : member.name.split(' ').first,
                  initial: member.name,
                  onTap: () => context.push('/family/members/${member.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    required this.onTap,
    this.initial,
    this.isAdd = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? initial;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final letter = (initial == null || initial!.isEmpty)
        ? '+'
        : initial!.characters.first.toUpperCase();
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.icon,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  isAdd ? AppColors.card : AppColors.primarySoft,
              foregroundColor: AppColors.primaryDark,
              child: isAdd
                  ? const Icon(Icons.add_rounded, color: AppColors.primary)
                  : Text(letter),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
