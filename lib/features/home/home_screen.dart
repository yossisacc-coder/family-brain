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

import '../../core/brain/family_brain_ai.dart';
import '../../core/brain/speech_locale.dart';
import '../settings/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/app_notice.dart';
import 'home_day_task.dart';
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
                  AppSpacing.sm,
                  AppSpacing.page,
                  8,
                ),
                children: [
                  AppHeader(
                    title: _greeting(l10n, user.name),
                    subtitle: l10n.greetingSubtitle,
                    unreadCount: unread,
                    onNotifications: () => context.push('/notifications'),
                    onSettings: () => context.go('/app/settings'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      StatCard(
                        label: l10n.statEventsToday,
                        value: events.length,
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.homeEvents,
                        background: AppColors.homeEventsSoft,
                        onTap: () => context.push('/tasks/events'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statPendingTasks,
                        value: open.length,
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.homeTasks,
                        background: AppColors.homeTasksSoft,
                        onTap: () => context.go('/app/tasks'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statImportantReminders,
                        value: reminders.length,
                        icon: Icons.notifications_none_rounded,
                        color: AppColors.homeReminders,
                        background: AppColors.homeRemindersSoft,
                        onTap: () => context.push('/tasks/reminders'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statFamilyConnected,
                        value: members.length,
                        icon: Icons.groups_rounded,
                        color: AppColors.homeFamily,
                        background: AppColors.homeFamilySoft,
                        onTap: () => context.go('/app/family'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppSectionHeader(title: l10n.quickAccess),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.calendar_today_rounded,
                          label: l10n.quickAccessCalendar,
                          iconColor: AppColors.homeEvents,
                          iconBackground: AppColors.homeEventsSoft,
                          onTap: () => context.push('/tasks/calendar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.check_circle_outline_rounded,
                          label: l10n.quickAccessTasks,
                          iconColor: AppColors.homeTasks,
                          iconBackground: AppColors.homeTasksSoft,
                          onTap: () => context.go('/app/tasks'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.person_rounded,
                          label: l10n.quickAccessMySpace,
                          iconColor: AppColors.homeFamily,
                          iconBackground: AppColors.homeFamilySoft,
                          onTap: () => context.push('/space/personal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.groups_rounded,
                          label: l10n.quickAccessFamilySpace,
                          iconColor: AppColors.homeReminders,
                          iconBackground: AppColors.homeRemindersSoft,
                          onTap: () => context.push('/space/family'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ComposerCard(
                    controller: _composer,
                    sending: _sending,
                    listening: _listening,
                    imagePath: _imagePath,
                    onSubmit: () => _submitComposer(context, l10n, members),
                    onAdd: (buttonContext) => _showInputMenu(
                      buttonContext,
                      l10n,
                    ),
                    onRemoveImage: () => setState(() => _imagePath = null),
                  ),
                  const SizedBox(height: 12),
                  AppSectionHeader(
                    title: l10n.todayActivity,
                    actionLabel: l10n.seeAllTasks,
                    onAction: () => context.go('/app/tasks'),
                  ),
                  if (today.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.noUpcoming,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    )
                  else
                    for (var i = 0; i < today.length; i++)
                      HomeDayTask(
                        task: today[i],
                        members: members,
                        isFirst: i == 0,
                        isLast: i == today.length - 1,
                        onTap: () => context.push('/tasks/${today[i].id}'),
                      ),
                  const SizedBox(height: AppSpacing.md),
                  _FamilyMembersRow(
                    members: members,
                    currentUserId: user.id,
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
    return matches.take(3).toList();
  }

  Future<void> _showInputMenu(
    BuildContext buttonContext,
    AppLocalizations l10n,
  ) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Navigator.of(buttonContext).overlay?.context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<_ComposerAction>(
      context: buttonContext,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(origin.dx, origin.dy, box.size.width, box.size.height),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.card,
      elevation: 8,
      items: [
        _menuItem(
          _ComposerAction.camera,
          Icons.photo_camera_outlined,
          l10n.photoFromCamera,
        ),
        _menuItem(
          _ComposerAction.gallery,
          Icons.photo_outlined,
          l10n.photoFromGallery,
        ),
        _menuItem(
          _ComposerAction.voice,
          _listening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
          _listening ? l10n.listening : l10n.voiceInput,
        ),
        _menuItem(
          _ComposerAction.askAi,
          Icons.auto_awesome_rounded,
          l10n.askAi,
        ),
      ],
    );
    if (!mounted || selected == null) return;
    switch (selected) {
      case _ComposerAction.camera:
        await _pickImage(l10n, ImageSource.camera);
      case _ComposerAction.gallery:
        await _pickImage(l10n, ImageSource.gallery);
      case _ComposerAction.voice:
        await _toggleVoice(l10n);
      case _ComposerAction.askAi:
        context.push('/brain/ask');
    }
  }

  PopupMenuItem<_ComposerAction> _menuItem(
    _ComposerAction value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(AppLocalizations l10n, ImageSource source) async {
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

enum _ComposerAction { camera, gallery, voice, askAi }

class _ComposerCard extends StatefulWidget {
  const _ComposerCard({
    required this.controller,
    required this.onSubmit,
    required this.onAdd,
    required this.onRemoveImage,
    this.sending = false,
    this.listening = false,
    this.imagePath,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final void Function(BuildContext buttonContext) onAdd;
  final VoidCallback onRemoveImage;
  final bool sending;
  final bool listening;
  final String? imagePath;

  @override
  State<_ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<_ComposerCard> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _focus.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _ComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;
    final showField = hasText || _focus.hasFocus || widget.listening;
    return Column(
      children: [
        if (widget.imagePath != null && !kIsWeb) ...[
          _AttachedPhotoChip(
            path: widget.imagePath!,
            label: l10n.photoAttached,
            onRemove: widget.onRemoveImage,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Row(
            children: [
              Builder(
                builder: (buttonContext) {
                  return _PillButton(
                    tooltip: l10n.attachInformation,
                    onPressed:
                        widget.sending ? null : () => widget.onAdd(buttonContext),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  );
                },
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: showField
                      ? TextField(
                          controller: widget.controller,
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 2,
                          textInputAction: TextInputAction.send,
                          onSubmitted:
                              widget.sending ? null : (_) => widget.onSubmit(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.listening
                                ? l10n.listening
                                : l10n.tellFamilyBrain,
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                            filled: false,
                            fillColor: Colors.transparent,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _focus.requestFocus(),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.sendToFamilyBrain,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  l10n.addToFamilyBrainHint,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              _PillButton(
                tooltip: l10n.sendToFamilyBrain,
                onPressed: widget.sending ? null : widget.onSubmit,
                child: widget.sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onPressed,
    required this.child,
    required this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _AttachedPhotoChip extends StatelessWidget {
  const _AttachedPhotoChip({
    required this.path,
    required this.label,
    required this.onRemove,
  });

  final String path;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primarySoft,
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.image_outlined, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).removePhoto,
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyMembersRow extends StatelessWidget {
  const _FamilyMembersRow({
    required this.members,
    required this.currentUserId,
    required this.onViewFamily,
    required this.onAdd,
  });

  final List<AppUser> members;
  final String currentUserId;
  final VoidCallback onViewFamily;
  final VoidCallback onAdd;

  static const _avatarColors = [
    Color(0xFFE8D5F2),
    Color(0xFFD6E4FF),
    Color(0xFFFFE0D1),
    Color(0xFFD4F0E2),
    Color(0xFFFFE8B8),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onViewFamily,
          child: AppSectionHeader(title: l10n.family),
        ),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MemberAvatar(
                  label: l10n.addFamilyMember,
                  onTap: onAdd,
                  isAdd: true,
                );
              }
              final member = members[index - 1];
              return _MemberAvatar(
                label: member.id == currentUserId
                    ? l10n.you
                    : member.name.split(' ').first,
                initial: member.name,
                color: _avatarColors[(index - 1) % _avatarColors.length],
                onTap: () => context.push('/family/members/${member.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    required this.onTap,
    this.initial,
    this.color,
    this.isAdd = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? initial;
  final Color? color;
  final bool isAdd;

  @override
  Widget build(BuildContext context) {
    final letter = (initial == null || initial!.isEmpty)
        ? '+'
        : initial!.characters.first.toUpperCase();
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            if (isAdd)
              CustomPaint(
                painter: _DashedCirclePainter(
                  color: AppColors.primary.withValues(alpha: 0.45),
                ),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add_rounded, color: AppColors.primary),
                ),
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: color ?? AppColors.primarySoft,
                foregroundColor: AppColors.primaryDark,
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dash = 4.0;
    const gap = 3.0;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final path = Path()..addOval(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

