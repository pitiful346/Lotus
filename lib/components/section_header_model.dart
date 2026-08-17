import '/components/button_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'section_header_widget.dart' show SectionHeaderWidget;
import 'package:flutter/material.dart';

class SectionHeaderModel extends FlutterFlowModel<SectionHeaderWidget> {
  ///  State fields for stateful widgets in this component.

  // Model for Button.
  late ButtonModel buttonModel;

  @override
  void initState(BuildContext context) {
    buttonModel = createModel(context, () => ButtonModel());
  }

  @override
  void dispose() {
    buttonModel.dispose();
  }
}
