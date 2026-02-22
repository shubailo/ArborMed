import 'package:flutter/material.dart';

Widget getPlatformImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  throw UnsupportedError('Cannot create platform image without dart:html or dart:io');
}
