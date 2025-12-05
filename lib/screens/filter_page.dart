import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'result_screen.dart';
import 'search_loading_screen.dart';
import '../config/search_config.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // 선택된 카테고리들
  final Set<String> _selectedCategories = {};

  // 내 주변 검색 여부
  bool _isNearbySearch = false;

  // 거리 범위 (km)
  double _distance = 2.0;

  // 카카오맵 컨트롤러
  bool _isMapReady = false;
  KakaoMapController? _mapController;

  // 카테고리 목록
  final List<Map<String, dynamic>> _categories = [
    {'name': '맛집', 'icon': Icons.restaurant},
    {'name': '카페', 'icon': Icons.local_cafe},
    {'name': '공원', 'icon': Icons.park},
    {'name': '쇼핑', 'icon': Icons.shopping_bag},
    {'name': '문화', 'icon': Icons.museum},
    {'name': '운동', 'icon': Icons.fitness_center},
    {'name': '관광', 'icon': Icons.camera_alt},
    {'name': '숙박', 'icon': Icons.hotel},
  ];

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

  void _startFilteredSearch() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 카테고리를 선택해주세요'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_mapController == null || !_isMapReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도가 준비 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return;
    }

    // 선택된 카테고리 중 랜덤으로 하나 선택
    final random = Random();
    final categoryList = _selectedCategories.toList();
    final keyword = categoryList[random.nextInt(categoryList.length)];
    debugPrint('🎯 선택된 카테고리: $keyword');

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
      int radius;
      String locationInfo;

      if (_isNearbySearch) {
        // 내 주변 검색
        final position = await _getCurrentLocation();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          radius = (_distance * 1000).toInt(); // km를 m로 변환
          locationInfo = '내 주변 ${_distance.toStringAsFixed(1)}km';
        } else {
          // 위치 가져오기 실패 시 서울 강남 기본값
          latitude = 37.4944992;
          longitude = 127.0252582;
          radius = (_distance * 1000).toInt();
          locationInfo = '서울 강남 ${_distance.toStringAsFixed(1)}km';
        }
      } else {
        // 랜덤 도시 검색
        final random = Random();
        final randomCity = SearchConfig.cities[random.nextInt(SearchConfig.cities.length)];
        latitude = randomCity.latitude;
        longitude = randomCity.longitude;
        radius = 10000; // 전국 검색은 10km
        locationInfo = randomCity.name;
        debugPrint('🎲 랜덤 도시 선택: ${randomCity.name}');
      }

      // 카카오맵 API로 키워드 검색
      final result = await _mapController!.keywordSearch(
        KeywordSearchRequest(
          keyword: keyword,
          y: latitude,
          x: longitude,
          radius: radius,
          sort: SortBy.distance,
        ),
      );

      if (!mounted) return;

      // 결과가 없으면
      if (result.list.isEmpty) {
        Navigator.pop(context); // 로딩 화면 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 결과가 없습니다. 다른 카테고리나 지역을 시도해보세요.')),
        );
        return;
      }

      // 랜덤으로 장소 선택
      final random = Random();
      final randomIndex = random.nextInt(result.list.length);
      final selectedPlace = result.list[randomIndex];

      // 콘솔에 상세 정보 출력
      debugPrint('========================================');
      debugPrint('🎲 필터 검색 결과!');
      debugPrint('📍 검색 위치: $locationInfo');
      debugPrint('🏷️ 카테고리: $keyword');
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
        _startFilteredSearch();
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
              debugPrint('🗺️ 필터 페이지 카카오맵 준비 완료');
            },
          ),
        ),

        // 실제 UI
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // 카테고리 선택 섹션
                Text(
                  '카테고리 선택',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
            const SizedBox(height: 12),
            Text(
              '원하는 장소 유형을 선택하세요',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 20),

            // 카테고리 그리드 (가로 2열)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category['name']);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category['name'] as String);
                      } else {
                        _selectedCategories.add(category['name'] as String);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'] as IconData,
                          size: 28,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          category['name'] as String,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // 내 주변 검색 옵션
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 내 주변 검색 체크박스
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isNearbySearch = !_isNearbySearch;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '내 주변에서 검색',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '현재 위치 기준으로 검색합니다',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 검색 거리 설정 (내 주변 검색 체크시에만 표시)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isNearbySearch
                        ? Column(
                            children: [
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '검색 거리',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_distance.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Slider(
                                value: _distance,
                                min: 0.5,
                                max: 10.0,
                                divisions: 19,
                                label: '${_distance.toStringAsFixed(1)} km',
                                onChanged: (value) {
                                  setState(() {
                                    _distance = value;
                                  });
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '0.5 km',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                  Text(
                                    '10 km',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

                const SizedBox(height: 40),

                // 필터 적용해서 뽑기 버튼
                Center(
                  child: ElevatedButton(
                    onPressed: _isMapReady ? _startFilteredSearch : null,
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
                          _isMapReady ? '필터 적용해서 뽑기!' : '준비 중...',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
