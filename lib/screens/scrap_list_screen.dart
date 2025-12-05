import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scrap_provider.dart';
import '../models/scrap_model.dart';
import 'result_screen.dart';

class ScrapListScreen extends StatefulWidget {
  const ScrapListScreen({super.key});

  @override
  State<ScrapListScreen> createState() => _ScrapListScreenState();
}

class _ScrapListScreenState extends State<ScrapListScreen> {
  @override
  void initState() {
    super.initState();
    // 로그인된 사용자의 스크랩 구독
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final scrapProvider = Provider.of<ScrapProvider>(context, listen: false);

      if (authProvider.user != null) {
        scrapProvider.subscribeToUserScraps(authProvider.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스크랩 목록'),
      ),
      body: Consumer2<AuthProvider, ScrapProvider>(
        builder: (context, authProvider, scrapProvider, child) {
          // 로그인하지 않은 경우
          if (authProvider.user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '로그인이 필요합니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '스크랩 기능을 사용하려면\n로그인해주세요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          // 스크랩이 없는 경우
          if (scrapProvider.scraps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '스크랩한 장소가 없습니다',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '마음에 드는 장소를 발견하면\n스크랩해보세요',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            );
          }

          // 스크랩 리스트
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scrapProvider.scraps.length,
            itemBuilder: (context, index) {
              final scrap = scrapProvider.scraps[index];
              return _buildScrapCard(context, scrap, scrapProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildScrapCard(BuildContext context, ScrapModel scrap, ScrapProvider scrapProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // 결과 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                place: PlaceResult(
                  id: scrap.placeId,
                  placeName: scrap.placeName,
                  categoryName: scrap.categoryName,
                  phone: scrap.phone,
                  addressName: scrap.addressName,
                  roadAddressName: scrap.roadAddressName,
                  distance: '',
                  placeUrl: scrap.placeUrl,
                  x: scrap.longitude,
                  y: scrap.latitude,
                ),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 장소 이름과 삭제 버튼
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scrap.placeName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      // 삭제 확인 다이얼로그
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('스크랩 삭제'),
                          content: const Text('이 장소를 스크랩에서 삭제하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('삭제'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await scrapProvider.deleteScrap(scrap.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('스크랩이 삭제되었습니다.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),

              // 카테고리
              if (scrap.categoryName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  scrap.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],

              const SizedBox(height: 8),

              // 주소
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      scrap.roadAddressName.isNotEmpty
                          ? scrap.roadAddressName
                          : scrap.addressName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ),
                ],
              ),

              // 전화번호
              if (scrap.phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      scrap.phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ],

              // 스크랩 날짜
              const SizedBox(height: 8),
              Text(
                '스크랩: ${_formatDate(scrap.scrapedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else {
      return '${date.year}.${date.month}.${date.day}';
    }
  }
}
