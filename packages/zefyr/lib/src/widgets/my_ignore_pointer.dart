import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:zefyr/zefyr.dart';

/// CTAF: modified to skip hittest when we have a blockhittest.

class FakeHitTestEntry extends HitTestEntry {
  FakeHitTestEntry(target) : super(target);
}

/// A render object that is invisible during hit testing.
///
/// When [debugId] is true, this render object (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events, because its render
/// object returns false from [hitTest].
///
/// When [debugIdSemantics] is true, the subtree will be invisible to
/// the semantics layer (and thus e.g. accessibility tools). If
/// [debugIdSemantics] is null, it uses the value of [debugId].
///
/// See also:
///
///  * [RenderAbsorbPointer], which takes the pointer events but prevents any
///    nodes in the subtree from seeing them.
class RenderMyIgnorePointer extends RenderProxyBox {
  /// Creates a render object that is invisible to hit testing.
  ///
  /// The [debugId] argument must not be null. If [debugIdSemantics] is null,
  /// this render object will be ignored for semantics if [debugId] is true.
  RenderMyIgnorePointer({
    RenderBox child,
    int debugId,
  })  : _debugId = debugId,
        super(child) {
    assert(_debugId != null);
  }

  /// Whether this render object is ignored during hit testing.
  ///
  /// Regardless of whether this render object is ignored during hit testing, it
  /// will still consume space during layout and be visible during painting.
  int get debugId => _debugId;
  int _debugId;
  set debugId(int value) {
    assert(value != null);
    if (value == _debugId) return;
    _debugId = value;
  }

  // we do not manage the selection if the tap is on a zone handled by one of our sub block
  // if we have another editor embedded, it will receive the blockBoxHitTestEntry but should not pay attention (wrong debug id), it is on top.
  bool _areWeBlocked(result) {
    for (var entry in result.path) {
      // print('checking: ${entry}');
      if (entry is BlockBoxHitTestEntry) {
        print('are we blocked: ${debugId} scope: ${entry.scopeDebugId}');
        if (debugId == entry.scopeDebugId) return true;
      }
    }
    return false;
  }

  // disable hitTest for blocks (they can have an input with ev handling...)
  // we don't want to steal from them just because we have an overlay on top.
  @override
  bool hitTest(BoxHitTestResult result, {Offset position}) {
    // avoid recursion... cause we call hitTest in this function...
    // this is ugly but fine, we could hittest on the subtree that matters to us..
    if (result.path.isNotEmpty) {
      for (var entry in result.path) {
        if (entry is FakeHitTestEntry) {
          bool ret = super.hitTest(result, position: position);
          return ret;
        }
      }
    }

    // print('position: ${position} ${localToGlobal(position)}');
    final localResult = HitTestResult();
    localResult.add(FakeHitTestEntry(this));
    WidgetsBinding.instance.hitTest(localResult, localToGlobal(position));

    // check if find a subblock in the hit results.
    // if yes it means we wont use our gesturedetector for selection on this zone.
    if (_areWeBlocked(localResult) == true) {
      print("BLOCKING");
      // remove ourself and descendants from the list... we dont want to steal input from the layer below.
      return false;
    }

    // otherwise proceed as usual
    return super.hitTest(result, position: position);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('debugId', _debugId));
  }
}

/// A widget that is invisible during hit testing.
///
/// When [debugId] is true, this widget (and its subtree) is invisible
/// to hit testing. It still consumes space during layout and paints its child
/// as usual. It just cannot be the target of located events, because it returns
/// false from [RenderBox.hitTest].
///
/// When [debugIdSemantics] is true, the subtree will be invisible to
/// the semantics layer (and thus e.g. accessibility tools). If
/// [debugIdSemantics] is null, it uses the value of [debugId].
///
/// See also:
///
///  * [AbsorbPointer], which also prevents its children from receiving pointer
///    events but is itself visible to hit testing.
class MyIgnorePointer extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to hit testing.
  ///
  /// The [debugId] argument must not be null. If [debugIdSemantics] is null,
  /// this render object will be ignored for semantics if [debugId] is true.
  const MyIgnorePointer({
    Key key,
    int this.debugId,
    Widget child,
  }) : super(key: key, child: child);

  final int debugId;

  @override
  RenderMyIgnorePointer createRenderObject(BuildContext context) {
    return RenderMyIgnorePointer(debugId: debugId);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderMyIgnorePointer renderObject) {
    renderObject..debugId = debugId;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<int>('debugId', debugId));
  }
}
