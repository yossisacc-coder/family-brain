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
import '../../core/brain/voice_listen_patience.dart';
import '../settings/locale_controller.dart';
import '../../core/theme/appearance.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_section_header.dart';
import '../../core/widgets/brain_status_strip.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/quick_action_card.dart';
import '../../core/widgets/stat_card.dart';
import 'home_day_task.dart';
import '../../data/providers.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/task_item.dart';
import '../tasks/calendar_screen.dart';

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
  var _voiceSession = false;
  var _restartingListen = false;
  var _localeAttempt = 0;
  List<String?> _localeAttempts = const [null];
  String? _imagePath;
  Timer? _listenWatchdog;
  Timer? _silenceTimer;
  DateTime? _voiceStartedAt;
  BrainStatusKind? _brainStatus;
  String? _brainStatusMessage;

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
    _silenceTimer?.cancel();
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
            final palette = context.palette;

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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCard(
                        label: l10n.statEventsToday,
                        value: events.length,
                        icon: Icons.calendar_today_rounded,
                        color: palette.homeEvents,
                        background: palette.homeEventsSoft,
                        onTap: () => context.push('/tasks/events'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statPendingTasks,
                        value: open.length,
                        icon: Icons.check_circle_outline_rounded,
                        color: palette.homeTasks,
                        background: palette.homeTasksSoft,
                        onTap: () => context.push(
                          '/tasks/calendar',
                          extra: CalendarFocus.tasks,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statImportantReminders,
                        value: reminders.length,
                        icon: Icons.notifications_none_rounded,
                        color: palette.homeReminders,
                        background: palette.homeRemindersSoft,
                        onTap: () => context.push('/tasks/reminders'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      StatCard(
                        label: l10n.statFamilyConnected,
                        value: members.length,
                        icon: Icons.groups_rounded,
                        color: palette.homeFamily,
                        background: palette.homeFamilySoft,
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
                          iconColor: palette.homeEvents,
                          iconBackground: palette.homeEventsSoft,
                          onTap: () => context.push('/tasks/calendar'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.check_circle_outline_rounded,
                          label: l10n.quickAccessTasks,
                          iconColor: palette.homeTasks,
                          iconBackground: palette.homeTasksSoft,
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
                          iconColor: palette.homeFamily,
                          iconBackground: palette.homeFamilySoft,
                          onTap: () => context.push('/space/personal'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: QuickActionCard(
                          icon: Icons.groups_rounded,
                          label: l10n.quickAccessFamilySpace,
                          iconColor: palette.homeReminders,
                          iconBackground: palette.homeRemindersSoft,
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
                    statusKind: _brainStatus,
                    statusMessage: _brainStatusMessage,
                    onSubmit: () => _submitComposer(
                      context,
                      l10n,
                      members,
                      user,
                      open,
                    ),
                    onAdd: (buttonContext) => _showInputMenu(
                      buttonContext,
                      l10n,
                    ),
                    onMic: () => _toggleVoice(l10n),
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
                              color: palette.textMuted,
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
      color: context.palette.card,
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
    final palette = context.palette;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: palette.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: palette.primary, size: 20),
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
        _setBrainStatus(BrainStatusKind.error, l10n.imageFailed);
        return;
      }
      if (bytes > _maxImageBytes) {
        _setBrainStatus(BrainStatusKind.error, l10n.imageTooLarge);
        return;
      }
      setState(() => _imagePath = file.path);
    } catch (_) {
      if (mounted) _setBrainStatus(BrainStatusKind.error, l10n.imageFailed);
    }
  }

  void _setBrainStatus(BrainStatusKind? kind, [String? message]) {
    if (!mounted) return;
    setState(() {
      _brainStatus = kind;
      _brainStatusMessage = message;
    });
  }

  void _sttLog(String message) {
    debugPrint('family_brain_stt $message');
  }

  Future<void> _toggleVoice(AppLocalizations l10n) async {
    if (_listening || _voiceSession) {
      _voiceSession = false;
      await _stopVoice(l10n);
      return;
    }
    try {
      _voiceSession = true;
      _voiceStartedAt = DateTime.now();
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
            _setBrainStatus(BrainStatusKind.error, l10n.voiceDenied);
          } else if (msg.contains('no_match') || msg.contains('speech_timeout')) {
            if (_voiceSession && _withinListenBudget()) {
              _listenCurrent(l10n, continuation: true);
              return;
            }
            _voiceSession = false;
            _setBrainStatus(BrainStatusKind.error, l10n.voiceEmpty);
          } else {
            _voiceSession = false;
            _setBrainStatus(BrainStatusKind.error, l10n.voiceFailed);
          }
        },
        onStatus: (status) {
          _sttLog('status=$status');
          if (!mounted) return;
          if (status == 'notListening' || status == 'done') {
            if (_voiceSession &&
                _withinListenBudget() &&
                !_restartingListen) {
              _restartingListen = true;
              Future<void>.delayed(const Duration(milliseconds: 400), () async {
                _restartingListen = false;
                if (!mounted || !_voiceSession || !_withinListenBudget()) {
                  return;
                }
                if (_speech.isListening) return;
                await _listenCurrent(l10n, continuation: true);
              });
              return;
            }
            if (!_voiceSession) {
              setState(() => _listening = false);
            }
          }
        },
      );
      _sttLog('initialize ready=$ready');
      if (!ready) {
        _voiceSession = false;
        if (mounted) _setBrainStatus(BrainStatusKind.error, l10n.voiceUnavailable);
        return;
      }
      final appLang = ref.read(localeControllerProvider).languageCode;
      _localeAttempts = SpeechLocalePicker.listenAttempts(appLang);
      _localeAttempt = 0;
      _sttLog('appLang=$appLang attempts=$_localeAttempts');
      if (!mounted) return;
      _armSessionWatchdog(l10n);
      await _listenCurrent(l10n);
    } catch (error) {
      _sttLog('toggle failed $error');
      _voiceSession = false;
      if (mounted) {
        setState(() => _listening = false);
        _setBrainStatus(BrainStatusKind.error, l10n.voiceUnavailable);
      }
    }
  }

  bool _withinListenBudget() {
    final started = _voiceStartedAt;
    if (!_voiceSession || started == null) return false;
    return DateTime.now().difference(started) < VoiceListenPatience.listenFor;
  }

  void _armSessionWatchdog(AppLocalizations l10n) {
    _listenWatchdog?.cancel();
    _listenWatchdog = Timer(VoiceListenPatience.watchdog, () {
      _voiceSession = false;
      _stopVoice(l10n);
    });
  }

  void _armSilenceTimer(AppLocalizations l10n) {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(VoiceListenPatience.silenceTimeout, () {
      _voiceSession = false;
      _stopVoice(l10n);
    });
  }

  void _noteContinuedSpeech(AppLocalizations l10n) {
    if (!_voiceSession) return;
    _armSilenceTimer(l10n);
  }

  Future<void> _listenCurrent(
    AppLocalizations l10n, {
    bool continuation = false,
  }) async {
    if (!mounted || !_voiceSession) return;
    final localeId = _localeAttempts[_localeAttempt];
    setState(() {
      _listening = true;
      if (!continuation) _heardSpeech = false;
      _brainStatus = BrainStatusKind.listening;
      _brainStatusMessage = l10n.listening;
    });
    if (!continuation) {
      _armSilenceTimer(l10n);
    }
    _sttLog('listen locale=${localeId ?? 'device_default'} continuation=$continuation');
    if (_localeAttempt > 0 || continuation) {
      try {
        await _speech.cancel();
      } catch (_) {}
    }
    final options = SpeechListenOptions(
      listenFor: VoiceListenPatience.listenFor,
      pauseFor: VoiceListenPatience.pauseFor,
      partialResults: true,
      listenMode: ListenMode.dictation,
      cancelOnError: false,
      localeId: localeId,
    );
    try {
      await _speech.listen(
        listenOptions: options,
        onSoundLevelChange: (level) {
          if (!mounted || !_voiceSession) return;
          if (level >= VoiceListenPatience.speakingLevel) {
            _heardSpeech = true;
            _noteContinuedSpeech(l10n);
          }
        },
        onResult: (result) {
          if (!mounted) return;
          final text = result.recognizedWords.trim();
          if (text.isEmpty) return;
          _heardSpeech = true;
          _noteContinuedSpeech(l10n);
          _composer.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          // Do not stop on finalResult. Short pauses must not start a response.
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
        _voiceSession = false;
        setState(() => _listening = false);
        _setBrainStatus(BrainStatusKind.error, l10n.voiceUnavailable);
      }
    }
  }

  Future<void> _stopVoice([AppLocalizations? l10n]) async {
    _listenWatchdog?.cancel();
    _listenWatchdog = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _voiceSession = false;
    try {
      await _speech.stop();
    } catch (_) {}
    if (!mounted) return;
    final empty = !_heardSpeech && _composer.text.trim().isEmpty;
    setState(() => _listening = false);
    if (empty && l10n != null) {
      _setBrainStatus(BrainStatusKind.error, l10n.voiceEmpty);
    } else if (_brainStatus == BrainStatusKind.listening) {
      _setBrainStatus(null);
    }
  }

  Future<void> _submitComposer(
    BuildContext context,
    AppLocalizations l10n,
    List<AppUser> members,
    AppUser user,
    List<TaskItem> openItems,
  ) async {
    if (_sending) return;
    final text = _composer.text.trim();
    final imagePath = _imagePath;
    if (text.isEmpty && imagePath == null) {
      _setBrainStatus(BrainStatusKind.error, l10n.emptyBrainInput);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _sending = true;
      _brainStatus = BrainStatusKind.sending;
      _brainStatusMessage = l10n.brainProcessing;
    });
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
        items: openItems,
        currentUser: user,
        imagePath: imagePath,
        imageBase64: imageBase64,
        mimeType: 'image/jpeg',
        language: language,
      );
      if (!mounted) return;
      if (!result.isOk) {
        _setBrainStatus(BrainStatusKind.error, l10n.brainUnclear);
        return;
      }
      if (result.usedFallback && result.error == 'offline') {
        _setBrainStatus(BrainStatusKind.info, l10n.brainUsingOnDevice);
      } else if (result.usedFallback) {
        _setBrainStatus(BrainStatusKind.info, l10n.brainAiFailed);
      } else {
        _setBrainStatus(BrainStatusKind.success, l10n.brainStatusSuccess);
      }
      _composer.clear();
      setState(() => _imagePath = null);
      ref.read(pendingBrainDraftsProvider.notifier).state = result.drafts;
      if (!context.mounted) return;
      context.push('/brain/confirm');
    } catch (_) {
      if (mounted) {
        _setBrainStatus(BrainStatusKind.error, l10n.errorUnavailable);
      }
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
    required this.onMic,
    required this.onRemoveImage,
    this.sending = false,
    this.listening = false,
    this.imagePath,
    this.statusKind,
    this.statusMessage,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final void Function(BuildContext buttonContext) onAdd;
  final VoidCallback onMic;
  final VoidCallback onRemoveImage;
  final bool sending;
  final bool listening;
  final String? imagePath;
  final BrainStatusKind? statusKind;
  final String? statusMessage;

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

  bool get _canSend {
    return widget.controller.text.trim().isNotEmpty ||
        (widget.imagePath != null && widget.imagePath!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
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
        Material(
          color: palette.primarySoft,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsetsDirectional.fromSTEB(5, 5, 5, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: widget.listening
                    ? palette.primary
                    : palette.primary.withValues(alpha: 0.16),
                width: widget.listening ? 2 : 1,
              ),
            ),
            child: Row(
                children: [
                  Builder(
                    builder: (buttonContext) {
                      return _PillButton(
                        tooltip: l10n.attachInformation,
                        onPressed: widget.sending
                            ? null
                            : () => widget.onAdd(buttonContext),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      );
                    },
                  ),
                  if (widget.listening)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4),
                      child: _ListeningDot(
                        key: const Key('home-listening-indicator'),
                        tooltip: l10n.listening,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        key: const Key('home-ai-input'),
                        controller: widget.controller,
                        focusNode: _focus,
                        enabled: !widget.sending,
                        readOnly: false,
                        enableInteractiveSelection: true,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 3,
                        onTap: () => _focus.requestFocus(),
                        onSubmitted: widget.sending || !_canSend
                            ? null
                            : (_) => widget.onSubmit(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: palette.primaryDark,
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
                              ?.copyWith(color: palette.textMuted),
                          filled: false,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: widget.listening ? l10n.listening : l10n.voiceInput,
                    onPressed: widget.sending ? null : widget.onMic,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    icon: Icon(
                      widget.listening
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_rounded,
                      color: widget.listening
                          ? palette.primary
                          : palette.primary,
                    ),
                  ),
                  _ComposerSendButton(
                    enabled: _canSend && !widget.sending,
                    sending: widget.sending,
                    tooltip: l10n.sendToFamilyBrain,
                    onPressed: widget.onSubmit,
                  ),
                ],
              ),
            ),
          ),
        if (widget.statusKind != null &&
            widget.statusMessage != null &&
            widget.statusMessage!.isNotEmpty) ...[
          const SizedBox(height: 8),
          BrainStatusStrip(
            kind: widget.statusKind!,
            message: widget.statusMessage!,
          ),
        ],
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
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.primary,
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

class _ComposerSendButton extends StatelessWidget {
  const _ComposerSendButton({
    required this.enabled,
    required this.sending,
    required this.tooltip,
    required this.onPressed,
  });

  final bool enabled;
  final bool sending;
  final String tooltip;
  final VoidCallback onPressed;

  static const buttonKey = Key('home-ai-send');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? palette.primary : palette.border,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: buttonKey,
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: enabled ? Colors.white : palette.textMuted,
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ListeningDot extends StatelessWidget {
  const _ListeningDot({super.key, required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: palette.primary.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          size: 16,
          color: palette.primary,
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
    final palette = context.palette;
    return Material(
      color: palette.primarySoft,
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
                errorBuilder: (_, _, _) => SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.image_outlined, color: palette.primary),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
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
                color: [
                  palette.primarySoft,
                  palette.homeFamilySoft,
                  palette.homeEventsSoft,
                  palette.homeTasksSoft,
                  palette.homeRemindersSoft,
                ][(index - 1) % 5],
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
    final palette = context.palette;
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
                  color: palette.primary.withValues(alpha: 0.45),
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(Icons.add_rounded, color: palette.primary),
                ),
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: color ?? palette.primarySoft,
                foregroundColor: palette.primaryDark,
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

