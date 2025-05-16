import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import '../../../../data/services/be_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodComponentPage extends StatefulWidget {
  const FoodComponentPage({super.key});

  @override
  State<FoodComponentPage> createState() => _FoodComponentPageState();
}

class _FoodComponentPageState extends State<FoodComponentPage> {
  File? _imageFile;
  bool showError = false;
  final backendService = BackendService();
  final user = FirebaseAuth.instance.currentUser;
  bool isLoading = false;
  int _dotCount = 0;
  Timer? _dotTimer;

  List<String> selectedComponents = [];
  List<String> foodComponents = [];
  Map<String, dynamic> foodComponentsWithStatus = {};
  // final List<String> foodComponents = [
  //   'Nasi',
  //   'Ayam',
  //   'Sayur',
  //   'Tempe',
  //   'Tahu',
  // ];
  void toggleComponent(String component) {
    setState(() {
      if (selectedComponents.contains(component)) {
        selectedComponents.remove(component);
      } else {
        selectedComponents.add(component);
      }
    });
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFoodComponents();
    });
    _startDotAnimation();
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

    Future<void> _loadFoodComponents() async {
    setState(() {
      isLoading = true; 
    });
    
    final file = GoRouterState.of(context).extra as File?;
    if (file != null && user != null) {
      _imageFile = file;
      final result = await backendService.sendPhotoToBeScanned(
        user!,
        File(file.path),
      );
      if (result != null) {
        if (!mounted) return;
        setState(() {
          foodComponentsWithStatus = result;
          foodComponents =
              (result["makanan"] as List)
                  .map((item) => item["nama"] as String)
                  .toList();
          isLoading = false; 
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false; 
      });
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
                        AppRoutes.foodResult,
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

class FoodComponentButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FoodComponentButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6.5),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.secondary.shade200
                  : AppColors.neutral.shade0,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.secondary.shade600, width: 2),
        ),
        child: Text(label, style: AppFonts.medium(14)),
      ),
    );
  }
}
