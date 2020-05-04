import 'package:flutter/widgets.dart';

class AnnotatedEditableText extends EditableText {
  AnnotatedEditableText({
    Key key,
    FocusNode focusNode,
    TextEditingController controller,
    TextStyle style,
    Color cursorColor,
    Color backgroundCursorColor,
    Color selectionColor,
  }) : super(
          key: key,
          focusNode: focusNode,
          controller: controller,
          cursorColor: cursorColor,
          backgroundCursorColor: backgroundCursorColor,
          style: style,
          keyboardType: TextInputType.text,
          autocorrect: true,
          autofocus: true,
          selectionColor: selectionColor,
        );

  @override
  AnnotatedEditableTextState createState() => new AnnotatedEditableTextState();
}

class AnnotatedEditableTextState extends EditableTextState {
  @override
  AnnotatedEditableText get widget => super.widget;

  @override
  TextSpan buildTextSpan() {
    final String text = textEditingValue.text;
    // return TextSpan(style: widget.style, text: text);
    return TextSpan(
        style: widget.style,
        text: '',
        children: [TextSpan(style: widget.style, text: text)]);
  }
}
