import '/custom_code/widgets/lotus_event_search.dart';
import 'package:flutter/material.dart';

/// Generated route kept as a thin bridge to the Lotus-owned search UI.
class SearchWidget extends StatelessWidget {
  const SearchWidget({super.key});

  static String routeName = 'search';
  static String routePath = '/search';

  @override
  Widget build(BuildContext context) => const LotusEventSearch();
}
