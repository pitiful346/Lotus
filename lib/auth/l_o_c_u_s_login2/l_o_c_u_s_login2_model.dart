import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'l_o_c_u_s_login2_widget.dart' show LOCUSLogin2Widget;
import 'package:flutter/material.dart';

class LOCUSLogin2Model extends FlutterFlowModel<LOCUSLogin2Widget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for PinCode widget.
  TextEditingController? pinCodeController;
  FocusNode? pinCodeFocusNode;
  String? Function(BuildContext, String?)? pinCodeControllerValidator;

  @override
  void initState(BuildContext context) {
    pinCodeController = TextEditingController();
  }

  @override
  void dispose() {
    pinCodeFocusNode?.dispose();
    pinCodeController?.dispose();
  }
}
