/// 대한민국 주요 도시 데이터
class KoreaCity {
  final String name;
  final double latitude;
  final double longitude;

  const KoreaCity(this.name, this.latitude, this.longitude);
}

/// 랜덤 검색 설정
class SearchConfig {
  // 검색 카테고리 리스트
  static const List<String> categories = [
    '맛집',
    '카페',
    '관광지',
    '공원',
    '박물관',
    '미술관',
    '쇼핑',
    '영화관',
    '서점',
    '빵집',
    '술집',
    '노래방',
    '찜질방',
    '숙박',
  ];

  // 대한민국 주요 도시 리스트
  static const List<KoreaCity> cities = [
    KoreaCity('서울', 37.5665, 126.9780),
    KoreaCity('부산', 35.1796, 129.0756),
    KoreaCity('인천', 37.4563, 126.7052),
    KoreaCity('대구', 35.8714, 128.6014),
    KoreaCity('광주', 35.1595, 126.8526),
    KoreaCity('대전', 36.3504, 127.3845),
    KoreaCity('울산', 35.5384, 129.3114),
    KoreaCity('세종', 36.4800, 127.2890),
    KoreaCity('수원', 37.2636, 127.0286),
    KoreaCity('창원', 35.2272, 128.6811),
    KoreaCity('고양', 37.6584, 126.8320),
    KoreaCity('용인', 37.2411, 127.1776),
    KoreaCity('성남', 37.4201, 127.1262),
    KoreaCity('청주', 36.6424, 127.4890),
    KoreaCity('전주', 35.8242, 127.1479),
    KoreaCity('천안', 36.8151, 127.1139),
    KoreaCity('포항', 36.0190, 129.3435),
    KoreaCity('제주', 33.4996, 126.5312),
    KoreaCity('안산', 37.3219, 126.8309),
    KoreaCity('김해', 35.2285, 128.8894),
    KoreaCity('평택', 36.9922, 127.1128),
    KoreaCity('의정부', 37.7388, 127.0336),
    KoreaCity('파주', 37.7599, 126.7800),
    KoreaCity('시흥', 37.3800, 126.8028),
    KoreaCity('구미', 36.1136, 128.3445),
  ];
}
