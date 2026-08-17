import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'contact_details_widget.dart' show ContactDetailsWidget;
import 'package:flutter/material.dart';

class ContactDetailsModel extends FlutterFlowModel<ContactDetailsWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for number widget.
  FocusNode? numberFocusNode;
  TextEditingController? numberTextController;
  String? Function(BuildContext, String?)? numberTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    emailFocusNode?.dispose();
    emailTextController?.dispose();

    numberFocusNode?.dispose();
    numberTextController?.dispose();
  }
}
