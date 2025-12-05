import 'package:az_incident_alert/utils/app_colors.dart';
import 'package:az_incident_alert/utils/extensions/context_ext.dart';
import 'package:az_incident_alert/utils/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appbarTitle,
    this.appbarActions = const <Widget>[],
    this.appbarBG,
    this.pinned,
    this.floating,
    this.snap,
    this.appbarBottom,
    this.bodyPadding,
    this.titleStyle,
  });

  final List<Widget> appbarActions;
  final Widget body;
  final String? appbarTitle;
  final TextStyle? titleStyle;
  final Color? appbarBG;
  final bool? pinned;
  final bool? floating;
  final bool? snap;
  final PreferredSize? appbarBottom;
  final EdgeInsets? bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbarTitle != null
          ? AppBar(
              title: Text(
                appbarTitle ?? 'Title',
                style: (titleStyle ?? textStyle22Bold).copyWith(
                  color: context.isDark ? Colors.white : AppColors.white,
                ),
              ),
              systemOverlayStyle:
                  Theme.of(context).appBarTheme.systemOverlayStyle,
              backgroundColor:
                  appbarBG ?? Theme.of(context).appBarTheme.backgroundColor,
              actions: appbarActions,
              bottom: appbarBottom,
            )
          : null,
      body: body,
    );
    /*return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: appbarBG ?? context.appColors.bgColorColor,
          title: Text(
            appbarTitle,
            style: titleStyle ?? textStyle22Bold,
          ),
          actions: appbarActions,
          pinned: pinned ?? false,
          floating: floating ?? false,
          snap: snap ?? false,
          bottom: appbarBottom,
        ),
        SliverToBoxAdapter(
            child: Padding(
          padding: bodyPadding ??
              const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: body,
        ))
      ],
    );*/
  }
}
