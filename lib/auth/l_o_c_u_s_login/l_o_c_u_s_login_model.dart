import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'l_o_c_u_s_login_widget.dart' show LOCUSLoginWidget;
import 'package:flutter/material.dart';

class LOCUSLoginModel extends FlutterFlowModel<LOCUSLoginWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for input_contacto widget.
  FocusNode? inputContactoFocusNode;
  TextEditingController? inputContactoTextController;
  String? Function(BuildContext, String?)? inputContactoTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    inputContactoFocusNode?.dispose();
    inputContactoTextController?.dispose();
  }
}
