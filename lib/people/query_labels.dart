import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';

/// Localized names of sort and filter options.
extension QueryLabels on AppLocalizations {
  String sortLabel(SortOption option) => translate(switch (option) {
        SortOption.name => 'sort_name',
        SortOption.age => 'sort_age',
        SortOption.birthday => 'sort_birthday',
        SortOption.remaining => 'sort_remaining',
        SortOption.group => 'sort_group',
      });

  String filterLabel(DateFilter filter) => translate(switch (filter) {
        DateFilter.all => 'filter_all',
        DateFilter.today => 'filter_today',
        DateFilter.thisWeek => 'filter_week',
        DateFilter.thisMonth => 'filter_month',
        DateFilter.custom => 'filter_custom',
      });
}
