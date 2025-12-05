import 'package:cloud_firestore/cloud_firestore.dart';

class ScrapModel {
  final String id; // Firestore 문서 ID
  final String userId; // 스크랩한 사용자 ID
  final String placeId; // 카카오맵 장소 ID
  final String placeName;
  final String categoryName;
  final String phone;
  final String addressName;
  final String roadAddressName;
  final String placeUrl;
  final double latitude;
  final double longitude;
  final DateTime scrapedAt;
  final String? memo; // 사용자 메모 (선택)

  ScrapModel({
    required this.id,
    required this.userId,
    required this.placeId,
    required this.placeName,
    required this.categoryName,
    required this.phone,
    required this.addressName,
    required this.roadAddressName,
    required this.placeUrl,
    required this.latitude,
    required this.longitude,
    required this.scrapedAt,
    this.memo,
  });

  factory ScrapModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ScrapModel(
      id: id,
      userId: data['userId'] ?? '',
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      categoryName: data['categoryName'] ?? '',
      phone: data['phone'] ?? '',
      addressName: data['addressName'] ?? '',
      roadAddressName: data['roadAddressName'] ?? '',
      placeUrl: data['placeUrl'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      scrapedAt: (data['scrapedAt'] as Timestamp).toDate(),
      memo: data['memo'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'placeId': placeId,
      'placeName': placeName,
      'categoryName': categoryName,
      'phone': phone,
      'addressName': addressName,
      'roadAddressName': roadAddressName,
      'placeUrl': placeUrl,
      'latitude': latitude,
      'longitude': longitude,
      'scrapedAt': Timestamp.fromDate(scrapedAt),
      'memo': memo,
    };
  }
}
