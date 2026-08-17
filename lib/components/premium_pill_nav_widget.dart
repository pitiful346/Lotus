import '/components/premium_nav_item_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'premium_pill_nav_model.dart';
export 'premium_pill_nav_model.dart';

class PremiumPillNavWidget extends StatefulWidget {
  const PremiumPillNavWidget({
    super.key,
    bool? isCompact,
    String? dimension,
  })  : this.isCompact = isCompact ?? false,
        this.dimension = dimension ?? 'default';

  final bool isCompact;
  final String dimension;

  @override
  State<PremiumPillNavWidget> createState() => _PremiumPillNavWidgetState();
}

class _PremiumPillNavWidgetState extends State<PremiumPillNavWidget> {
  late PremiumPillNavModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PremiumPillNavModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10.0,
          sigmaY: 10.0,
        ),
        child: Container(
          width: valueOrDefault<double>(
            valueOrDefault<bool>(
              widget.isCompact,
              false,
            )
                ? 300.0
                : 390.0,
            390.0,
          ),
          height: 72.0,
          decoration: BoxDecoration(
            color: Color(0xFF0A0A0F),
            borderRadius: BorderRadius.circular(9999.0),
            shape: BoxShape.rectangle,
            border: Border.all(
              color: Color(0x1AFFFFFF),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                wrapWithModel(
                  model: _model.premiumNavItemModel1,
                  updateCallback: () => safeSetState(() {}),
                  child: PremiumNavItemWidget(
                    icon: Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 26.0,
                    ),
                    imgDesc: 'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
                    isActive: true,
                    isAvatar: false,
                  ),
                ),
                wrapWithModel(
                  model: _model.premiumNavItemModel2,
                  updateCallback: () => safeSetState(() {}),
                  child: PremiumNavItemWidget(
                    icon: Icon(
                      Icons.play_circle_outline_rounded,
                      color: Colors.white,
                      size: 26.0,
                    ),
                    imgDesc: 'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
                    isActive: false,
                    isAvatar: false,
                  ),
                ),
                wrapWithModel(
                  model: _model.premiumNavItemModel3,
                  updateCallback: () => safeSetState(() {}),
                  child: PremiumNavItemWidget(
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.white,
                      size: 26.0,
                    ),
                    imgDesc: 'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
                    isActive: false,
                    isAvatar: false,
                  ),
                ),
                wrapWithModel(
                  model: _model.premiumNavItemModel4,
                  updateCallback: () => safeSetState(() {}),
                  child: PremiumNavItemWidget(
                    icon: Icon(
                      Icons.search_rounded,
                      color: Colors.white,
                      size: 26.0,
                    ),
                    imgDesc: 'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
                    isActive: false,
                    isAvatar: false,
                  ),
                ),
                wrapWithModel(
                  model: _model.premiumNavItemModel5,
                  updateCallback: () => safeSetState(() {}),
                  child: PremiumNavItemWidget(
                    icon: Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 26.0,
                    ),
                    imgDesc:
                        'https://dimg.dreamflow.cloud/v1/image/User%20profile%20photo',
                    isActive: false,
                    isAvatar: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
