import 'dart:async';
import 'package:flutter/material.dart';
import '../models/folder_model.dart';
import '../services/folder_service.dart';

class FolderProvider extends ChangeNotifier {
  final FolderService _folderService = FolderService();
  List<FolderModel> _folders = [];
  StreamSubscription? _subscription;

  List<FolderModel> get folders => _folders;

  // 사용자의 폴더 구독 시작
  void subscribeToUserFolders(String userId) {
    _subscription?.cancel();

    _subscription = _folderService.getUserFoldersStream(userId).listen((folders) {
      _folders = folders;
      notifyListeners();
    });
  }

  // 구독 취소
  void unsubscribe() {
    _subscription?.cancel();
    _folders = [];
    notifyListeners();
  }

  // 폴더 생성
  Future<bool> createFolder(String userId, String folderName) async {
    try {
      // 중복 이름 체크
      if (_folders.any((folder) => folder.name == folderName)) {
        return false; // 중복된 이름
      }

      await _folderService.createFolder(userId, folderName);
      return true;
    } catch (e) {
      debugPrint('폴더 생성 실패: $e');
      return false;
    }
  }

  // 폴더 이름 수정
  Future<bool> updateFolderName(String folderId, String newName) async {
    try {
      // 중복 이름 체크 (자기 자신 제외)
      if (_folders.any((folder) => folder.id != folderId && folder.name == newName)) {
        return false; // 중복된 이름
      }

      await _folderService.updateFolderName(folderId, newName);
      return true;
    } catch (e) {
      debugPrint('폴더 이름 수정 실패: $e');
      return false;
    }
  }

  // 폴더 삭제
  Future<bool> deleteFolder(String folderId) async {
    try {
      await _folderService.deleteFolder(folderId);
      return true;
    } catch (e) {
      debugPrint('폴더 삭제 실패: $e');
      return false;
    }
  }

  // 특정 폴더의 스크랩 개수 가져오기
  Future<int> getFolderScrapCount(String folderId) async {
    return await _folderService.getFolderScrapCount(folderId);
  }

  // 기본 폴더의 스크랩 개수 가져오기
  Future<int> getDefaultFolderScrapCount(String userId) async {
    return await _folderService.getDefaultFolderScrapCount(userId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
