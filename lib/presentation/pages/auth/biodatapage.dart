import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:OhMyGERD/presentation/components/alert_notification.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import 'package:OhMyGERD/presentation/components/custom_buttons.dart';
import 'package:OhMyGERD/presentation/components/custom_fields.dart';
import 'package:OhMyGERD/presentation/routes/app_routes.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import '../../../data/services/be_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

class BiodataPage extends StatefulWidget {
  const BiodataPage({super.key});

  @override
  State<BiodataPage> createState() => _BiodataPageState();
}

class _BiodataPageState extends State<BiodataPage> {
  final _dobController = TextEditingController();
  final _weightController = TextEditingController();
  final _diseaseController = TextEditingController();
  String? selectedGender;
  bool isLoading = false;
  final backendService = BackendService();
  final authService = AuthService();

  List<String> selectedDiseases = [];
  final List<String> diseaseOptions = [
    "Kardiovaskular",
    "Diabetes",
    "Pernapasan",
    "Anemia",
    "Kolesterol",
    "Obesitas",
  ];

  bool isErrorVisible = false;
  String alertDescription = "";

  bool isDobValid = true;
  bool isGenderValid = true;
  bool isWeightValid = true;

  @override
  void dispose() {
    _dobController.dispose();
    _weightController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: InvisibleAppbar(isBackButtonVisible: false),
      backgroundColor: AppColors.neutral.shade0,
      body: Stack(
        children: [
          _buildForm(context),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.neutral.shade900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalMargin = constraints.maxWidth > 600 ? 100.w : 43.w;
        double verticalMargin = constraints.maxWidth > 600 ? 100.h : 70.h;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: verticalMargin,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AlertNotification(
                description: alertDescription,
                visible: isErrorVisible,
              ),
              Image.asset('assets/images/biodata_mascot.png', height: 150.h),
              SizedBox(height: 16.h),
              Text("Biodata", style: AppFonts.semiBold(20.sp)),
              SizedBox(height: 4.h),
              Text(
                "Isikan biodatamu di bawah ini",
                style: AppFonts.regular(14.sp),
              ),
              SizedBox(height: 32.h),
              CustomDatePickerField(
                title: "Tanggal Lahir",
                hintText: "Pilih tanggal lahirmu",
                controller: _dobController,
                onDatePicked: (_) => setState(() {}),
                errorText: isDobValid ? null : "Tanggal lahir wajib diisi",
              ),
              SizedBox(height: 16.h),
              CustomDropDownField(
                title: "Jenis Kelamin",
                hintText: "Pilih Jenis Kelamin",
                items: ["Laki-Laki", "Perempuan"],
                selectedItem: selectedGender,
                onChanged: (val) => setState(() => selectedGender = val),
                errorText: isGenderValid ? null : "Jenis kelamin wajib dipilih",
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                title: "Berat Badan",
                hintText: "Masukkan berat badanmu (kg)",
                controller: _weightController,
                errorText: isWeightValid ? null : "Berat badan wajib diisi",
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),
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
              SizedBox(height: 32.h),
              MainButton(text: "Selanjutnya", onPressed: submitForm),
            ],
          ),
        );
      },
    );
  }

  Future<void> submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    final dob = _dobController.text.trim();
    final weightText = _weightController.text.trim();

    if (!mounted) return;
    setState(() {
      isDobValid = dob.isNotEmpty;
      isGenderValid = selectedGender != null;
      isWeightValid = weightText.isNotEmpty;
      isErrorVisible = false;
      alertDescription = "";
    });

    if (!isDobValid || !isGenderValid || !isWeightValid || user == null) {
      setState(() {
        isErrorVisible = true;
        alertDescription = "Mohon isi semua data dengan benar";
      });
      return;
    }

    final weight = int.tryParse(weightText);
    if (weight == null || weight <= 0 || weight > 300) {
      setState(() {
        isWeightValid = false;
        isErrorVisible = true;
        alertDescription = "Berat badan tidak valid";
      });
      return;
    }

    setState(() => isLoading = true);

    final response = await authService.sendUserBiodata(
      user,
      dob,
      selectedGender!,
      weight,
      selectedDiseases.join(', '),
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (response != null) {
      context.push(AppRoutes.preference);
    } else {
      setState(() {
        isErrorVisible = true;
        alertDescription = "Gagal mengirim biodata!";
      });
    }
  }
}
