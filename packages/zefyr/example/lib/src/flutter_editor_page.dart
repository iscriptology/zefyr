import 'package:example/src/full_page.dart';
import 'package:flutter/material.dart';

class FlutterEditorScreen extends StatefulWidget {
  FlutterEditorScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _FlutterEditorScreenState createState() => _FlutterEditorScreenState();
}

class _FlutterEditorScreenState extends State<FlutterEditorScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final span = TextSpan(text: 'yolo', children: [
      TextSpan(text: "yata"),
      WidgetSpan(child: Container(color: Colors.cyanAccent)),
    ]);

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
              child: SelectableText.rich(
                span,
                maxLines: 1000,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
