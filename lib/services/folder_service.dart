import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart';

class FolderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 폴더 생성
  Future<String> createFolder(String userId, String folderName) async {
    try {
      final docRef = await _firestore.collection('folders').add({
        'userId': userId,
        'name': folderName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('폴더 생성 실패: $e');
    }
  }

  // 사용자의 모든 폴더 가져오기 (스트림)
  Stream<List<FolderModel>> getUserFoldersStream(String userId) {
    return _firestore
        .collection('folders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FolderModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // 폴더 이름 수정
  Future<void> updateFolderName(String folderId, String newName) async {
    try {
      await _firestore.collection('folders').doc(folderId).update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('폴더 이름 수정 실패: $e');
    }
  }

  // 폴더 삭제
  Future<void> deleteFolder(String folderId) async {
    try {
      // 해당 폴더의 스크랩을 기본 폴더(null)로 이동
      final scrapsSnapshot = await _firestore
          .collection('scraps')
          .where('folderId', isEqualTo: folderId)
          .get();

      // 배치 작업으로 스크랩의 folderId를 null로 변경
      final batch = _firestore.batch();
      for (var doc in scrapsSnapshot.docs) {
        batch.update(doc.reference, {'folderId': null});
      }
      await batch.commit();

      // 폴더 삭제
      await _firestore.collection('folders').doc(folderId).delete();
    } catch (e) {
      throw Exception('폴더 삭제 실패: $e');
    }
  }

  // 특정 폴더의 스크랩 개수 가져오기
  Future<int> getFolderScrapCount(String folderId) async {
    try {
      final snapshot = await _firestore
          .collection('scraps')
          .where('folderId', isEqualTo: folderId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // 기본 폴더(folderId가 null)의 스크랩 개수 가져오기
  Future<int> getDefaultFolderScrapCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('scraps')
          .where('userId', isEqualTo: userId)
          .where('folderId', isEqualTo: null)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
