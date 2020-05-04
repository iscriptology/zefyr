import 'package:flutter/material.dart';

abstract class ZefyrSearchDelegate {
  Future<void> onMention();
  Future<void> onBlock();
  Future<Widget> buildBlock(String content);
}
