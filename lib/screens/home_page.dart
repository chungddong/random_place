import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'result_screen.dart';
import 'search_loading_screen.dart';
import '../config/search_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isNearbySearch = false;
  bool _isMapReady = false;
  KakaoMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다.')),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 거부되었습니다.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.')),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  void _startRandomSearch() async {
    if (_mapController == null || !_isMapReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도가 준비 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    // 랜덤으로 카테고리 선택
    final random = Random();
    final keyword = SearchConfig.categories[random.nextInt(SearchConfig.categories.length)];
    debugPrint('🎯 랜덤 카테고리 선택: $keyword');

    // 로딩 화면으로 이동
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SearchLoadingScreen(searchKeyword: keyword),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    try {
      // 위치 가져오기
      double latitude;
      double longitude;
      String locationInfo;

      if (_isNearbySearch) {
        // 내 주변 검색
        final position = await _getCurrentLocation();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          locationInfo = '내 주변';
        } else {
          // 위치 가져오기 실패 시 서울 강남 기본값
          latitude = 37.4944992;
          longitude = 127.0252582;
          locationInfo = '서울 강남';
        }
      } else {
        // 랜덤 도시 검색
        final random = Random();
        final randomCity = SearchConfig.cities[random.nextInt(SearchConfig.cities.length)];
        latitude = randomCity.latitude;
        longitude = randomCity.longitude;
        locationInfo = randomCity.name;
        debugPrint('🎲 랜덤 도시 선택: ${randomCity.name}');
      }

      // 카카오맵 API로 키워드 검색
      final result = await _mapController!.keywordSearch(
        KeywordSearchRequest(
          keyword: keyword,
          y: latitude,
          x: longitude,
          radius: _isNearbySearch ? 2000 : 10000, // 랜덤 도시는 10km
          sort: SortBy.distance,
        ),
      );

      if (!mounted) return;

      // 결과가 없으면
      if (result.list.isEmpty) {
        Navigator.pop(context); // 로딩 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 결과가 없습니다. 다른 키워드로 시도해보세요.')),
        );
        return;
      }

      // 랜덤으로 장소 선택
      final random = Random();
      final randomIndex = random.nextInt(result.list.length);
      final selectedPlace = result.list[randomIndex];

      // 콘솔에 상세 정보 출력
      debugPrint('========================================');
      debugPrint('🎲 랜덤 장소 선택!');
      debugPrint('📍 검색 위치: $locationInfo');
      debugPrint('📌 ${selectedPlace.placeName}');
      debugPrint('   카테고리: ${selectedPlace.categoryName}');
      debugPrint('   주소: ${selectedPlace.addressName}');
      debugPrint('   도로명주소: ${selectedPlace.roadAddressName}');
      debugPrint('   전화번호: ${selectedPlace.phone}');
      debugPrint('   거리: ${selectedPlace.distance}m');
      debugPrint('========================================');

      // 로딩 화면을 충분히 보여주기 위한 지연 (1초)
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 결과 화면으로 이동 (로딩 화면 교체)
      final shouldRetry = await Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
            place: PlaceResult.fromKeywordAddress(selectedPlace),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );

      // 다시 뽑기 버튼을 눌렀으면 다시 검색
      if (shouldRetry == true && mounted) {
        _startRandomSearch();
      }
    } catch (e) {
      debugPrint('검색 오류: $e');
      if (mounted) {
        Navigator.pop(context); // 로딩 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 숨겨진 카카오맵 (검색용)
        Positioned(
          left: -1000,
          top: -1000,
          width: 100,
          height: 100,
          child: KakaoMap(
            center: LatLng(37.4944992, 127.0252582),
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                _isMapReady = true;
              });
              debugPrint('🗺️ 숨겨진 카카오맵 준비 완료');
            },
          ),
        ),
        
        // 실제 UI
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 로고 또는 타이틀 영역
                Icon(
                  Icons.place_rounded,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '랜덤 장소 찾기',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '새로운 장소를 발견해보세요',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 60),

                // 내 주변에서 검색 체크박스
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isNearbySearch,
                        onChanged: (value) {
                          setState(() {
                            _isNearbySearch = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '내 주변에서 검색',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (_isNearbySearch) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.my_location,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 랜덤 장소 뽑기 버튼
                ElevatedButton(
                  onPressed: _isMapReady ? _startRandomSearch : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isMapReady ? Icons.casino : Icons.hourglass_empty, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        _isMapReady ? '랜덤 장소 뽑기!' : '준비 중...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
