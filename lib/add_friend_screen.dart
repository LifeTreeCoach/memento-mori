
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';
import 'package:memento_mori_life_in_weeks/friend_form/avatar_picker_tile.dart';
import 'package:memento_mori_life_in_weeks/friend_form/birthday_field.dart';
import 'package:memento_mori_life_in_weeks/friend_form/day_month_picker.dart';
import 'package:memento_mori_life_in_weeks/friend_form/friend_estimate_launcher.dart';
import 'package:memento_mori_life_in_weeks/friend_form/group_field.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_estimate_tile.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_slider.dart';
import 'package:memento_mori_life_in_weeks/friend_form/person_form_tour.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_lifespan_estimate.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_trigger.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

class AddFriendScreen extends StatefulWidget {
  final Friend? friend; // If provided, we're editing; otherwise, adding

  const AddFriendScreen({
    super.key,
    this.friend,
    this.estimateLauncher = openFriendEstimate,
    this.firstPerson = false,
  });

  /// Adding the very first person: the form then offers the estimate tip
  /// ([PersonFormTour]) once.
  final bool firstPerson;

  /// Opens the lifespan estimate about this person (replaced in tests).
  final FriendEstimateLauncher estimateLauncher;

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  static const _fieldGap = SizedBox(height: 16);
  static const _sectionGap = SizedBox(height: 28);

  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _customNotificationController = TextEditingController();
  final _groupController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final _nameFocus = FocusNode();
  final _scrollController = ScrollController();
  final TourAnchors _tourAnchors = TourAnchors();
  late final TourTrigger _tour =
      TourTrigger(contextOf: () => context, anchors: _tourAnchors);

  /// The on-screen keyboard was open at the last dependency change.
  bool _keyboardOpen = false;

  /// An estimate tip check is under way.
  bool _tipPending = false;

  DateTime? _selectedBirthDate;

  /// Birthday known by day and month only ([Friend.hasBirthYear] false);
  /// [_selectedBirthDate] then lies in [Friend.noYearStorageYear].
  bool _yearUnknown = false;
  int _customLifespan = LifeCalculator.defaultLifeExpectancyYears;

  /// The person's estimate answers; kept (unused) while the year is unknown.
  FriendLifespanEstimate? _lifespanEstimate;
  bool _isLoading = false;
  String? _avatarPath;

  /// Groups of all saved friends, offered as chips after the predefined ones.
  List<String> _existingGroups = FriendsService.getAllGroups();

  /// Whether a predefined group id in the field was replaced by its label.
  bool _groupLabelShown = false;

  /// Form values when the screen opened; differing values make it dirty.
  late final _FormValues _initialValues;

