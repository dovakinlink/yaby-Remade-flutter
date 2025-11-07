import 'package:dio/dio.dart';
import 'package:yabai_app/core/network/api_client.dart';
import 'package:yabai_app/core/network/api_exception.dart';
import 'package:yabai_app/core/network/models/api_response.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_group_model.dart';
import 'package:yabai_app/features/address_book/data/models/address_book_item_model.dart';

class AddressBookRepository {
  const AddressBookRepository(this._apiClient);

  final ApiClient _apiClient;

  /// 获取通讯录列表（按首字母分组）
  Future<List<AddressBookGroupModel>> fetchAddressBook() async {
    try {
      final response = await _apiClient.get('/api/v1/address-book');

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is List) {
            return rawData;
          }
          return [];
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;

      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((item) => AddressBookGroupModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '通讯录加载失败: $error');
    }
  }

  /// 搜索通讯录
  Future<List<AddressBookItemModel>> searchAddressBook(String keyword) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': keyword,
      };

      final response = await _apiClient.get(
        '/api/v1/address-book/search',
        queryParameters: queryParameters,
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is List) {
            return rawData;
          }
          return [];
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;

      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((item) => AddressBookItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '搜索失败: $error');
    }
  }

  /// 患者倒查CRC（返回标准通讯录格式）
  Future<List<AddressBookItemModel>> lookupCrcByPatient(String keyword) async {
    try {
      final queryParameters = <String, dynamic>{
        'keyword': keyword,
      };

      final response = await _apiClient.get(
        '/api/v1/address-book/lookup-crc',
        queryParameters: queryParameters,
      );

      final body = response.data;

      if (body == null) {
        throw ApiException(message: '服务器未返回数据');
      }

      final apiResponse = ApiResponse<List<dynamic>>.fromJson(
        body,
        dataParser: (rawData) {
          if (rawData is List) {
            return rawData;
          }
          return [];
        },
      );

      if (!apiResponse.success) {
        throw ApiException(
          message: apiResponse.message,
          code: apiResponse.code,
        );
      }

      final data = apiResponse.data;

      if (data == null || data.isEmpty) {
        return [];
      }

      return data
          .map((item) => AddressBookItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final dynamic responseBody = error.response?.data;
      String? code;
      String message = '网络请求失败';
      if (responseBody is Map<String, dynamic>) {
        code = responseBody['code'] as String?;
        message = responseBody['message'] as String? ?? message;
      } else if (error.message != null) {
        message = error.message!;
      }
      throw ApiException(message: message, code: code);
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(message: '查询失败: $error');
    }
  }
}

