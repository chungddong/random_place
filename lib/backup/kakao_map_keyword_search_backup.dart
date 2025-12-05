/// 카카오맵 키워드 검색 예제 백업 파일
/// 작성일: 2025-12-03
/// 
/// 이 파일은 카카오맵에서 키워드로 장소를 검색하고
/// 마커를 표시하는 기능을 구현한 백업 코드입니다.

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: 'assets/env/.env');

  // 카카오맵 초기화
  AuthRepository.initialize(
    appKey: dotenv.env['APP_KEY'] ?? '',
    baseUrl: dotenv.env['BASE_URL'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Place',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? mapController;
  late TextEditingController textEditingController;

  String searchResult = '';
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController(text: '맛집');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Random Place'),
      ),
      body: Column(
        children: [
          // 지도 영역
          Expanded(
            child: KakaoMap(
              center: LatLng(37.4944992, 127.0252582),
              onMapCreated: (controller) {
                setState(() {
                  mapController = controller;
                });
              },
              markers: markers.toList(),
            ),
          ),
          // 검색 결과 및 검색창 영역
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // 검색 결과 표시
                Container(
                  height: 100,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      searchResult.isEmpty ? '검색 결과가 여기에 표시됩니다' : searchResult,
                      style: TextStyle(
                        color: searchResult.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 검색창
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '검색어를 입력하세요',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _searchKeyword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: const Text('검색'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchKeyword() async {
    if (mapController == null) return;

    final text = textEditingController.value.text;
    if (text.isEmpty) return;

    final center = await mapController!.getCenter();

    final result = await mapController!.keywordSearch(
      KeywordSearchRequest(
        keyword: text,
        y: center.latitude,
        x: center.longitude,
        radius: 1000,
        sort: SortBy.distance,
      ),
    );

    List<LatLng> bounds = [];
    Set<Marker> newMarkers = {};

    debugPrint('========================================');
    debugPrint('🔍 검색어: $text');
    debugPrint('📍 총 ${result.list.length}개 결과');
    debugPrint('========================================');

    for (var item in result.list) {
      LatLng latLng = LatLng(
        double.parse(item.y ?? '0'),
        double.parse(item.x ?? '0'),
      );

      bounds.add(latLng);

      Marker marker = Marker(
        markerId: item.id ?? UniqueKey().toString(),
        latLng: latLng,
        infoWindowContent: '<div>${item.placeName}</div>',
        infoWindowFirstShow: true,
      );

      newMarkers.add(marker);

      // 콘솔에 상세 정보 출력
      debugPrint('----------------------------------------');
      debugPrint('📌 ${item.placeName}');
      debugPrint('   ID: ${item.id}');
      debugPrint('   카테고리: ${item.categoryName}');
      debugPrint('   전화번호: ${item.phone}');
      debugPrint('   주소: ${item.addressName}');
      debugPrint('   도로명주소: ${item.roadAddressName}');
      debugPrint('   거리: ${item.distance}m');
      debugPrint('   URL: ${item.placeUrl}');
      debugPrint('   좌표: (${item.x}, ${item.y})');
    }

    debugPrint('========================================');

    if (bounds.isNotEmpty) {
      mapController!.fitBounds(bounds);
    }

    setState(() {
      markers = newMarkers;
      searchResult = '총 ${result.list.length}개 결과\n${result.list.map((e) => '• ${e.placeName}').join('\n')}';
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
