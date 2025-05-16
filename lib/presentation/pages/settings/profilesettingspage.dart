import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collection/collection.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();

  String? selectedGender;
  List<String> initialDiseases = [];

  List<String> selectedDiseases = [];
  final List<String> diseaseOptions = [
    "Kardiovaskular",
    "Diabetes",
    "Pernapasan",
    "Anemia",
    "Kolesterol",
    "Obesitas",
  ];

  File? _profileImage;
  final auth = AuthService();
  final user = FirebaseAuth.instance.currentUser;

  String? name, weighString;
  int? weight;
  bool _isLoading = true;
  bool _isPicking = false;

  // Future<void> _pickImage() async {
  //   if (_isPicking) return;
  //   _isPicking = true;
  //   try {
  //     final picker = ImagePicker();
  //     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  //     if (pickedFile != null) {
  //       if (!mounted) return;
  //       setState(() {
  //         _profileImage = File(pickedFile.path);
  //       });
  //     }
  //   } catch (err) {
  //     print("Error picking image : ${err}");
  //   } finally {
  //     _isPicking = false;
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (user != null) {
      final result = await auth.getProfileData(user!);
      if (result != null) {
        if (!mounted) return;
        setState(() {
          name = result["name"];
          weight = result["weight"];
          weighString = weight.toString();
          final fetchedDiseases = result["diseases"];
          // Mengubah fetchedDiseases (string) menjadi list untuk dibandingkan dengan selectedDiseases
          final fetchedDiseasesList =
              fetchedDiseases
                  .split(", ")
                  .map((disease) => disease.trim())
                  .toList();

          // Menyimpan hasil perubahan
          initialDiseases = List.from(fetchedDiseasesList);
          selectedDiseases = initialDiseases;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.neutral.shade0,
      appBar: InvisibleAppbar(title: "Profil"),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.neutral.shade900,
                  ),
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                    ).copyWith(top: 16, bottom: 93),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              _profileImage != null
                                  ? Image.file(
                                    _profileImage!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                  : (user!.photoURL != null
                                      ? Image.network(
                                        user!.photoURL!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.asset(
                                        'assets/images/photo_profile_placeholder.png',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )),
                        ),

                        SizedBox(height: 8),
                        SizedBox(height: 16),
                        CustomTextField(
                          title: "Nama",
                          hintText: name ?? "Isi namamu",
                          controller: _nameController,
                        ),
                        SizedBox(height: 16),
                        CustomDatePickerField(
                          title: "Tanggal Lahir",
                          hintText: "Pilih tanggal lahirmu",
                          controller: _dobController,
                          onDatePicked: (_) {},
                        ),
                        SizedBox(height: 16),
                        CustomDropDownField(
                          title: "Jenis Kelamin",
                          hintText: "Pilih Jenis Kelamin",
                          items: ["Laki-Laki", "Perempuan"],
                          selectedItem: selectedGender,
                          onChanged:
                              (val) => setState(() => selectedGender = val),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          title: "Berat Badan",
                          hintText: weighString ?? "Isi berat badanmu",
                          controller: _weightController,
                        ),
                        const SizedBox(height: 16),
                        CustomCheckboxField(
                          title: "Penyakit Bawaan (Opsional)",
                          items: diseaseOptions,
                          selectedItems: selectedDiseases,
                          onChanged: (newSelectedItems) {
                            setState(() {
                              selectedDiseases = newSelectedItems;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        MainButton(
                          text: "Simpan perubahan",
                          isLoading: false,
                          onPressed: () async {
                            Map<String, dynamic> updatedFields = {};

                            final newName = _nameController.text.trim();
                            final newWeightStr = _weightController.text.trim();
                            final newWeight = int.tryParse(newWeightStr);

                            if (newName.isNotEmpty && newName != name) {
                              updatedFields['name'] = newName;
                            }

                            if (newWeight != null && newWeight != weight) {
                              updatedFields['weight'] = newWeight;
                            }
                            if (!ListEquality().equals(
                              selectedDiseases,
                              initialDiseases,
                            )) {
                              updatedFields['diseases'] = selectedDiseases.join(
                                ', ',
                              );
                            }

                            if (user != null && updatedFields.isNotEmpty) {
                              await auth.updateProfileData(
                                user!,
                                updatedFields,
                              );
                              context.go(AppRoutes.home);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
