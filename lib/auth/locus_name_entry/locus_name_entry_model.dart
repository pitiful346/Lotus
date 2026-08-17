import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'locus_name_entry_widget.dart' show LocusNameEntryWidget;
import 'package:flutter/material.dart';

class LocusNameEntryModel extends FlutterFlowModel<LocusNameEntryWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for input_firstName widget.
  FocusNode? inputFirstNameFocusNode;
  TextEditingController? inputFirstNameTextController;
  String? Function(BuildContext, String?)?
      inputFirstNameTextControllerValidator;
  // State field(s) for input_lastName widget.
  FocusNode? inputLastNameFocusNode;
  TextEditingController? inputLastNameTextController;
  String? Function(BuildContext, String?)? inputLastNameTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    inputFirstNameFocusNode?.dispose();
    inputFirstNameTextController?.dispose();

    inputLastNameFocusNode?.dispose();
    inputLastNameTextController?.dispose();
  }
}
