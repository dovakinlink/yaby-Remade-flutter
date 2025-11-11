import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 文件上传服务
class FileUploadService {
  final Dio dio;

  FileUploadService({required this.dio});

  /// 上传文件到服务器
  /// 
  /// [file] - 要上传的文件
  /// [onProgress] - 上传进度回调（0.0 - 1.0）
  /// 
  /// 返回：
  /// ```dart
  /// {
  ///   'fileId': 123,
  ///   'url': '/uploads/2025/11/11/xxxxx.jpg',
  ///   'filename': 'image.jpg',
  ///   'size': 102400
  /// }
  /// ```
  Future<Map<String, dynamic>> uploadFile(
    File file, {
    Function(double)? onProgress,
  }) async {
    try {
      final filename = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
      });

      debugPrint('开始上传文件: $filename, 大小: ${await file.length()} 字节');

      final response = await dio.post(
        '/api/v1/files/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
            debugPrint('上传进度: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        debugPrint('文件上传成功: fileId=${data['fileId']}, url=${data['url']}');
        return data;
      } else {
        throw Exception(response.data['message'] ?? '上传失败');
      }
    } on DioException catch (e) {
      debugPrint('文件上传失败: ${e.message}');
      if (e.response != null) {
        final message = e.response?.data['message'] ?? '上传失败';
        throw Exception(message);
      }
      throw Exception('网络连接失败，请检查网络');
    } catch (e) {
      debugPrint('文件上传异常: $e');
      throw Exception('文件上传失败: $e');
    }
  }

  /// 批量上传文件
  Future<List<Map<String, dynamic>>> uploadFiles(
    List<File> files, {
    Function(int index, double progress)? onProgress,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final result = await uploadFile(
        file,
        onProgress: (progress) {
          onProgress?.call(i, progress);
        },
      );
      results.add(result);
    }
    
    return results;
  }

  /// 获取图片尺寸
  Future<Map<String, int>> getImageDimensions(File imageFile) async {
    try {
      // 使用 dart:ui 解析图片尺寸
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      return {
        'width': image.width,
        'height': image.height,
      };
    } catch (e) {
      debugPrint('获取图片尺寸失败: $e');
      return {'width': 0, 'height': 0};
    }
  }
}

