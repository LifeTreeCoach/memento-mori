import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The population data source (citation, not translated).
const String wppCitation =
    'United Nations, Department of Economic and Social Affairs, Population '
    'Division (2024). World Population Prospects 2024. CC BY 3.0 IGO.';

/// The studies behind `lib/lifespan/lifestyle_model.dart` (citations, not
/// translated), in questionnaire order.
const List<String> lifestyleCitations = [
  'Jha P et al. 21st-century hazards of smoking and benefits of cessation in '
      'the United States. N Engl J Med 2013;368:341-350.',
  'Arem H et al. Leisure time physical activity and mortality: a detailed '
      'pooled analysis of the dose-response relationship. JAMA Intern Med '
      '2015;175:959-967.',
  'Wood AM et al. Risk thresholds for alcohol consumption: combined analysis '
      'of individual-participant data for 599 912 current drinkers in 83 '
      'prospective studies. Lancet 2018;391:1513-1523.',
  'Zhao J et al. Association between daily alcohol intake and risk of '
      'all-cause mortality. JAMA Netw Open 2023;6:e236185.',
  'Global BMI Mortality Collaboration. Body-mass index and all-cause '
      'mortality: individual-participant-data meta-analysis of 239 prospective '
      'studies in four continents. Lancet 2016;388:776-786.',
  'Holt-Lunstad J, Smith TB, Layton JB. Social relationships and mortality '
      'risk: a meta-analytic review. PLoS Med 2010;7:e1000316.',
  'Holt-Lunstad J et al. Loneliness and social isolation as risk factors for '
      'mortality: a meta-analytic review. Perspect Psychol Sci '
      '2015;10:227-237.',
];

/// The studies behind `lib/lifespan/condition_model.dart` (citations, not
/// translated), in questionnaire order.
const List<String> conditionCitations = [
  'Emerging Risk Factors Collaboration, Di Angelantonio E et al. Association '
      'of cardiometabolic multimorbidity with mortality. JAMA '
      '2015;314:52-60.',
  'Lind M et al. Glycemic control and excess mortality in type 1 diabetes. '
      'N Engl J Med 2014;371:1972-1982.',
  'Livingstone SJ et al. Estimated life expectancy in a Scottish cohort with '
      'type 1 diabetes, 2008-2010. JAMA 2015;313:37-44.',
  'Stolfo D et al. Persistent high burden of heart failure across the '
      'ejection fraction spectrum in a nationwide setting. J Am Heart Assoc '
      '2022;11:e026708.',
  'Mannino DM et al. Obstructive lung disease and low lung function in adults '
      'in the United States. Thorax 2003;58:388-393.',
  'Shavelle RM et al. Life expectancy and years of life lost in chronic '
      'obstructive pulmonary disease. Int J Chron Obstruct Pulmon Dis '
      '2009;4:137-148.',
  'Chronic Kidney Disease Prognosis Consortium, Matsushita K et al. '
      'Association of estimated glomerular filtration rate and albuminuria '
      'with all-cause and cardiovascular mortality in general population '
      'cohorts. Lancet 2010;375:2073-2081.',
];

/// Bottom sheet listing the data source and the studies.
Future<void> showLifespanSourcesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _SourcesSheet(),
  );
}

class _SourcesSheet extends StatelessWidget {
  const _SourcesSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium;
    final muted = body?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetTitle(l10n.translate('estimate_sources')),
          Flexible(
            child: ScrollThread(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionLabel.compact(
                      l10n.translate('estimate_sources_data'),
                    ),
                    Text(wppCitation, style: body),
                    const SizedBox(height: 6),
                    Text(
                      l10n.translate('estimate_sources_wpp_note'),
                      style: muted,
                    ),
                    const SizedBox(height: 24),
                    SectionLabel.compact(
                      l10n.translate('estimate_sources_studies'),
                    ),
                    ..._citations(lifestyleCitations, body),
                    const SizedBox(height: 14),
                    SectionLabel.compact(
                      l10n.translate('estimate_sources_conditions'),
                    ),
                    ..._citations(conditionCitations, body),
                    const SizedBox(height: 14),
                    Text(l10n.translate('estimate_sources_note'), style: muted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Iterable<Widget> _citations(
    List<String> citations,
    TextStyle? style,
  ) => citations.map(
    (citation) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(citation, style: style),
    ),
  );
}
