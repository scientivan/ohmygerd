import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:OhMyGERD/core/colors.dart';
import 'package:OhMyGERD/core/fonts.dart';
import 'package:OhMyGERD/data/models/chat_model.dart';
import 'package:OhMyGERD/data/services/auth_service.dart';
import 'package:OhMyGERD/presentation/components/custom_appbar.dart';
import '../../../data/services/be_service.dart';

class ChatbotPage extends StatefulWidget {
  final Map<String, dynamic>? extraData;

  const ChatbotPage({super.key, this.extraData});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Chat> _chats = [
    Chat(message: "Halo, Aku Gerdian! Ada yang bisa dibantu?", isUser: false),
  ];

  final List<String> _suggestedQuestions = [
    'Apa itu GERD?',
    'Apa saja gejala dan pemicu GERD?',
    'Apa saja dampak dan urgensi dari GERD?',
  ];

  // late final GenerativeModel _model;
  late final ChatSession _chat;
  bool _isLoading = false;
  bool _isDisposed = false; // Track if the widget is disposed
  Timer? _typingTimer; // Timer for typing animation
  final backendService = BackendService();
  final authService = AuthService();
  final user = FirebaseAuth.instance.currentUser;
  String? username, imageLink;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileData();
    _loadChatHistory();

    // Emergency cuma diproses awal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.extraData != null &&
          widget.extraData!.containsKey('emergencyMessage') &&
          widget.extraData!['emergencyMessage'] != null) {
        Future.delayed(Duration(microseconds: 500), () {
          processEmergencyMessage(widget.extraData!['emergencyMessage']);
        });
      }
    });
  }

  // Add this new method to process emergency messages
  void processEmergencyMessage(String message) {
    _controller.text = message;
    callGeminiModel(); // atau fungsi buat kirim chat
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _isDisposed = true;
    _typingTimer?.cancel(); // Cancel any running timers
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Cancel any ongoing operations when app is backgrounded
      _typingTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant ChatbotPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Cek apakah emergencyMessage berubah
    final oldMsg = oldWidget.extraData?['emergencyMessage'];
    final newMsg = widget.extraData?['emergencyMessage'];

    if (newMsg != null && newMsg != oldMsg) {
      processEmergencyMessage(newMsg);
    }
  }

  Future<void> _loadProfileData() async {
    if (user != null) {
      final userData = await authService.getProfileData(user!);
      if (userData != null) {
        username = userData!["name"];
        imageLink = userData!["profilePicture"];
      }
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (user != null) {
        // Mengambil 5 chat terakhir dari backend
        final response = await backendService.getChatHistory(user!);
        print(response);
        if (response != null && response['chats'] != null) {
          final List<dynamic> chatHistory = response['chats'];

          if (chatHistory.isNotEmpty) {
            // Jika ada riwayat chat
            List<Chat> historicalChats = [];

            for (var chat in chatHistory) {
              // Tambahkan pesan user
              historicalChats.add(
                Chat(message: chat['userMessage'], isUser: true),
              );

              // Tambahkan respons bot
              historicalChats.add(
                Chat(message: chat['botResponse'], isUser: false),
              );
            }

            if (mounted) {
              setState(() {
                // Hapus pesan selamat datang default jika diperlukan
                if (_chats.length == 1 &&
                    _chats[0].message ==
                        "Halo, Aku Gerdian! Ada yang bisa dibantu?") {
                  _chats.clear();
                }

                // Tambahkan riwayat chat
                _chats.addAll(historicalChats);
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching chat history: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat riwayat chat')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Scroll ke pesan terakhir
        _scrollToBottom();
      }
    }
  }

  Future<void> _simulateTyping(String fullText) async {
    String displayedText = '';
    // Cancel any existing typing animation
    _typingTimer?.cancel();

    _typingTimer = Timer.periodic(Duration(milliseconds: 5), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (displayedText.length < fullText.length) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!mounted) return;
        setState(() {
          displayedText += fullText[displayedText.length];
          _chats[_chats.length - 1] = Chat(
            message: displayedText,
            isUser: false,
          );
        });
      } else {
        timer.cancel();
      }
    });

    // Wait for animation to complete
    await Future.delayed(Duration(milliseconds: 20 * fullText.length + 200));
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> callGeminiModel() async {
    if (_controller.text.isEmpty || _isLoading) return;

    final userInput = _controller.text.trim();
    _controller.clear();

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _chats.add(Chat(message: userInput, isUser: true));
      _chats.add(Chat(message: "Sedang memproses...", isUser: false));
    });

    try {
      // final response = await _chat.sendMessage(Content.text(userInput));
      if (user != null) {
        final response = await backendService.chatBotResponse(user!, userInput);
        if (!mounted) return; // Check if widget is still mounted

        setState(() {
          _chats.removeLast(); // remove "Sedang memproses..."
          _chats.add(
            Chat(message: '', isUser: false),
          ); // prepare for typing anim
        });
        await _simulateTyping(response?['response'] ?? "[Empty response]");
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pesan, coba lagi bro')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary.shade500,
      extendBodyBehindAppBar: true,
      appBar: InvisibleAppbar(),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    backgroundColor: AppColors.primary.shade500,
                    expandedHeight: 100.h,
                    floating: false,
                    pinned: false,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        "Tanyakan Pertanyaanmu \n pada Gerdian",
                        style: AppFonts.bold(
                          18.sp,
                        ).copyWith(color: AppColors.neutral.shade0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ];
              },
              body: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary.shade300,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.only(
                          right: 35.w,
                          top: 30.h,
                          left: 35.w,
                          bottom: 160.h,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final chat = _chats[index];
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Column(
                                crossAxisAlignment:
                                    chat.isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        chat.isUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                    children:
                                        chat.isUser
                                            ? [
                                              Text(
                                                username ?? "Pengguna",
                                                style: AppFonts.medium(
                                                  12.sp,
                                                ).copyWith(
                                                  color:
                                                      AppColors
                                                          .neutral
                                                          .shade700,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              ClipOval(
                                                child:
                                                    imageLink != null
                                                        ? Image.network(
                                                          imageLink!,
                                                          width: 23.w,
                                                          height: 23.h,
                                                        )
                                                        : Image.asset(
                                                          'assets/images/photo_profile_placeholder.png',
                                                          width: 23.w,
                                                          height: 23.h,
                                                        ),
                                              ),
                                            ]
                                            : [
                                              Image.asset(
                                                'assets/icons/mascot_icon.png',
                                                width: 23.w,
                                                height: 23.h,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                'Gerdian',
                                                style: AppFonts.medium(
                                                  12.sp,
                                                ).copyWith(
                                                  color:
                                                      AppColors
                                                          .neutral
                                                          .shade700,
                                                ),
                                              ),
                                            ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Align(
                                    alignment:
                                        chat.isUser
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.w,
                                        vertical: 8.h,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            0.7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.neutral.shade0,
                                        border: Border.all(
                                          color: AppColors.neutral.shade900,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft:
                                              chat.isUser
                                                  ? Radius.circular(8.r)
                                                  : Radius.zero,
                                          topRight:
                                              chat.isUser
                                                  ? Radius.zero
                                                  : Radius.circular(8.r),
                                          bottomLeft: Radius.circular(8.r),
                                          bottomRight: Radius.circular(8.r),
                                        ),
                                      ),
                                      child: MarkdownBody(
                                        data: chat.message,
                                        styleSheet:
                                            MarkdownStyleSheet.fromTheme(
                                              Theme.of(context),
                                            ).copyWith(
                                              p: AppFonts.medium(
                                                14.sp,
                                              ).copyWith(
                                                color:
                                                    AppColors.neutral.shade900,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }, childCount: _chats.length),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 90.h,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8.w,
                  children:
                      _suggestedQuestions.map((question) {
                        return ActionChip(
                          backgroundColor: AppColors.neutral.shade0,
                          label: Text(
                            question,
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          labelPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          padding: EdgeInsets.all(4.r),
                          onPressed: () {
                            setState(() {
                              _suggestedQuestions.remove(question);
                            });
                            _controller.text = question;
                            callGeminiModel();
                          },
                        );
                      }).toList(),
                ),
              ),
            ),
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 30.h,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 30.w),
                decoration: BoxDecoration(
                  color: AppColors.neutral.shade0,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.neutral.shade700),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Ketik Pertanyaanmu',
                          hintStyle: AppFonts.medium(
                            14.sp,
                          ).copyWith(color: AppColors.neutral.shade500),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: callGeminiModel,
                      child: Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Image.asset(
                          'assets/icons/send_icon.png',
                          width: 24.w,
                          height: 24.h,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
