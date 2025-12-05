import 'package:flutter/material.dart';
import '../models/scrap_model.dart';
import '../services/firestore_service.dart';
import '../screens/result_screen.dart';

class ScrapProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<ScrapModel> _scraps = [];
  bool _isLoading = false;

  List<ScrapModel> get scraps => _scraps;
  bool get isLoading => _isLoading;

  // 사용자의 스크랩 목록 실시간 구독
  void subscribeToUserScraps(String userId) {
    _firestoreService.getUserScraps(userId).listen((scraps) {
      _scraps = scraps;
      notifyListeners();
    });
  }

  // 스크랩 추가
  Future<void> addScrap(String userId, PlaceResult place) async {
    _isLoading = true;
    notifyListeners();

    final scrap = ScrapModel(
      id: '', // Firestore에서 자동 생성됨
      userId: userId,
      placeId: place.id,
      placeName: place.placeName,
      categoryName: place.categoryName,
      phone: place.phone,
      addressName: place.addressName,
      roadAddressName: place.roadAddressName,
      placeUrl: place.placeUrl,
      latitude: place.y,
      longitude: place.x,
      scrapedAt: DateTime.now(),
    );

    await _firestoreService.addScrap(scrap);

    _isLoading = false;
    notifyListeners();
  }

  // 스크랩 삭제
  Future<void> deleteScrap(String scrapId) async {
    await _firestoreService.deleteScrap(scrapId);
    // 실시간 구독으로 자동 업데이트됨
  }

  // 특정 장소가 스크랩되었는지 확인
  Future<String?> isPlaceScraped(String userId, String placeId) async {
    return await _firestoreService.isPlaceScraped(userId, placeId);
  }

  // 메모 추가/수정
  Future<void> updateMemo(String scrapId, String memo) async {
    await _firestoreService.updateScrapMemo(scrapId, memo);
  }
}
