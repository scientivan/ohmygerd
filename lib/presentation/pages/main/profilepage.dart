import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/presentation/components/achievement_card.dart';
import 'package:OhMyGERD/presentation/components/shimmer_loading_card.dart';
import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  String? name,
      gender,
      profilePicture,
      currentStreakString,
      currentNoGerdStreakString;
  int? currentStreak, currentNoGerdStreak;
  dynamic weight;
  bool _isLoading = true;
  bool? is10Badge, is30Badge, is100Badge, is300Badge, is500Badge;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Method to load profile data
  Future<void> _loadProfileData() async {
    if (user != null) {
      setState(() {
        _isLoading = true;
      });

      final result = await authService.getProfileData(user!);
      if (result != null) {
        if (!mounted) return;
        setState(() {
          name = result["name"];
          gender = result["gender"];
          weight = result["weight"];
          profilePicture = result["profilePicture"];
          currentStreak = result["currentStreak"];
          currentStreakString = currentStreak?.toString();
          currentNoGerdStreak = result["currentNoGerdStreak"];
          currentNoGerdStreakString = currentNoGerdStreak?.toString();

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

  // Method to handle refresh - will be connected to RefreshIndicator
  Future<void> _handleRefresh() async {
    await _loadProfileData();
    return Future.value();
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
  ];

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double profileImageSize =
        screenSize.width * 0.25; // 25% of screen width
    final double containerHeight =
        screenSize.height * 0.07; // 7% of screen height

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.secondary.shade200,
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: Container(
              margin: const EdgeInsets.only(left: 2),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.shade300,
              ),
              child: Image.asset(
                'assets/icons/settings_icon.png',
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading settings icon: $error');
                  return const Icon(Icons.settings, color: Colors.white);
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.secondary.shade600,
          backgroundColor: AppColors.secondary.shade0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      height: containerHeight,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.shade200,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(color: AppColors.neutral.shade900),
                        ),
                      ),
                    ),
                    Positioned(
                      top: containerHeight - (profileImageSize / 2),
                      child: Center(
                        child:
                            _isLoading
                                ? ShimmerLoadingCard(
                                  height: profileImageSize,
                                  width: profileImageSize,
                                  borderRadius: profileImageSize / 2,
                                )
                                : profilePicture != null
                                ? CircleAvatar(
                                  radius: profileImageSize / 2,
                                  backgroundImage: NetworkImage(
                                    profilePicture!,
                                  ),
                                  onBackgroundImageError: (
                                    exception,
                                    stackTrace,
                                  ) {
                                    print(
                                      'Error loading profile image: $exception',
                                    );
                                  },
                                )
                                : Image.asset(
                                  'assets/images/photo_profile_placeholder.png',
                                  width: profileImageSize,
                                  height: profileImageSize,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Error loading placeholder image: $error',
                                    );
                                    return CircleAvatar(
                                      radius: profileImageSize / 2,
                                      backgroundColor: Colors.grey.shade300,
                                      child: Icon(
                                        Icons.person,
                                        size: profileImageSize * 0.6,
                                        color: Colors.grey.shade700,
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        top: containerHeight + (profileImageSize / 2) + 8,
                        left: screenSize.width * 0.08,
                        right: screenSize.width * 0.08,
                      ),
                      child: Column(
                        children: [
                          // Name
                          _isLoading
                              ? ShimmerLoadingCard(
                                height: 24,
                                width: 150,
                                borderRadius: 4,
                              )
                              : Text(
                                name ?? '-',
                                style: AppFonts.bold(24),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                          const SizedBox(height: 4),
                          // Gender and weight
                          _isLoading
                              ? ShimmerLoadingCard(
                                height: 16,
                                width: 100,
                                borderRadius: 4,
                              )
                              : Text(
                                "${gender ?? '-'} | ${weight ?? '-'} kg",
                                style: AppFonts.medium(14),
                              ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Overview", style: AppFonts.semiBold(16)),
                              const SizedBox(height: 8),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final double spacing = 8;
                                  final double cardWidth =
                                      (constraints.maxWidth - spacing) / 2;

                                  if (_isLoading) {
                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: 8,
                                      children: [
                                        ShimmerLoadingCard(
                                          height: 58,
                                          width: cardWidth,
                                          borderRadius: 8,
                                        ),
                                        ShimmerLoadingCard(
                                          height: 58,
                                          width: cardWidth,
                                          borderRadius: 8,
                                        ),
                                      ],
                                    );
                                  }

                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: 8,
                                    children: [
                                      // Streak Card
                                      _buildStatCard(
                                        cardWidth,
                                        "assets/icons/fire_icon.png",
                                        currentStreakString != "null"
                                            ? currentStreakString ?? "0"
                                            : "0",
                                        "Hari streak",
                                      ),
                                      // No GERD Streak Card
                                      _buildStatCard(
                                        cardWidth,
                                        "assets/icons/mascot_icon.png",
                                        currentNoGerdStreakString != "null"
                                            ? currentNoGerdStreakString ?? "0"
                                            : "0",
                                        "Hari tanpa GERD",
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Pencapaian", style: AppFonts.semiBold(16)),
                              GestureDetector(
                                onTap:
                                    () => context.push(AppRoutes.achievement),
                                child: Text(
                                  "Lihat Selengkapnya",
                                  style: AppFonts.regular(
                                    12,
                                  ).copyWith(color: AppColors.neutral.shade900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Achievement cards
                          _isLoading
                              ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: List.generate(
                                  3,
                                  (index) => ShimmerLoadingCard(
                                    height: screenSize.width * 0.35,
                                    width: screenSize.width * 0.25,
                                    borderRadius: 8.r,
                                  ),
                                ),
                              )
                              : SizedBox(
                                height: screenSize.width * 0.32,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: userAchievements.length,
                                  itemBuilder: (context, index) {
                                    final achievement = userAchievements[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: AchievementCard(
                                        imagePath: achievement['imagePath'],
                                        isActive: achievement['isActive'],
                                        width: screenSize.width * 0.25,
                                        height: screenSize.width * 0.30,
                                      ),
                                    );
                                  },
                                ),
                              ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    double width,
    String iconPath,
    String value,
    String label,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.secondary.shade200,
        border: Border.all(color: AppColors.neutral.shade900),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Image.asset(
            iconPath,
            width: 38,
            height: 42,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading icon: $iconPath - $error');
              return Icon(
                iconPath.contains("fire")
                    ? Icons.local_fire_department
                    : Icons.person,
                size: 38,
                color: AppColors.secondary.shade600,
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppFonts.semiBold(16),
                  overflow: TextOverflow.ellipsis,
                ),

                Text(
                  label,
                  style: AppFonts.regular(12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
