import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/custom_code/event_mapping/firestore_favorite_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'masonry_event_card2_model.dart';
export 'masonry_event_card2_model.dart';

class MasonryEventCard2Widget extends StatefulWidget {
  const MasonryEventCard2Widget({
    super.key,
    required this.eventoRef,
  });

  final DocumentReference? eventoRef;

  @override
  State<MasonryEventCard2Widget> createState() =>
      _MasonryEventCard2WidgetState();
}

class _MasonryEventCard2WidgetState extends State<MasonryEventCard2Widget> {
  late MasonryEventCard2Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MasonryEventCard2Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          FlutterFlowTheme.of(context).designToken.spacing.sm,
          0.0,
          FlutterFlowTheme.of(context).designToken.spacing.sm,
          FlutterFlowTheme.of(context).designToken.spacing.lg),
      child: StreamBuilder<EventsRecord>(
        stream: EventsRecord.getDocument(widget.eventoRef!),
        builder: (context, snapshot) {
          // Customize what your widget looks like when it's loading.
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                width: 50.0,
                height: 50.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ),
            );
          }

          final containerEventsRecord = snapshot.data!;

          return Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: CachedNetworkImage(
                          fadeInDuration: Duration(milliseconds: 0),
                          fadeOutDuration: Duration(milliseconds: 0),
                          imageUrl: valueOrDefault<String>(
                            containerEventsRecord.image,
                            'https://www.sp.senac.br/documents/portlet_file_entry/51828463/dicas+para+um+evento+de+sucesso.webp/0453a6e1-5c79-ba90-d46d-009062d3ad4d',
                          ),
                          width: MediaQuery.sizeOf(context).width * 1.0,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional(1.0, -1.0),
                      child: Container(
                        alignment: AlignmentDirectional(1.0, -1.0),
                        child: Padding(
                          padding: EdgeInsets.all(FlutterFlowTheme.of(context)
                              .designToken
                              .spacing
                              .md),
                          child: InkWell(
                            splashColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () async {
                              final ref = widget.eventoRef;
                              if (ref == null || currentUserUid.isEmpty) return;
                              final isFav = (currentUserDocument?.favoritos.toList() ?? [])
                                  .contains(ref);
                              await FirestoreFavoriteRepository().setFavorite(
                                userId: currentUserUid,
                                eventId: ref.path,
                                isFavorite: !isFav,
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  FlutterFlowTheme.of(context)
                                      .designToken
                                      .radius
                                      .full),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8.0,
                                  sigmaY: 8.0,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(
                                      FlutterFlowTheme.of(context)
                                          .designToken
                                          .spacing
                                          .sm),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                          FlutterFlowTheme.of(context)
                                              .designToken
                                              .radius
                                              .full),
                                    ),
                                    child: Icon(
                                      Icons.favorite_rounded,
                                      color: FlutterFlowTheme.of(context).error,
                                      size: 18.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                        FlutterFlowTheme.of(context).designToken.spacing.sm,
                        0.0,
                        FlutterFlowTheme.of(context).designToken.spacing.sm,
                        0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          containerEventsRecord.name,
                          maxLines: 1,
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontStyle,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '8 nov',
                          style: FlutterFlowTheme.of(context)
                              .bodySmall
                              .override(
                                font: GoogleFonts.urbanist(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .fontStyle,
                                ),
                                color:
                                    FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .fontStyle,
                              ),
                        ),
                      ].divide(SizedBox(
                          height: FlutterFlowTheme.of(context)
                              .designToken
                              .spacing
                              .xs)),
                    ),
                  ),
                ),
              ].divide(SizedBox(
                  height: FlutterFlowTheme.of(context).designToken.spacing.sm)),
            ),
          );
        },
      ),
    );
  }
}
