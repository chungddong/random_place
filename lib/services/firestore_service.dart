import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scrap_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 스크랩 추가
  Future<void> addScrap(ScrapModel scrap) async {
    await _firestore.collection('scraps').add(scrap.toFirestore());
  }

  // 스크랩 삭제
  Future<void> deleteScrap(String scrapId) async {
    await _firestore.collection('scraps').doc(scrapId).delete();
  }

  // 특정 사용자의 스크랩 목록 가져오기 (실시간)
  Stream<List<ScrapModel>> getUserScraps(String userId) {
    return _firestore
        .collection('scraps')
        .where('userId', isEqualTo: userId)
        .orderBy('scrapedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScrapModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // 특정 장소가 이미 스크랩되었는지 확인
  Future<String?> isPlaceScraped(String userId, String placeId) async {
    final snapshot = await _firestore
        .collection('scraps')
        .where('userId', isEqualTo: userId)
        .where('placeId', isEqualTo: placeId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id; // 스크랩 문서 ID 반환
  }

  // 스크랩에 메모 추가/수정
  Future<void> updateScrapMemo(String scrapId, String memo) async {
    await _firestore.collection('scraps').doc(scrapId).update({
      'memo': memo,
    });
  }

  // 특정 폴더의 스크랩 목록 가져오기 (실시간)
  Stream<List<ScrapModel>> getFolderScraps(String userId, String? folderId) {
    Query query = _firestore
        .collection('scraps')
        .where('userId', isEqualTo: userId);

    if (folderId == null) {
      // 기본 폴더 (folderId가 null인 스크랩)
      query = query.where('folderId', isEqualTo: null);
    } else {
      // 특정 폴더
      query = query.where('folderId', isEqualTo: folderId);
    }

    return query
        .orderBy('scrapedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ScrapModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // 스크랩을 다른 폴더로 이동
  Future<void> moveScrapToFolder(String scrapId, String? folderId) async {
    await _firestore.collection('scraps').doc(scrapId).update({
      'folderId': folderId,
    });
  }
}