  bool get _isEditing => widget.friend != null;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.friend!.name;
      _notesController.text = widget.friend!.notes ?? '';
      _customNotificationController.text =
          widget.friend!.customNotificationMessage ?? '';
      _groupController.text = widget.friend!.groupName ?? '';
      _selectedBirthDate = widget.friend!.birthDate;
      _yearUnknown = !widget.friend!.hasBirthYear;
      _customLifespan = widget.friend!.customLifespan;
      _lifespanEstimate = widget.friend!.lifespanEstimate;
      _avatarPath = widget.friend!.avatarPath;
    }
    _initialValues = _currentValues();
    _loadExistingGroups();
    _nameFocus.addListener(_onNameFocusChanged);
  }

  Future<void> _loadExistingGroups() async {
    final groups = await FriendsService.loadAllGroups();
    if (mounted) setState(() => _existingGroups = groups);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trackKeyboard();
    if (_groupLabelShown) return;
    _groupLabelShown = true;
    _showGroupLabel();
  }

  /// The keyboard closing (also by system Back, focus kept) ends typing.
  void _trackKeyboard() {
    final open = MediaQuery.viewInsetsOf(context).bottom > 0;
    final closed = _keyboardOpen && !open;
    _keyboardOpen = open;
    if (closed) _offerEstimateTipIfDue();
  }

  /// Leaving the name field ends typing.
  void _onNameFocusChanged() {
    if (!_nameFocus.hasFocus) _offerEstimateTipIfDue();
  }

  bool get _estimateTipFits => PersonFormTour.fits(
        isEditing: _isEditing,
        firstPerson: widget.firstPerson,
        name: _nameController.text,
        birthDate: _selectedBirthDate,
        yearUnknown: _yearUnknown,
        hasEstimate: _lifespanEstimate != null,
      );

  /// Shows the estimate tip once, when the form is ready for it and
  /// nobody is typing; "Estimate now" opens the estimate.
  Future<void> _offerEstimateTipIfDue() async {
    if (_tipPending || !_estimateTipFits) return;
    _tipPending = true;
    try {
      await TourProgressStore.initialize();
      if (TourProgressStore.isSeen(PersonFormTour.id)) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_estimateTipFits || _keyboardOpen) return;
      await _revealEstimateAnchor();
      if (!mounted) return;
      final result = await _tour.startIfDue(
        PersonFormTour.id,
        PersonFormTour.steps,
        tabVisible: () => mounted,
        blocked: () => !_estimateTipFits || _keyboardOpen,
      );
      if (result.completed && mounted) await _openEstimate();
    } finally {
      _tipPending = false;
    }
  }

  /// The list builds lazily: an estimate tile scrolled far out of view is
  /// not built, so scroll back to the top, where it sits just below the
  /// birthday ([runTour] then centres it).
  Future<void> _revealEstimateAnchor() async {
    if (_tourAnchors.contains(PersonFormTour.estimateAnchor)) return;
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: Motion.of(context, Motion.medium),
      curve: Motion.standard,
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  /// A predefined group is stored as an id; the field shows its label.
  void _showGroupLabel() {
    final stored = _groupController.text;
    if (GroupNames.isPredefined(stored)) {
      _groupController.text = GroupNames.label(stored, _l10n);
    }
  }

  _FormValues _currentValues() => (
        name: _nameController.text.trim(),
        notes: _notesController.text.trim(),
        message: _customNotificationController.text.trim(),
        group: _groupName ?? '',
        birthDate: _selectedBirthDate,
        yearUnknown: _yearUnknown,
        lifespan: _customLifespan,
        estimate: _lifespanEstimate,
        avatarPath: _avatarPath,
      );

  bool get _isDirty => _currentValues() != _initialValues;

  /// Back with unsaved changes: asks before discarding them.
  Future<void> _onPopBlocked(bool didPop, Object? result) async {
    if (didPop) return;
    if (await _confirmDiscard() && mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    final l10n = _l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('form_discard_title')),
        content: Text(l10n.translate('form_discard_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('form_keep_editing')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('form_discard_confirm')),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _scrollController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _customNotificationController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  /// Closes the keyboard before a dialog or route, so focus does not come
  /// back to a text field (and reopen the keyboard) when it closes.
  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  /// Once the name error shows, it updates while typing (and disappears).
  void _revalidateNameIfShowingError() {
    final field = _nameFieldKey.currentState;
    if (field != null && field.hasError) field.validate();
  }

  Future<void> _selectBirthDate() async {
    _dismissKeyboard();
    if (_yearUnknown) {
      final picked =
          await showDayMonthPicker(context, initialDate: _selectedBirthDate);
      if (picked != null) setState(() => _selectedBirthDate = picked);
      return;
    }
    await _selectFullBirthDate();
  }

  /// Date picker with a year; true when a date was chosen.
  Future<bool> _selectFullBirthDate() async {
    _dismissKeyboard();
    final initialDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    final lastDate = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: DateTime(1900),
      lastDate: lastDate,
      helpText: _l10n.translate('form_birthday_picker_title'),
      confirmText: _l10n.translate('form_ok'),
      cancelText: _l10n.translate('people_cancel'),
    );

    if (selectedDate == null) return false;
    setState(() {
      _selectedBirthDate = selectedDate;
      _yearUnknown = false;
    });
    _offerEstimateTipIfDue();
    return true;
  }

  /// "Year unknown" on keeps day and month; off asks for the full date
  /// (starting from day and month), and stays on when that is cancelled.
  Future<void> _setYearUnknown(bool unknown) async {
    final date = _selectedBirthDate;
    if (unknown) {
      setState(() {
        _yearUnknown = true;
        if (date != null) {
          _selectedBirthDate =
              DateTime(Friend.noYearStorageYear, date.month, date.day);
        }
      });
      return;
    }
    if (date == null) {
      setState(() => _yearUnknown = false);
      return;
    }
    await _selectFullBirthDate();
  }

  /// Opens the estimate about this person (needs a name and a birth
  /// date); applying it sets the slider and keeps the answers.
  Future<void> _openEstimate() async {
    _dismissKeyboard();
    final name = _nameController.text.trim();
    final birthDate = _selectedBirthDate;
    if (name.isEmpty) {
      _formKey.currentState?.validate();
      _showMessage(_l10n.translate('form_estimate_name_first'));
      return;
    }
    if (birthDate == null) {
      _showMessage(_l10n.translate('form_birthday_required'));
      return;
    }
    final profile = await widget.estimateLauncher(
      context,
      FriendEstimateRequest(
        name: name,
        birthDate: birthDate,
        initial: FriendEstimateRequest.initialProfile(_lifespanEstimate),
        currentYears: _customLifespan,
      ),
    );
    final years = profile?.applied?.appliedYears;
    if (!mounted || profile == null || years == null) return;
    setState(() {
      _lifespanEstimate = FriendLifespanEstimate(profile);
      _customLifespan = years
          .clamp(LifespanSlider.minYears, LifespanSlider.maxYears)
          .toInt();
    });
  }

  /// "Forget the answers, keep the number".
  void _forgetEstimate() => setState(() => _lifespanEstimate = null);

  /// Picks a photo from [source] and copies it into the app's avatars folder.
  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );
      if (image == null) return;

      final savedPath = await _saveAvatar(image);
      if (!mounted) return;
      setState(() {
        _avatarPath = savedPath;
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _l10n.translate('form_photo_error', replacements: {'error': '$e'}),
      );
    }
  }

  Future<String> _saveAvatar(XFile image) async =>
      const AvatarStore().save(await image.readAsBytes());

  void _showAvatarOptions() {
    _dismissKeyboard();
    showModalBottomSheet(
      context: context,
      builder: (context) => AvatarOptionsSheet(
        hasPhoto: _avatarPath != null,
        onGallery: () => _pickAvatar(ImageSource.gallery),
        onCamera: () => _pickAvatar(ImageSource.camera),
        onRemove: () => setState(() {
          _avatarPath = null;
        }),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// The group to store: a predefined group's label becomes its id.
  String? get _groupName => GroupNames.normalize(_groupController.text);

  String? _trimmedOrNull(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  Friend _buildFriend(DateTime now) {
    if (_isEditing) {
      return widget.friend!.copyWith(
        name: _nameController.text.trim(),
        birthDate: _selectedBirthDate!,
        hasBirthYear: !_yearUnknown,
        avatarPath: _avatarPath,
        notes: _trimmedOrNull(_notesController),
        customNotificationMessage: _trimmedOrNull(
          _customNotificationController,
        ),
        groupName: _groupName,
        clearGroupName: _groupName == null,
        customLifespan: _customLifespan,
        lifespanEstimate: _lifespanEstimate,
        clearLifespanEstimate: _lifespanEstimate == null,
        lastUpdated: now,
      );
    }
    return Friend(
      id: now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      birthDate: _selectedBirthDate!,
      hasBirthYear: !_yearUnknown,
      avatarPath: _avatarPath,
      notes: _trimmedOrNull(_notesController),
      customNotificationMessage: _trimmedOrNull(_customNotificationController),
      groupName: _groupName,
      customLifespan: _customLifespan,
      lifespanEstimate: _lifespanEstimate,
      createdDate: now,
      lastUpdated: now,
    );
  }

  Future<void> _saveFriend() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBirthDate == null) {
      _showMessage(_l10n.translate('form_birthday_required'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final friend = _buildFriend(DateTime.now());
      if (_isEditing) {
        await FriendsService.updateFriend(friend);
      } else {
        await FriendsService.addFriend(friend);
      }
      if (mounted) {
        Navigator.of(context).pop(friend);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _l10n.translate('form_save_error', replacements: {'error': '$e'}),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_isDirty,
      onPopInvokedWithResult: _onPopBlocked,
      child: TourAnchorScope(
        anchors: _tourAnchors,
        child: _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _l10n.translate(_isEditing ? 'form_title_edit' : 'form_title_add'),
        ),
        actions: [_buildAppBarAction()],
      ),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}), // re-evaluates canPop
        child: ScrollThread(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              AvatarPickerTile(
                avatarPath: _avatarPath,
                onTap: _showAvatarOptions,
              ),
              _sectionGap,
              ..._buildPersonSection(),
              if (!_yearUnknown) ...[
                _sectionGap,
                ..._buildLifespanSection(),
              ],
              _sectionGap,
              SectionLabel.compact(_l10n.translate('form_section_group')),
              GroupField(
                controller: _groupController,
                existingGroups: _existingGroups,
                onGroupSelected: (group) => setState(() {
                  _groupController.text = group;
                }),
              ),
              _sectionGap,
              ..._buildNotesSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 24),
              _buildReminderInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarAction() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return TextButton(
      onPressed: _saveFriend,
      child: Text(_l10n.translate(_isEditing ? 'form_update' : 'form_save')),
    );
  }

  List<Widget> _buildPersonSection() {
    return [
      SectionLabel.compact(_l10n.translate('form_section_person')),
      TextFormField(
        key: _nameFieldKey,
        controller: _nameController,
        focusNode: _nameFocus,
        onChanged: (_) => _revalidateNameIfShowingError(),
        decoration: InputDecoration(
          labelText: _l10n.translate('form_name_label'),
          hintText: _l10n.translate('form_name_hint'),
          prefixIcon: const Icon(Icons.person_outline),
        ),
        textCapitalization: TextCapitalization.words,
        validator: (value) => value == null || value.trim().isEmpty
            ? _l10n.translate('form_name_required')
            : null,
      ),
      _fieldGap,
      BirthdayField(
        birthDate: _selectedBirthDate,
        yearUnknown: _yearUnknown,
        onTap: _selectBirthDate,
        onYearUnknownChanged: _setYearUnknown,
      ),
    ];
  }

  List<Widget> _buildLifespanSection() {
    final birthDate = _selectedBirthDate;
    return [
      SectionLabel.compact(_l10n.translate('form_section_lifespan')),
      LifespanSlider(
        lifespan: _customLifespan,
        currentAge: birthDate == null ? null : Friend.ageOn(birthDate, DateTime.now()),
        onChanged: (value) => setState(() {
          _customLifespan = value;
        }),
      ),
      const SizedBox(height: 8),
      TourAnchor(
        id: PersonFormTour.estimateAnchor,
        child: LifespanEstimateTile(
          estimate: _lifespanEstimate,
          lifespan: _customLifespan,
          onOpen: _openEstimate,
          onForget: _forgetEstimate,
        ),
      ),
    ];
  }

  List<Widget> _buildNotesSection() {
    return [
      SectionLabel.compact(_l10n.translate('form_section_notes')),
      TextFormField(
        controller: _notesController,
        decoration: InputDecoration(
          labelText: _l10n.translate('form_notes_label'),
          hintText: _l10n.translate('form_notes_hint'),
          prefixIcon: const Icon(Icons.notes_outlined),
        ),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
      _fieldGap,
      TextFormField(
        controller: _customNotificationController,
        decoration: InputDecoration(
          labelText: _l10n.translate('form_message_label'),
          hintText: _l10n.translate('form_message_hint'),
          helperText: _l10n.translate('form_message_helper'),
          prefixIcon: const Icon(Icons.chat_bubble_outline),
        ),
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
      ),
    ];
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isLoading ? null : _saveFriend,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(
          _l10n.translate(
            _isEditing ? 'form_save_changes' : 'form_save_person',
          ),
        ),
      ),
    );
  }

  Widget _buildReminderInfo() {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.translate('form_info_title'),
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _l10n.translate('form_info_body'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef _FormValues = ({
  String name,
  String notes,
  String message,
  String group,
  DateTime? birthDate,
  bool yearUnknown,
  int lifespan,
  FriendLifespanEstimate? estimate,
  String? avatarPath,
});
