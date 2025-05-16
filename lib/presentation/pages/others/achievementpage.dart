import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/presentation/components/achievement_card.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  final user = FirebaseAuth.instance.currentUser;
  final backendService = BackendService();
  bool? is10Badge, is30Badge, is100Badge, is300Badge, is500Badge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadgeData();
  }

  Future<void> _loadBadgeData() async {
    if (user != null) {
      final result = await backendService.getBadgeInformation(user!);
      if (result != null) {
        if (!mounted) return;
        setState(() {
          is10Badge = result["is10Badge"] ?? false;
          is30Badge = result["is30Badge"] ?? false;
          is100Badge = result["is100Badge"] ?? false;
          is300Badge = result["is300Badge"] ?? false;
          is500Badge = result["is500Badge"] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get userAchievements => [
    {
      'imagePath': 'assets/images/achievement_10.png',
      'isActive': is10Badge ?? false,
    },
    {
      'imagePath': 'assets/images/achievement_30.png',
      'isActive': is30Badge ?? false,
    },
    {
      'imagePath': 'assets/images/achievement_100.png',
      'isActive': is100Badge ?? false,
    },
    {
      'imagePath': 'assets/images/achievement_300.png',
      'isActive': is300Badge ?? false,
    },
    {
      'imagePath': 'assets/images/achievement_500.png',
      'isActive': is500Badge ?? false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(title: "Badges"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 35, left: 35, top: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: userAchievements.length,
              itemBuilder: (context, index) {
                final achievement = userAchievements[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AchievementCard(
                    imagePath: achievement['imagePath'],
                    isActive: achievement['isActive'],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
