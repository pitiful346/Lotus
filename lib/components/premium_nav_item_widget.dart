import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'premium_nav_item_model.dart';
export 'premium_nav_item_model.dart';

class PremiumNavItemWidget extends StatefulWidget {
  const PremiumNavItemWidget({
    super.key,
    this.icon,
    String? imgDesc,
    bool? isActive,
    bool? isAvatar,
  })  : this.imgDesc =
            imgDesc ?? 'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
        this.isActive = isActive ?? true,
        this.isAvatar = isAvatar ?? false;

  final Widget? icon;
  final String imgDesc;
  final bool isActive;
  final bool isAvatar;

  @override
  State<PremiumNavItemWidget> createState() => _PremiumNavItemWidgetState();
}

class _PremiumNavItemWidgetState extends State<PremiumNavItemWidget> {
  late PremiumNavItemModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PremiumNavItemModel());

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
      decoration: BoxDecoration(
        color: valueOrDefault<Color>(
          valueOrDefault<bool>(
            widget.isActive,
            true,
          )
              ? Color(0x26FFFFFF)
              : Colors.transparent,
          Color(0x26FFFFFF),
        ),
        borderRadius: BorderRadius.circular(9999.0),
        shape: BoxShape.rectangle,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(24.0, 12.0, 24.0, 12.0),
        child: Container(
          child: Container(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Stack(
              alignment: AlignmentDirectional(-1.0, -1.0),
              children: [
                if (valueOrDefault<bool>(
                  valueOrDefault<bool>(
                    widget.isAvatar,
                    false,
                  )
                      ? false
                      : true,
                  true,
                ))
                  widget.icon!,
                if (valueOrDefault<bool>(
                  widget.isAvatar,
                  false,
                ))
                  Container(
                    width: 26.0,
                    height: 26.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13.0),
                      child: CachedNetworkImage(
                        fadeInDuration: Duration(milliseconds: 0),
                        fadeOutDuration: Duration(milliseconds: 0),
                        imageUrl: valueOrDefault<String>(
                          widget.imgDesc,
                          'https://dimg.dreamflow.cloud/v1/image/Img%20Desc',
                        ),
                        width: 26.0,
                        height: 26.0,
                        fit: BoxFit.cover,
                        alignment: Alignment(0.0, 0.0),
                      ),
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
