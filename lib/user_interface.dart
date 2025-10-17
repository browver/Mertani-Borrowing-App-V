import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:user_app/firebase_services.dart';
import 'package:user_app/menu_dashboard.dart';
import 'package:user_app/notification_service.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> with TickerProviderStateMixin {
  String searchQuery = '';
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _isAnimationInitialized = false;
  
  // Track which item is being pressed
  String? _pressedUserId;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    try {
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _slideController = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
      
      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 2.0,
      ).animate(CurvedAnimation(
        parent: _fadeController!,
        curve: Curves.easeInOut,
      ));
      
      _slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController!,
        curve: Curves.easeOutCubic,
      ));

      setState(() {
        _isAnimationInitialized = true;
      });

      _fadeController?.forward();
      _slideController?.forward();
    } catch (e) {
      // Fallback if animation fails
      setState(() {
        _isAnimationInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if(!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Method to get borrowed items count for a specific user
  Stream<Map<String, int>> _getUserBorrowedStats(String username) {
    return FirebaseFirestore.instance
        .collection('borrowed')
        .where('by', isEqualTo: username)
        .snapshots()
        .map((snapshot) {
      int totalBorrowed = 0;
      int activeBorrowed = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0) as int;
        final status = data['status'] ?? '';
        
        totalBorrowed += amount;
        if (status == 'dipinjam') {
          activeBorrowed += amount;
        }
      }
      
      return {
        'total': totalBorrowed,
        'active': activeBorrowed,
      };
    });
  }

    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        title: Text('Kelola Pengguna', style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        )),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width - 100,
                  kToolbarHeight,
                  0,
                  0,
                ),
                items: [
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(
                      children: const [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout'),
                      ],
                    ),
                  ),
                ],
              ).then((value) {
                if (value == 'logout') {
                  _logout();
                }
              });
            },
          ),
        ],
      ),
      body: _isAnimationInitialized && _fadeAnimation != null && _slideAnimation != null
          ? FadeTransition(
              opacity: _fadeAnimation!,
              child: SlideTransition(
                position: _slideAnimation!,
                child: _buildBody(),
              ),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Enhanced Search Section
        Container(
          margin: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari kontak...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 22,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              style: GoogleFonts.poppins(fontSize: 16),
              onChanged: (value) { 
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        
        // Users List
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat kontak...',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Filter users based on search query
              final users = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final username = (data['username'] ?? '').toString().toLowerCase();
                return username.contains(searchQuery);
              }).toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        searchQuery.isEmpty 
                            ? 'Belum ada kontak terdaftar'
                            : 'Kontak tidak ditemukan',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data();
                  final username = data['username'] ?? 'No name';
                  final role = data['role'] ?? 'user';
                  final divisi = data['divisi'] ?? 'Unknown';
                  final userId = user.id;

                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 100)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, animationValue, child) {
                      return Transform.translate(
                        offset: Offset(50 * (1 - animationValue), 0),
                        child: Opacity(
                          opacity: animationValue,
                          child: child,
                        ),
                      );
                    },
                    child: StreamBuilder<Map<String, int>>(
                      stream: _getUserBorrowedStats(username),
                      builder: (context, statsSnapshot) {
                        final stats = statsSnapshot.data ?? {'total': 0, 'active': 0};
                        
                        return Material(
                          color: Colors.transparent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: _pressedUserId == userId 
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.white,
                              border: const Border(
                                bottom: BorderSide(
                                  color: Color(0xFFE8E8E8),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: InkWell(
                              splashColor: Colors.indigo.withValues(alpha: 0.1),
                              highlightColor: Colors.indigo.withValues(alpha: 0.05),
                              onTapDown: (_) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _pressedUserId = userId;
                                });
                              },
                              onTapUp: (_) {
                                setState(() {
                                  _pressedUserId = null;
                                });
                              },
                              onTapCancel: () {
                                setState(() {
                                  _pressedUserId = null;
                                });
                              },
                              onTap: () async {
                                await Future.delayed(const Duration(milliseconds: 100));
                                if (!context.mounted) return; 
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 350),
                                      reverseTransitionDuration: const Duration(milliseconds: 300),
                                      pageBuilder: (context, animation, secondaryAnimation) =>
                                          MyBorrowingsPage(userName: username, isSelf: false),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        // Fade transition
                                        return FadeTransition(
                                          opacity: CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeInOutQuart,
                                          ),
                                          child: ScaleTransition(
                                            scale: Tween<double>(
                                              begin: 0.95,
                                              end: 1.0,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOutQuart,
                                            )),
                                            child: child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },

                              child: AnimatedScale(
                                scale: _pressedUserId == userId ? 0.98 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeInOut,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Avatar with enhanced animation
                                      Hero(
                                        tag: 'avatar_$username',
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 150),
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: role == 'admin' 
                                                ? Colors.purple
                                                : Colors.indigo[400],
                                            shape: BoxShape.circle,
                                            boxShadow: _pressedUserId == userId 
                                                ? [
                                                    BoxShadow(
                                                      color: (role == 'admin' 
                                                          ? Colors.purple.withValues(alpha: 0.4)
                                                          : Colors.indigo).withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                : [],
                                          ),
                                          child: Icon(
                                            role == 'admin' ? Icons.admin_panel_settings : Icons.person,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      
                                      // User Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Name and Role
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    username,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF1F1F1F),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: role == 'admin' 
                                                        ? Colors.purple.withValues(alpha: 0.2)
                                                        : Colors.indigo.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    role.toUpperCase(),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: role == 'admin' 
                                                          ? Colors.purple
                                                          : Colors.indigo,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),

                                            // Division and borrowed items count
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    divisi,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (stats['active']! > 0)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 7, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[500],
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      '${stats['active']}',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Notification Bell
                                      if (stats['active']! > 0)
                                      // // Tombol Testing
                                      //   Container(
                                      //     margin: const EdgeInsets.only(left: 8),
                                      //     child: Material(
                                      //       color: Colors.transparent,
                                      //       child: InkWell(
                                      //         borderRadius: BorderRadius.circular(20),
                                      //         onTap: () {
                                      //           HapticFeedback.lightImpact();
                                      //             NotificationService().schedulerNotification(
                                      //               id: 0, 
                                      //               title: 'Peringatan Jadwal', 
                                      //               body: 'Kembalikan barang');
                                      //         },
                                      //         child: Container(
                                      //           padding: const EdgeInsets.all(10),
                                      //           decoration: BoxDecoration(
                                      //             color: Colors.indigo,
                                      //             shape: BoxShape.circle,
                                      //             boxShadow: [
                                      //               BoxShadow(
                                      //                 color: Colors.black.withValues(alpha: 0.1),
                                      //                 blurRadius: 3,
                                      //                 offset: const Offset(0, 2),
                                      //               )
                                      //             ],
                                      //           ),
                                      //           child: const Icon(
                                      //             Icons.timelapse,
                                      //             color: Colors.white,
                                      //             size: 18,
                                      //           ),
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ),
                                        if(role == 'alien')
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTap: () async {
                                                HapticFeedback.lightImpact();

                                                await NotificationService().scheduleBorrowingNotifications(
                                                  username: username
                                                );

                                                if(!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Peringatan telah dikirim ke $username',
                                                      style: GoogleFonts.poppins(),
                                                    ),
                                                    backgroundColor: Colors.purple,
                                                    duration: const Duration(seconds: 2),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    margin: const EdgeInsets.all(8),
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              },
                                              child: AnimatedScale(
                                                scale: 1.0,
                                                duration: const Duration(milliseconds: 200),
                                                curve: Curves.easeInOut,
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo,
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.1),
                                                        blurRadius: 3,
                                                        offset: const Offset(0, 2),
                                                      )
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    Icons.notifications,
                                                    color: Colors.white,
                                                    size: 18, 
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }
  }