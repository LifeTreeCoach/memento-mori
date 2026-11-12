import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The weight question: height and weight (turned into a BMI band right
/// away) or a self-chosen band. Only the band leaves this page.
class WeightPage extends StatefulWidget {
  const WeightPage({
    super.key,
    required this.answer,
    required this.isLast,
    required this.onAnswer,
    required this.onNext,
    required this.onSkipRest,
    this.subject = const SelfSubject(),
  });

  final BmiBand? answer;
  final LifespanEstimateSubject subject;
  final bool isLast;
  final ValueChanged<BmiBand?> onAnswer;
  final VoidCallback onNext;
  final VoidCallback onSkipRest;

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final TextEditingController _height = TextEditingController();
  final TextEditingController _weight = TextEditingController();

  /// A stored band opens the band list; otherwise height and weight.
  late bool _byBand = widget.answer != null;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  static double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _measurementsChanged(String _) {
    widget.onAnswer(bmiBandFor(_parse(_height.text), _parse(_weight.text)));
  }

  void _setMode(bool byBand) {
    if (byBand == _byBand) return;
    Haptics.selection();
    setState(() => _byBand = byBand);
    if (!byBand) _measurementsChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return QuestionFrame(
      factor: LifestyleFactor.bmi,
      isLast: widget.isLast,
      onNext: widget.onNext,
      onSkipRest: widget.onSkipRest,
      subject: widget.subject,
      body: [
        _ModeChoice(byBand: _byBand, onChanged: _setMode),
        const SizedBox(height: 20),
        if (_byBand)
          OptionList(
            factor: LifestyleFactor.bmi,
            answer: widget.answer,
            onAnswer: (option) => widget.onAnswer(option as BmiBand?),
            subject: widget.subject,
          )
        else
          _Measurements(
            height: _height,
            weight: _weight,
            band: widget.answer,
            onChanged: _measurementsChanged,
            subject: widget.subject,
          ),
      ],
    );
  }
}

class _ModeChoice extends StatelessWidget {
  const _ModeChoice({required this.byBand, required this.onChanged});

  final bool byBand;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          key: const ValueKey('lifespan_weight_measure'),
          label: Text(l10n.translate('estimate_weight_measure')),
          selected: !byBand,
          onSelected: (_) => onChanged(false),
        ),
        ChoiceChip(
          key: const ValueKey('lifespan_weight_band'),
          label: Text(l10n.translate('estimate_weight_band')),
          selected: byBand,
          onSelected: (_) => onChanged(true),
        ),
      ],
    );
  }
}

class _Measurements extends StatelessWidget {
  const _Measurements({
    required this.height,
    required this.weight,
    required this.band,
    required this.onChanged,
    required this.subject,
  });

  final LifespanEstimateSubject subject;
  final TextEditingController height;
  final TextEditingController weight;
  final BmiBand? band;
  final ValueChanged<String> onChanged;

  /// Room kept visible below a focused field (keyboard open, typing): the
  /// live "Your range" line and the privacy note beneath the fields.
  static const EdgeInsets _scrollPadding = EdgeInsets.fromLTRB(20, 20, 20, 140);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final band = this.band;
    final formatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('lifespan_height'),
                controller: height,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: formatters,
                scrollPadding: _scrollPadding,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.translate('estimate_height'),
                  suffixText: 'cm',
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('lifespan_weight'),
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: formatters,
                scrollPadding: _scrollPadding,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.translate('estimate_weight'),
                  suffixText: 'kg',
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (band != null)
          Text(
            subject.translate(
              l10n,
              'estimate_weight_result',
              replacements: {
                'band': l10n.translate(
                  LifestyleText.option(LifestyleFactor.bmi, band),
                ),
              },
            ),
            style: theme.textTheme.titleMedium,
          ),
        const SizedBox(height: 8),
        Text(
          subject.translate(l10n, 'estimate_weight_privacy'),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}
