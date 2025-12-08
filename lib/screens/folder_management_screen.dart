import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/folder_provider.dart';
import '../models/folder_model.dart';

class FolderManagementScreen extends StatelessWidget {
  const FolderManagementScreen({super.key});

  void _showCreateFolderDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 폴더 만들기'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '폴더 이름을 입력하세요',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final folderName = controller.text.trim();
                if (folderName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('폴더 이름을 입력해주세요')),
                  );
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final folderProvider = Provider.of<FolderProvider>(context, listen: false);

                if (authProvider.user == null) return;

                final success = await folderProvider.createFolder(
                  authProvider.user!.uid,
                  folderName,
                );

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$folderName 폴더가 생성되었습니다')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미 존재하는 폴더 이름입니다')),
                    );
                  }
                }
              },
              child: const Text('만들기'),
            ),
          ],
        );
      },
    );
  }

  void _showEditFolderDialog(BuildContext context, FolderModel folder) {
    final TextEditingController controller = TextEditingController(text: folder.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('폴더 이름 수정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('폴더 이름을 입력해주세요')),
                  );
                  return;
                }

                final folderProvider = Provider.of<FolderProvider>(context, listen: false);
                final success = await folderProvider.updateFolderName(folder.id, newName);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('폴더 이름이 수정되었습니다')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미 존재하는 폴더 이름입니다')),
                    );
                  }
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFolderDialog(BuildContext context, FolderModel folder) async {
    final folderProvider = Provider.of<FolderProvider>(context, listen: false);
    final scrapCount = await folderProvider.getFolderScrapCount(folder.id);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('폴더 삭제'),
          content: Text(
            scrapCount > 0
                ? '${folder.name} 폴더를 삭제하시겠습니까?\n폴더 내 $scrapCount개의 스크랩은 기본 폴더로 이동됩니다.'
                : '${folder.name} 폴더를 삭제하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () async {
                final success = await folderProvider.deleteFolder(folder.id);

                if (context.mounted) {
                  Navigator.of(context).pop();
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('폴더가 삭제되었습니다')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('폴더 삭제에 실패했습니다')),
                    );
                  }
                }
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('스크랩 폴더 관리'),
      ),
      body: Consumer<FolderProvider>(
        builder: (context, folderProvider, child) {
          final folders = folderProvider.folders;

          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '생성된 폴더가 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '아래 버튼을 눌러 폴더를 만들어보세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: folders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    Icons.folder,
                    color: colorScheme.primary,
                  ),
                  title: Text(folder.name),
                  subtitle: FutureBuilder<int>(
                    future: folderProvider.getFolderScrapCount(folder.id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text('$count개 항목');
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditFolderDialog(context, folder),
                        tooltip: '이름 수정',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _showDeleteFolderDialog(context, folder),
                        tooltip: '폴더 삭제',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFolderDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('폴더 만들기'),
      ),
    );
  }
}
