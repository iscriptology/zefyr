// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:example/src/full_page.dart';
import 'package:flutter/material.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:zefyr/zefyr.dart';

import 'images.dart';

class BlockEditorScreen extends StatefulWidget {
  @override
  _BlockEditorScreenState createState() => _BlockEditorScreenState();
}

String get doc {
  // be carefull with the invisible no-width-space used for blocks
  final lines = [
    r'{"insert":"Zefyr\n"}',
    r'{"insert":"A\n"}',
    // r'{"insert":"---SDF"}',
    r'{"insert":"​","attributes":{"embed":{"type":"block","source":"Canard"}}}',
    r'{"insert":"\nB\n"}',
    // r'{"insert":"​","attributes":{"embed":{"type":"image","source":"asset://images/breeze.jpg"}}}',
    // r'{"insert":"C\n"}',
    // r'{"insert":"C\n"}',
    // r'{"insert":"","attributes":{"embed":{"type":"block","source":"canard"}}}',
    // r'{"insert":"D\n"}',
    // r'{"insert":"Heuristic Rules","attributes":{"a":"https://github.com/memspace/zefyr/blob/master/doc/heuristics.md"}}',
    r'{"insert":"\n"}'
  ].join(',');
  return '[${lines}]';
}

String get childDoc {
  // be carefull with the invisible no-width-space used for blocks
  final lines = [
    r'{"insert":"Zefyr\n"}',
    r'{"insert":"A\n"}',
    // r'{"insert":"---SDF"}',
    // r'{"insert":"​","attributes":{"embed":{"type":"block","source":"Canard"}}}',
    r'{"insert":"\nB\n"}',
    // r'{"insert":"​","attributes":{"embed":{"type":"image","source":"asset://images/breeze.jpg"}}}',
    // r'{"insert":"C\n"}',
    // r'{"insert":"C\n"}',
    // r'{"insert":"","attributes":{"embed":{"type":"block","source":"canard"}}}',
    // r'{"insert":"D\n"}',
    // r'{"insert":"Heuristic Rules","attributes":{"a":"https://github.com/memspace/zefyr/blob/master/doc/heuristics.md"}}',
    r'{"insert":"\n"}'
  ].join(',');
  return '[${lines}]';
}

Delta getDelta(doc) {
  return Delta.fromJson(json.decode(doc) as List);
}

class CustomSearchDelegate implements ZefyrSearchDelegate {
  final ZefyrController controller;
  final FocusNode focusNode;
  final TextEditingController _tcon = TextEditingController(text: 'tot');
  ZefyrController childController;
  FocusNode childFocusNode;

  CustomSearchDelegate(this.controller, this.focusNode) {
    childController =
        ZefyrController(NotusDocument.fromDelta(getDelta(childDoc)));
    childFocusNode = FocusNode();
  }

  @override
  Future<void> onBlock() async {
    this.controller.formatSelection(NotusAttribute.embed.block("canard"));
    print(NotusAttribute.embed.block("canard").toString());
    this.focusNode.requestFocus();
  }

  @override
  Future<Widget> buildBlock(String content) async {
    // final builder = DittorSliversBuilder();

    // final node = await nodeAwaiter(context, content);
    //
    // print('bloc up ');
    // return RichText(text: WidgetSpan(child: NodeEditor(node: node)));
    // return InkWell(
    //     onTap: () => print("YEEEAH MAN"),
    //     child: Container(height: 100, width: 100, color: Colors.brown));
    // return MaterialBudIC"));
    final editor = ZefyrField(
      height: 200.0,
      decoration: InputDecoration(labelText: 'Description'),
      controller: childController,
      focusNode: childFocusNode,
      autofocus: true,
      imageDelegate: CustomImageDelegate(),
      physics: ClampingScrollPhysics(),
    );
    final scaf = ZefyrScaffold(child: editor);
    // return TextField(controller: _tcon);
    return scaf;
    // return Text('## block: ${content} ##');

    final ret = GestureDetector(
        behavior: HitTestBehavior.opaque,
        // When the child is tapped, show a snackbar.
        onTapDown: (TapDownDetails tdd) {
          print('############## vazi');
        },
        onTap: () {
          print('############## Ee are here');
        },
        // child: Text('## block: ${content} ##'));
        child: TextField(controller: _tcon));
    return ret;

    // builder.addNode(node);
    // builder.addWidget(NodeEditor(node: node));
    // return CustomScrollView(slivers: builder.build());
  }

  @override
  Future<void> onMention() async {
    print("TODO");
  }

  // @override
  // Future<void> onMention() async {
  //   final Node node = await popUpSearch(context);
  //   if (node == null) {
  //     this.focusNode.requestFocus();
  //     return;
  //   }

  //   final text = describeNode(node);
  //   final link = 'dittor://e/${node.id}';
  //   final sel = this.controller.selection;
  //   final newSel = TextSelection.collapsed(offset: sel.start + text.length);

  //   this
  //       .controller
  //       .replaceText(sel.start, sel.end - sel.start, text, selection: newSel);
  //   this.controller.formatText(
  //       sel.start, text.length, NotusAttribute.link.fromString(link));

  //   this.focusNode.requestFocus();
  // }
}

enum _Options { darkTheme }

class _BlockEditorScreenState extends State<BlockEditorScreen> {
  final ZefyrController _controller =
      ZefyrController(NotusDocument.fromDelta(getDelta(doc)));
  final FocusNode _focusNode = FocusNode();
  bool _editing = true;
  StreamSubscription<NotusChange> _sub;
  bool _darkTheme = false;
  CustomSearchDelegate _searchDelegate;

  @override
  void initState() {
    super.initState();
    _sub = _controller.document.changes.listen((change) {
      print('${change.source}: ${change.change}');
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_searchDelegate == null) {
      _searchDelegate = CustomSearchDelegate(_controller, _focusNode);
    }
    final done = _editing
        ? IconButton(onPressed: _stopEditing, icon: Icon(Icons.save))
        : IconButton(onPressed: _startEditing, icon: Icon(Icons.edit));
    final result = Scaffold(
      resizeToAvoidBottomPadding: true,
      appBar: AppBar(
        title: Text('Blocks'),
        actions: [
          done,
          PopupMenuButton<_Options>(
            itemBuilder: buildPopupMenu,
            onSelected: handlePopupItemSelected,
          )
        ],
      ),
      body: ZefyrScaffold(
        child: ZefyrEditor(
          controller: _controller,
          focusNode: _focusNode,
          mode: _editing ? ZefyrMode.edit : ZefyrMode.select,
          imageDelegate: CustomImageDelegate(),
          keyboardAppearance: _darkTheme ? Brightness.dark : Brightness.light,
          searchDelegate: _searchDelegate,
        ),
      ),
    );
    if (_darkTheme) {
      return Theme(data: ThemeData.dark(), child: result);
    }
    return Theme(data: ThemeData(primarySwatch: Colors.cyan), child: result);
  }

  void handlePopupItemSelected(value) {
    if (!mounted) return;
    setState(() {
      if (value == _Options.darkTheme) {
        _darkTheme = !_darkTheme;
      }
    });
  }

  List<PopupMenuEntry<_Options>> buildPopupMenu(BuildContext context) {
    return [
      CheckedPopupMenuItem(
        value: _Options.darkTheme,
        child: Text("Dark theme"),
        checked: _darkTheme,
      ),
    ];
  }

  void _startEditing() {
    print("${doc.toString()}");
    // setState(() {
    //   _editing = true;
    // });
  }

  void _stopEditing() {
    print("${_controller.document.toJson()}");
    // setState(() {
    //   _editing = false;
    // });
  }
}
