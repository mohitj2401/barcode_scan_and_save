import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_scanner/scanner_error_widget.dart';
import 'package:widgets_to_image/widgets_to_image.dart';

class BarcodeScannerReturningImage extends StatefulWidget {
  const BarcodeScannerReturningImage({super.key});

  @override
  State<BarcodeScannerReturningImage> createState() =>
      _BarcodeScannerReturningImageState();
}

class _BarcodeScannerReturningImageState
    extends State<BarcodeScannerReturningImage> {
  WidgetsToImageController widgetsToImageController =
      WidgetsToImageController();
  final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    returnImage: false,
  );
  Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcode Scanner ')),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: Text(
                  "Scan & Save",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 100,
                child: ColoredBox(
                  color: Colors.grey,
                  child: MobileScanner(
                    controller: controller,
                    errorBuilder: (context, error, child) {
                      return ScannerErrorWidget(error: error);
                    },
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: StreamBuilder<BarcodeCapture>(
                  stream: controller.barcodes,
                  builder: (context, snapshot) {
                    final barcode = snapshot.data;

                    if (barcode == null) {
                      return Text(
                        'Your scanned barcode will appear here!',
                      );
                    } else {
                      return ListTile(
                        title: WidgetsToImage(
                          controller: widgetsToImageController,
                          child: Text(
                              "${barcode.barcodes.first.displayValue!}_${DateTime.now().toString().split(" ")[0]}"),
                        ),
                        trailing: ElevatedButton(
                            onPressed: () async {
                              final bytes =
                                  await widgetsToImageController.capture();
                              saveImageFileToDownloads(bytes!,
                                  "${barcode.barcodes.first.displayValue!}_${DateTime.now().toString().split(" ")[0]}");
                              setState(() {
                                this.bytes = bytes;
                              });
                            },
                            child: Text("Save")),
                      );
                    }
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              const Text(
                "Images",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 10,
              ),
              if (bytes != null) buildImage(bytes!),
              SizedBox(
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> requestPermissions() async {
    if (await Permission.storage.isGranted ||
        await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // For Android 11+, request manage storage permission
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    print("Permission denied");
    return false;
  }

  Future<void> saveImageFileToDownloads(
      Uint8List imageFile, String filename) async {
    try {
      // Request storage permissions
      bool isGranted = await requestPermissions();
      if (!isGranted) return;

      // Get the Downloads directory path
      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        print("Downloads folder not found");
        return;
      }
      // Create the destination file path
      String fileName = "${filename}.png";
      String newFilePath = "${downloadsDir.path}/$fileName";

      // Write to Downloads folder
      final newFile = File(newFilePath);
      await newFile.writeAsBytes(imageFile);

      // Copy the file to the Downloads folder
      // await imageFile.copy(newFilePath);

      var snackBar = SnackBar(
          content: Text("File saved to Downloads folder: $newFilePath"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      print("Error saving file: $e");
    }
  }

  Widget buildImage(Uint8List bytes) => Image.memory(bytes);
  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}
