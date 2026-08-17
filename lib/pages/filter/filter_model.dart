import '/components/local_section_header_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'filter_widget.dart' show FilterWidget;
import 'package:flutter/material.dart';

class FilterModel extends FlutterFlowModel<FilterWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for LocalSectionHeader component.
  late LocalSectionHeaderModel localSectionHeaderModel1;
  // Model for LocalSectionHeader component.
  late LocalSectionHeaderModel localSectionHeaderModel2;
  // Model for LocalSectionHeader component.
  late LocalSectionHeaderModel localSectionHeaderModel3;
  // Model for LocalSectionHeader component.
  late LocalSectionHeaderModel localSectionHeaderModel4;

  @override
  void initState(BuildContext context) {
    localSectionHeaderModel1 =
        createModel(context, () => LocalSectionHeaderModel());
    localSectionHeaderModel2 =
        createModel(context, () => LocalSectionHeaderModel());
    localSectionHeaderModel3 =
        createModel(context, () => LocalSectionHeaderModel());
    localSectionHeaderModel4 =
        createModel(context, () => LocalSectionHeaderModel());
  }

  @override
  void dispose() {
    localSectionHeaderModel1.dispose();
    localSectionHeaderModel2.dispose();
    localSectionHeaderModel3.dispose();
    localSectionHeaderModel4.dispose();
  }
}
