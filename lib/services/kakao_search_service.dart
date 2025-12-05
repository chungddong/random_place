import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

/// 카카오맵 키워드 검색 서비스
class KakaoSearchService {
  static const String _baseUrl = 'https://dapi.kakao.com/v2/local/search/keyword.json';
  
  /// REST API를 통한 키워드 검색
  static Future<List<KeywordAddress>> searchKeyword({
    required String keyword,
    required double latitude,
    required double longitude,
    int radius = 5000,
    int page = 1,
    int size = 15,
  }) async {
    // REST API 키 사용 (없으면 APP_KEY 사용)
    final restApiKey = dotenv.env['REST_API_KEY'] ?? dotenv.env['APP_KEY'] ?? '';
    
    try {
      final uri = Uri.parse(_baseUrl).replace(
        queryParameters: {
          'query': keyword,
          'y': latitude.toString(),
          'x': longitude.toString(),
          'radius': radius.toString(),
          'page': page.toString(),
          'size': size.toString(),
          'sort': 'distance',
        },
      );

      debugPrint('검색 요청: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'KakaoAK $restApiKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List;
        
        return documents.map((doc) {
          return KeywordAddress(
            id: doc['id'],
            placeName: doc['place_name'],
            categoryName: doc['category_name'],
            categoryGroupCode: doc['category_group_code'],
            categoryGroupName: doc['category_group_name'],
            phone: doc['phone'],
            addressName: doc['address_name'],
            roadAddressName: doc['road_address_name'],
            x: doc['x'],
            y: doc['y'],
            placeUrl: doc['place_url'],
            distance: doc['distance'],
          );
        }).toList();
      } else {
        debugPrint('검색 API 오류: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('검색 중 오류 발생: $e');
      return [];
    }
  }
}
