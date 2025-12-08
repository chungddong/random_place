import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/folder_provider.dart';
import 'scrap_list_screen.dart';
import 'folder_management_screen.dart';

class ScrapFolderScreen extends StatelessWidget {
  const ScrapFolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('스크랩 폴더'),
        ),
        body: const Center(
          child: Text('로그인이 필요합니다'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('스크랩 폴더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FolderManagementScreen(),
                ),
              );
            },
            tooltip: '폴더 관리',
          ),
        ],
      ),
      body: Consumer<FolderProvider>(
        builder: (context, folderProvider, child) {
          final folders = folderProvider.folders;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 기본 폴더 카드
              FutureBuilder<int>(
                future: folderProvider.getDefaultFolderScrapCount(user.uid),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildFolderCard(
                    context: context,
                    icon: Icons.bookmark,
                    name: '기본 폴더',
                    count: count,
                    color: colorScheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScrapListScreen(
                            folderId: null,
                            folderName: '기본 폴더',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              if (folders.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    '내 폴더',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // 사용자 생성 폴더 목록
              ...folders.map((folder) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FutureBuilder<int>(
                    future: folderProvider.getFolderScrapCount(folder.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildFolderCard(
                        context: context,
                        icon: Icons.folder,
                        name: folder.name,
                        count: count,
                        color: colorScheme.secondary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScrapListScreen(
                                folderId: folder.id,
                                folderName: folder.name,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              }),

              if (folders.isEmpty) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '아직 생성된 폴더가 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '우측 상단 설정 버튼을 눌러 폴더를 만들어보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildFolderCard({
    required BuildContext context,
    required IconData icon,
    required String name,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count개 항목',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
