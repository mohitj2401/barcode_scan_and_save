import 'package:flutter/material.dart';
import 'package:qr_scanner/barcode_scanner_returning_image.dart';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Barcode Scanner ',
      home: BarcodeScannerReturningImage(),
    ),
  );
}
