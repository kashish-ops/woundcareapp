import 'package:flutter/material.dart';
import 'services/s3_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Entry point for running application. This class defines the application, UI,
// and main logic for interacting with AWS S3.

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final S3Service s3Service = S3Service(
    accessKey: 'YOUR_ACCESS_KEY',
    secretKey: 'YOUR_SECRET_KEY',
    bucketName: 'YOUR_BUCKET_NAME',
    region: 'YOUR_BUCKET_REGION',
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Woundcare'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  final directory = await getApplicationDocumentsDirectory();
                  final filePath = 'Users/kashish/Documents/woundcare/test.txt';
                  final file = File(filePath);
                  await file.writeAsString('Hello, AWS S3!');
                  final fileUrl = await s3Service.uploadFile(filePath, 'example.txt');
                  print('File uploaded: $fileUrl');
                },
                child: Text('Upload File'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final directory = await getApplicationDocumentsDirectory();
                  final downloadPath = 'Users/kashish/Documents/woundcare/test.txt';
                  await s3Service.downloadFile('test.txt', downloadPath);
                  final file = File(downloadPath);
                  final contents = await file.readAsString();
                  print('File downloaded: $contents');
                },
                child: Text('Download File'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
