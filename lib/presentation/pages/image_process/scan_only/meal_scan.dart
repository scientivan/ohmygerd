import 'dart:async';
import 'dart:io';

import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/services/be_service.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/pages/image_process/by_time/foodcomponentpage.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MealScan extends StatefulWidget {
  const MealScan({super.key});

  @override
  State<MealScan> createState() => _MealScanState();
}

class _MealScanState extends State<MealScan> {
  File? _imageFile;
  bool showError = false;
  bool isLoading = true;
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  List<String> selectedComponents = [];
  List<String> foodComponents = [];
  Map<String, dynamic> foodComponentsWithStatus = {};
  int _dotCount = 0;
  Timer? _dotTimer;

  void _startDotAnimation() {
    _dotTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startDotAnimation();
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get image file passed through extra in context
    final file = GoRouterState.of(context).extra as File?;

    if (file != null) {
      setState(() {
        _imageFile = file;
      });

      // Load food components after getting the file
      _loadFoodComponents(file);
    }
  }

  void toggleComponent(String component) {
    setState(() {
      if (selectedComponents.contains(component)) {
        selectedComponents.remove(component);
      } else {
        selectedComponents.add(component);
      }
    });
  }

  Future<void> _loadFoodComponents(File file) async {
    if (user != null) {
      final result = await backendService.sendPhotoToBeScanned(user!, file);

      if (result != null) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          foodComponentsWithStatus = result;
          foodComponents =
              (result["makanan"] as List)
                  .map((item) => item["nama"] as String)
                  .toList();
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral.shade0,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: EdgeInsets.only(left: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondary.shade200,
          ),
          child: IconButton(
            onPressed: () {
              context.go(AppRoutes.home);
            },
            icon: Icon(Icons.arrow_back),
            iconSize: 24,
            padding: EdgeInsets.all(12),
            color: Colors.black,
          ),
        ),
        title: Text(
          "Pilih Komponen Makanan yang Sesuai",
          style: AppFonts.semiBold(18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 15, right: 30, left: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.secondary.shade300,
                    width: 3,
                  ),
                ),
                child:
                    _imageFile != null
                        ? ClipOval(
                          child: Image.file(
                            _imageFile!,
                            width: 230,
                            height: 230,
                            fit: BoxFit.cover,
                          ),
                        )
                        : SizedBox(
                          width: 230,
                          height: 230,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.neutral.shade900,
                              ),
                            ),
                          ),
                        ),
              ),
              SizedBox(height: 32),
              if (isLoading)
                Center(
                  child: Text(
                    "Sedang mengolah fotomu${'.' * _dotCount}",
                    style: AppFonts.medium(
                      20,
                    ).copyWith(color: AppColors.neutral.shade400),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      foodComponents.map((component) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: FoodComponentButton(
                            label: component,
                            isSelected: selectedComponents.contains(component),
                            onTap: () => toggleComponent(component),
                          ),
                        );
                      }).toList(),
                ),
              SizedBox(height: 24),
              Visibility(
                visible: !isLoading,
                child: MainButton(
                  text: "Selanjutnya",
                  onPressed: () {
                    if (selectedComponents.isEmpty) {
                      setState(() {
                        showError = true;
                      });
                    } else {
                      final filteredComponents =
                          foodComponentsWithStatus['makanan']
                              .where(
                                (item) =>
                                    selectedComponents.contains(item['nama']),
                              )
                              .toList();

                      context.go(
                        AppRoutes.mealResult,
                        extra: {
                          'selectedComponents': filteredComponents,
                          'imageFile': _imageFile,
                        },
                      );
                    }
                  },
                ),
              ),
              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Pilih minimal 1 komponen makanan!",
                    style: AppFonts.semiBold(
                      14,
                    ).copyWith(color: AppColors.danger.shade300),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
