// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:notus/notus.dart';
import 'package:zefyr/zefyr.dart';

import 'image.dart';

class ZefyrSubBlock extends StatelessWidget {
  final ZefyrSearchDelegate searchDelegate;
  ZefyrSubBlock({@required this.node, this.searchDelegate, Key key})
      : assert(node != null),
        super(key: key);

  final EmbedNode node;

  @override
  Widget build(BuildContext context) {
    final theme = ZefyrTheme.of(context);
    // final cont = Container(color: Colors.green, padding: EdgeInsets.all(8.0));
    EmbedAttribute attribute = node.style.get(NotusAttribute.embed);
    final source = attribute.value['source'] as String;

    Widget child;
    if (searchDelegate == null) {
      child = Container(color: Colors.green, padding: EdgeInsets.all(8.0));
    } else {
      final futureWidget = searchDelegate.buildBlock(source);
      child = FutureBuilder(
          builder: (context, AsyncSnapshot<Widget> widget) => widget.data,
          initialData:
              Container(color: Colors.blue, padding: EdgeInsets.all(8.0)),
          future: futureWidget);
    }
    return AnEditableImage(
      debugId: ZefyrScope.of(context).debugId,
      child: Padding(
          padding: theme.defaultLineTheme.padding,
          child: Container(
            child: child,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 4)),
            // padding: EdgeInsets.all(8.0)
          )),
      node: node,
    );
  }
}
