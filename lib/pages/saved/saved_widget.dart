import '/custom_code/widgets/lotus_personalization_hub.dart';
import 'package:flutter/material.dart';

/// Generated route kept as a thin bridge to the Lotus-owned personalization UI.
class SavedWidget extends StatelessWidget {
  const SavedWidget({super.key});

  static String routeName = 'saved';
  static String routePath = '/saved';

  @override
  Widget build(BuildContext context) => const LotusPersonalizationHub();
}
