import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:notus/notus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zefyr/src/widgets/scope.dart';
import 'package:zefyr/src/widgets/theme.dart';
import 'package:zefyr/src/widgets/toolbar.dart';

class MathButton extends StatefulWidget {
  const MathButton({Key key}) : super(key: key);

  @override
  _MathButtonState createState() => _MathButtonState();
}

class _MathButtonState extends State<MathButton> {
  final TextEditingController _inputController = TextEditingController();
  Key _inputKey = UniqueKey();
  bool _formatError = false;

  bool get isEditing => _inputKey != null;

  @override
  Widget build(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);

    return toolbar.buildButton(
      context,
      ZefyrToolbarAction.math,
      onPressed: showOverlay,
    );
  }

  bool hasMath(NotusStyle style) => style.contains(NotusAttribute.math);

  String getMath([String defaultValue]) {
    final editor = ZefyrToolbar.of(context).editor;
    final attrs = editor.selectionStyle;
    if (hasMath(attrs)) {
      return attrs.value(NotusAttribute.math);
    }
    return defaultValue;
  }

  void showOverlay() {
    final toolbar = ZefyrToolbar.of(context);
    toolbar.showOverlay(buildOverlay).whenComplete(cancelEdit);
  }

  void closeOverlay() {
    final toolbar = ZefyrToolbar.of(context);
    toolbar.closeOverlay();
  }

  void edit() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      _inputKey = UniqueKey();
      _inputController.text = getMath('');
      _inputController.addListener(_handleInputChange);
      toolbar.markNeedsRebuild();
    });
  }

  void doneEdit() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      var error = false;
      if (_inputController.text.isNotEmpty) {
        try {
          // TODO: Change to LaTeX parser
          var uri = Uri.parse(_inputController.text);
          if ((uri.isScheme('https') || uri.isScheme('http')) && uri.host.isNotEmpty) {
            toolbar.editor.formatSelection(NotusAttribute.link.fromString(_inputController.text));
          } else {
            error = true;
          }
        } on FormatException {
          error = true;
        }
      }
      if (error) {
        _formatError = error;
        toolbar.markNeedsRebuild();
      } else {
        _inputKey = null;
        _inputController.text = '';
        _inputController.removeListener(_handleInputChange);
        toolbar.markNeedsRebuild();
        toolbar.editor.focus();
      }
    });
  }

  void cancelEdit() {
    if (mounted) {
      final editor = ZefyrToolbar.of(context).editor;
      setState(() {
        _inputKey = null;
        _inputController.text = '';
        _inputController.removeListener(_handleInputChange);
        editor.focus();
      });
    }
  }

  void unlink() {
    final editor = ZefyrToolbar.of(context).editor;
    editor.formatSelection(NotusAttribute.link.unset);
    closeOverlay();
  }

  void copyToClipboard() {
    var link = getMath();
    assert(link != null);
    Clipboard.setData(ClipboardData(text: link));
  }

  void openInBrowser() async {
    final editor = ZefyrToolbar.of(context).editor;
    var link = getMath();
    assert(link != null);
    if (await canLaunch(link)) {
      editor.hideKeyboard();
      await launch(link, forceWebView: true);
    }
  }

  void _handleInputChange() {
    final toolbar = ZefyrToolbar.of(context);
    setState(() {
      _formatError = false;
      toolbar.markNeedsRebuild();
    });
  }

  Widget buildOverlay(BuildContext context) {
    final toolbar = ZefyrToolbar.of(context);
    final style = toolbar.editor.selectionStyle;

    final clipboardEnabled = true;
    final body = _MathInput(
      key: _inputKey,
      controller: _inputController,
      formatError: _formatError,
    );
    final items = <Widget>[Expanded(child: body)];
    if (!isEditing) {
      final unlinkHandler = hasMath(style) ? unlink : null;
      final copyHandler = clipboardEnabled ? copyToClipboard : null;
      final openHandler = hasMath(style) ? openInBrowser : null;
      final buttons = <Widget>[
        toolbar.buildButton(context, ZefyrToolbarAction.unlink, onPressed: unlinkHandler),
        toolbar.buildButton(context, ZefyrToolbarAction.clipboardCopy, onPressed: copyHandler),
        toolbar.buildButton(
          context,
          ZefyrToolbarAction.openInBrowser,
          onPressed: openHandler,
        ),
      ];
      items.addAll(buttons);
    }
    final trailingPressed = isEditing ? doneEdit : closeOverlay;
    final trailingAction = isEditing ? ZefyrToolbarAction.confirm : ZefyrToolbarAction.close;

    return ZefyrToolbarScaffold(
      body: Row(children: items),
      trailing: toolbar.buildButton(
        context,
        trailingAction,
        onPressed: trailingPressed,
      ),
    );
  }
}

