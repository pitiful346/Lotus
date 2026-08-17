import '/components/premium_nav_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'premium_pill_nav_widget.dart' show PremiumPillNavWidget;
import 'package:flutter/material.dart';

class PremiumPillNavModel extends FlutterFlowModel<PremiumPillNavWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for PremiumNavItem.
  late PremiumNavItemModel premiumNavItemModel1;
  // Model for PremiumNavItem.
  late PremiumNavItemModel premiumNavItemModel2;
  // Model for PremiumNavItem.
  late PremiumNavItemModel premiumNavItemModel3;
  // Model for PremiumNavItem.
  late PremiumNavItemModel premiumNavItemModel4;
  // Model for PremiumNavItem.
  late PremiumNavItemModel premiumNavItemModel5;

  @override
  void initState(BuildContext context) {
    premiumNavItemModel1 = createModel(context, () => PremiumNavItemModel());
    premiumNavItemModel2 = createModel(context, () => PremiumNavItemModel());
    premiumNavItemModel3 = createModel(context, () => PremiumNavItemModel());
    premiumNavItemModel4 = createModel(context, () => PremiumNavItemModel());
    premiumNavItemModel5 = createModel(context, () => PremiumNavItemModel());
  }

  @override
  void dispose() {
    premiumNavItemModel1.dispose();
    premiumNavItemModel2.dispose();
    premiumNavItemModel3.dispose();
    premiumNavItemModel4.dispose();
    premiumNavItemModel5.dispose();
  }
}
