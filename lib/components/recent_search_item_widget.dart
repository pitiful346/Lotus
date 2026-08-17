import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'recent_search_item_model.dart';
export 'recent_search_item_model.dart';

class RecentSearchItemWidget extends StatefulWidget {
  const RecentSearchItemWidget({
    super.key,
    this.query,
  });

  final String? query;

  @override
  State<RecentSearchItemWidget> createState() => _RecentSearchItemWidgetState();
}

class _RecentSearchItemWidgetState extends State<RecentSearchItemWidget> {
  late RecentSearchItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RecentSearchItemModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
            0.0,
            FlutterFlowTheme.of(context).designToken.spacing.md,
            0.0,
            FlutterFlowTheme.of(context).designToken.spacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              color: FlutterFlowTheme.of(context).hint,
              size: 20.0,
            ),
            Expanded(
              flex: 1,
              child: Text(
                valueOrDefault<String>(
                  widget.query,
                  'Techno festivals',
                ),
                maxLines: 1,
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.urbanist(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.north_west_rounded,
              color: FlutterFlowTheme.of(context).hint,
              size: 18.0,
            ),
          ].divide(SizedBox(
              width: FlutterFlowTheme.of(context).designToken.spacing.md)),
        ),
      ),
    );
  }
}
