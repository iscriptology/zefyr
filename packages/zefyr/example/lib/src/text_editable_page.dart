import 'package:example/src/annotable_edit.dart';
import 'package:example/src/full_page.dart';
import 'package:flutter/material.dart';

class TextEditableScreen extends StatefulWidget {
  TextEditableScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _TextEditableScreenState createState() => _TextEditableScreenState();
}

class _TextEditableScreenState extends State<TextEditableScreen> {
  final TextEditingController _singleTextFieldcontroller =
      TextEditingController(text: "une grosse pomme");
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ZefyrLogo(),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnnotatedEditableText(
                focusNode: _focusNode,
                style: TextStyle(),
                cursorColor: Colors.blue,
                backgroundCursorColor: Colors.white10,
                selectionColor: Colors.yellow,
                controller: _singleTextFieldcontroller,
                // maxLines: 1000,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
