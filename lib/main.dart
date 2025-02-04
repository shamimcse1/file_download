import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data' as typed_data; // Alias the import for clarity
import 'package:device_info_plus/device_info_plus.dart';

var status = "Waiting to download...";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () async {
              FileDownloader fileDownloader = FileDownloader();
              await fileDownloader.downloadFile(
                  'https://gbihr.org/images/docs/test.pdf');
            },
            child: const Text("Download File"),
          ),
          const SizedBox(height: 20),
          Expanded(child: Text(status)),
        ],
      ),
    );
  }
}

class FileDownloader {
  final Dio _dio = Dio();

  // Save file to the Download folder
  Future<void> downloadFile(String url, [String? fileName]) async {
    fileName ??= Uri.parse(url).pathSegments.last;

    // Path to the Download folder
    final directory = Directory('/storage/emulated/0/Download');
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    // Check if file already exists
    if (await file.exists()) {
      print("File already exists at $filePath");
      return; // Exit the method
    }


    // Request storage permissions
    final plugin = DeviceInfoPlugin();
    final android = await plugin.androidInfo;

    final storageStatus = android.version.sdkInt < 33
        ? await Permission.storage.request()
        : PermissionStatus.granted;

    if (storageStatus == PermissionStatus.granted) {
      try {
        if (Platform.isAndroid) {
          // Using Dio to download the file as bytes
          final response = await _dio.get(url, options: Options(responseType: ResponseType.bytes));
          final typed_data.Uint8List fileBytes = response.data as typed_data.Uint8List;

          // Writing the file to the Download folder
          final file = await _writeToDownloadFolder(fileBytes, fileName);

          print("Download complete! File saved to ${file.path}");
        }
      } catch (e) {
        print("Error downloading file: $e");
      }
    }
    if (storageStatus == PermissionStatus.denied) {
      print("denied");
    }
    if (storageStatus == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  // Write the downloaded bytes to the Download folder
  Future<File> _writeToDownloadFolder(
      typed_data.Uint8List fileBytes, String fileName) async {
    // Get the path to the external storage Download directory
    final directory = Directory('/storage/emulated/0/Download'); // Path to the Download folder

    // Create the file in the Download folder
    final file = File('${directory.path}/$fileName');

    // Write the bytes to the file
    await file.writeAsBytes(fileBytes);

    return file;
  }
}