class _MathInput extends StatefulWidget {
  final TextEditingController controller;
  final bool formatError;

  const _MathInput({Key key, @required this.controller, this.formatError = false}) : super(key: key);

  @override
  _MathInputState createState() => _MathInputState();
}

class _MathInputState extends State<_MathInput> {
  final FocusNode _focusNode = FocusNode();

  ZefyrScope _editor;
  bool _didAutoFocus = false;

  final StreamController<String> _latexStream = StreamController<String>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAutoFocus) {
      FocusScope.of(context).requestFocus(_focusNode);
      _didAutoFocus = true;
    }

    final toolbar = ZefyrToolbar.of(context);

    if (_editor != toolbar.editor) {
      _editor?.toolbarFocusNode = null;
      _editor = toolbar.editor;
      _editor.toolbarFocusNode = _focusNode;
    }
  }

  @override
  void dispose() {
    _editor?.toolbarFocusNode = null;
    _focusNode.dispose();
    _editor = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolbarTheme = ZefyrTheme.of(context).toolbarTheme;
    final color = widget.formatError ? Colors.redAccent : toolbarTheme.iconColor;
    final style = theme.textTheme.subhead.copyWith(color: color);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        overflow: Overflow.visible,
        children: [
          TextField(
            style: style,
            keyboardType: TextInputType.url,
            focusNode: _focusNode,
            controller: widget.controller,
            onChanged: (latex) {
              _latexStream.add(latex);
            },
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'LaTeX',
              filled: true,
              fillColor: toolbarTheme.color,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(10.0),
            ),
          ),
          Positioned(
            bottom: 40,
            right: 0,
            left: 0,
            child: StreamBuilder<String>(
                stream: _latexStream.stream,
                builder: (context, snapshot) {
                  return Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 200,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(offset: Offset(-9, -9), color: Color.fromRGBO(255, 255, 255, 0.5), blurRadius: 16),
                          BoxShadow(offset: Offset(9, 9), color: Color.fromRGBO(163, 177, 198, 0.6), blurRadius: 16)
                        ],
                      ),
                      child: TeXView(
                          renderingEngine: TeXViewRenderingEngine.katex(),
                          children: [
                            TeXViewChild(
                                id: "child_1",
                                body: r"$$" + (snapshot.data ?? "") + r"$$",
                                decoration: TeXViewDecoration(
                                    bodyStyle: TeXViewStyle.fromCSS("color:grey;background-color:white")))
                          ],
                          loadingWidget: Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[CircularProgressIndicator(), Text("Updating... ")],
                            ),
                          ),
                          onTap: (childID) {
                            print("TeXView $childID is tapped.");
                          }),
                    ),
                  );
                }),
          ),
        ],
      ),
    );
  }
}

class _MathView extends StatelessWidget {
  const _MathView({Key key, @required this.value, this.onTap}) : super(key: key);
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toolbarTheme = ZefyrTheme.of(context).toolbarTheme;
    Widget widget = ClipRect(
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.all(10.0),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.subhead.copyWith(color: toolbarTheme.disabledIconColor),
            ),
          )
        ],
      ),
    );
    if (onTap != null) {
      widget = GestureDetector(
        child: widget,
        onTap: onTap,
      );
    }
    return widget;
  }
}
