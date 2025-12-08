import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scrap_provider.dart';
import '../providers/folder_provider.dart';

/// 검색 결과를 담는 모델 클래스
class PlaceResult {
  final String id;
  final String placeName;
  final String categoryName;
  final String phone;
  final String addressName;
  final String roadAddressName;
  final String distance;
  final String placeUrl;
  final double x;
  final double y;

  PlaceResult({
    required this.id,
    required this.placeName,
    required this.categoryName,
    required this.phone,
    required this.addressName,
    required this.roadAddressName,
    required this.distance,
    required this.placeUrl,
    required this.x,
    required this.y,
  });

  factory PlaceResult.fromKeywordAddress(KeywordAddress item) {
    return PlaceResult(
      id: item.id ?? '',
      placeName: item.placeName ?? '알 수 없음',
      categoryName: item.categoryName ?? '',
      phone: item.phone ?? '',
      addressName: item.addressName ?? '',
      roadAddressName: item.roadAddressName ?? '',
      distance: item.distance ?? '',
      placeUrl: item.placeUrl ?? '',
      x: double.tryParse(item.x ?? '0') ?? 0,
      y: double.tryParse(item.y ?? '0') ?? 0,
    );
  }
}

/// 검색 결과 화면 - 지도와 상세정보 표시
class ResultScreen extends StatefulWidget {
  final PlaceResult place;

  const ResultScreen({super.key, required this.place});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  KakaoMapController? mapController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // 폴더 선택 다이얼로그
  Future<String?> _showFolderSelectDialog(BuildContext context) async {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final folders = folderProvider.folders;

    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('스크랩 폴더 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                // 기본 폴더
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('기본 폴더'),
                  onTap: () => Navigator.of(context).pop(null), // null = 기본 폴더
                ),
                const Divider(),
                // 사용자 생성 폴더
                ...folders.map((folder) {
                  return ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder.name),
                    onTap: () => Navigator.of(context).pop(folder.id),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;

    return Scaffold(
      appBar: AppBar(
        title: const Text('검색 결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // 지도 영역
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: KakaoMap(
                      center: LatLng(place.y, place.x),
                      onMapCreated: (controller) {
                        setState(() {
                          mapController = controller;
                        });
                        // 마커 추가
                        controller.addMarker(
                          markers: [
                            Marker(
                              markerId: place.id,
                              latLng: LatLng(place.y, place.x),
                              infoWindowContent: '<div style="padding:5px;">${place.placeName}</div>',
                              infoWindowFirstShow: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 상세 정보 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 장소 이름과 스크랩 버튼
                      Row(
                        children: [
                          Icon(
                            Icons.place,
                            color: Theme.of(context).colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              place.placeName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          // 스크랩 아이콘 버튼
                          Consumer2<AuthProvider, ScrapProvider>(
                            builder: (context, authProvider, scrapProvider, child) {
                              return FutureBuilder<String?>(
                                future: authProvider.user != null
                                    ? scrapProvider.isPlaceScraped(
                                        authProvider.user!.uid,
                                        place.id,
                                      )
                                    : Future.value(null),
                                builder: (context, snapshot) {
                                  final isScraped = snapshot.data != null;
                                  final scrapId = snapshot.data;

                                  return IconButton(
                                    icon: Icon(
                                      isScraped ? Icons.bookmark : Icons.bookmark_border,
                                      size: 28,
                                    ),
                                    color: isScraped
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    onPressed: authProvider.user == null
                                        ? null
                                        : () async {
                                            if (isScraped && scrapId != null) {
                                              // 스크랩 취소
                                              await scrapProvider.deleteScrap(scrapId);
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('스크랩이 취소되었습니다.')),
                                                );
                                              }
                                            } else {
                                              // 폴더 선택 다이얼로그 표시
                                              final selectedFolderId = await _showFolderSelectDialog(context);

                                              // 취소하지 않은 경우에만 스크랩 추가
                                              if (selectedFolderId != 'cancelled' && context.mounted) {
                                                await scrapProvider.addScrapToFolder(
                                                  authProvider.user!.uid,
                                                  place,
                                                  selectedFolderId, // null이면 기본 폴더
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('스크랩되었습니다!')),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 카테고리
                      if (place.categoryName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: Text(
                            place.categoryName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 상세 정보 리스트
                      _buildInfoRow(
                        context,
                        Icons.location_on_outlined,
                        '주소',
                        place.roadAddressName.isNotEmpty
                            ? place.roadAddressName
                            : place.addressName,
                      ),

                      if (place.phone.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(context, Icons.phone_outlined, '전화', place.phone),
                      ],

                      if (place.distance.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          Icons.straighten_outlined,
                          '거리',
                          '${place.distance}m',
                        ),
                      ],

                      const SizedBox(height: 24),

                      // 지도에서 열기 버튼
                      if (place.placeUrl.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final url = Uri.parse(place.placeUrl);
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.platformDefault,
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('링크를 열 수 없습니다: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('카카오맵에서 열기'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                      if (place.placeUrl.isNotEmpty) const SizedBox(height: 12),

                      // 다시 뽑기 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.casino),
                          label: const Text('다시 뽑기'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
