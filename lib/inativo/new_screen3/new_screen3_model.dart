import '/components/form_label_widget.dart';
import '/components/upload_placeholder_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'new_screen3_widget.dart' show NewScreen3Widget;
import 'package:flutter/material.dart';

class NewScreen3Model extends FlutterFlowModel<NewScreen3Widget> {
  ///  State fields for stateful widgets in this page.

  // Model for FormLabel component.
  late FormLabelModel formLabelModel1;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // Model for FormLabel component.
  late FormLabelModel formLabelModel2;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // Model for FormLabel component.
  late FormLabelModel formLabelModel3;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // Model for FormLabel component.
  late FormLabelModel formLabelModel4;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // Model for FormLabel component.
  late FormLabelModel formLabelModel5;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;
  // Model for FormLabel component.
  late FormLabelModel formLabelModel6;
  // Model for UploadPlaceholder component.
  late UploadPlaceholderModel uploadPlaceholderModel;

  @override
  void initState(BuildContext context) {
    formLabelModel1 = createModel(context, () => FormLabelModel());
    formLabelModel2 = createModel(context, () => FormLabelModel());
    formLabelModel3 = createModel(context, () => FormLabelModel());
    formLabelModel4 = createModel(context, () => FormLabelModel());
    formLabelModel5 = createModel(context, () => FormLabelModel());
    formLabelModel6 = createModel(context, () => FormLabelModel());
    uploadPlaceholderModel =
        createModel(context, () => UploadPlaceholderModel());
  }

  @override
  void dispose() {
    formLabelModel1.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    formLabelModel2.dispose();
    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    formLabelModel3.dispose();
    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    formLabelModel4.dispose();
    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    formLabelModel5.dispose();
    textFieldFocusNode5?.dispose();
    textController5?.dispose();

    formLabelModel6.dispose();
    uploadPlaceholderModel.dispose();
  }
}
