import 'package:flutter_aws_s3_client/flutter_aws_s3_client.dart';
// import 'package:amplify_storage_s3/amplify_storage_s3.dart';

class S3Service {
  final String accessKey;
  final String secretKey;
  final String bucketName;
  final String region;

  late AwsS3Client s3Client;

  S3Service({
    required this.accessKey,
    required this.secretKey,
    required this.bucketName,
    required this.region,
  }) {
    s3Client = AwsS3Client(
      region: region,
      accessKey: accessKey,
      secretKey: secretKey,
      bucketId: bucketName,
    );
  }

  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      final response = await s3Client.uploadFile(
        filePath,
        bucketName,
        fileName,
        S3AccessControl.private,
      );
      return response.url;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  Future<void> downloadFile(String fileName, String downloadPath) async {
    try {
      await s3Client.downloadFile(bucketName, fileName, downloadPath);
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }
}
