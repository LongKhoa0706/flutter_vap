import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vap/vap_view_for_android.dart';
import 'package:flutter_vap/vap_view_for_ios.dart';

class VapView extends StatelessWidget {

  const VapView({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child = const SizedBox.shrink();
    if (Platform.isAndroid) {
      child = VapViewForAndroid();
    } else if (Platform.isIOS) {
      child = VapViewForIos();
    }

    return child;
  }
}
