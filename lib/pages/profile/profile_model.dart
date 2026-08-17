import '/components/masonry_event_card_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'profile_widget.dart' show ProfileWidget;
import 'package:flutter/material.dart';

class ProfileModel extends FlutterFlowModel<ProfileWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for MasonryEventCard component.
  late MasonryEventCardModel masonryEventCardModel1;
  // Model for MasonryEventCard component.
  late MasonryEventCardModel masonryEventCardModel2;
  // Model for MasonryEventCard component.
  late MasonryEventCardModel masonryEventCardModel3;
  // Model for MasonryEventCard component.
  late MasonryEventCardModel masonryEventCardModel4;

  @override
  void initState(BuildContext context) {
    masonryEventCardModel1 =
        createModel(context, () => MasonryEventCardModel());
    masonryEventCardModel2 =
        createModel(context, () => MasonryEventCardModel());
    masonryEventCardModel3 =
        createModel(context, () => MasonryEventCardModel());
    masonryEventCardModel4 =
        createModel(context, () => MasonryEventCardModel());
  }

  @override
  void dispose() {
    masonryEventCardModel1.dispose();
    masonryEventCardModel2.dispose();
    masonryEventCardModel3.dispose();
    masonryEventCardModel4.dispose();
  }
}
