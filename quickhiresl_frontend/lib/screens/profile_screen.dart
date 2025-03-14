import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'job_owner_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final ScrollController _scrollController = ScrollController();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final response = await _userService.getUserProfile();
      setState(() {
        _userData = response['data'];
        _isLoading = false;
      });
    } catch (e) {
      print('[ERROR] Failed to load user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('[ERROR] Failed to sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign out. Please try again.')),
        );
      }
    }
  }

  // Function to format user ID
  String _getFormattedUserId() {
    if (_userData?['userId'] != null) {
      String fullId = _userData?['userId'];
      return 'ID: ${fullId.substring(0, 4)}';
    }
    return 'ID: 67d3';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = const Color(0xFF98C9C5);
    final lightAccentColor = const Color(0xFFE8F3F1);

    return Scaffold(
      backgroundColor: Colors.white,
      // Use a constant white background AppBar
      appBar: AppBar(
        title: const Text('My Profile', 
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          )
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // This prevents elevation when scrolled under
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share profile feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ScrollConfiguration(
              // Remove overscroll glow
              behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Container(
                  color: Colors.white, // Ensure background is white
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Profile Image with Edit Button
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accentColor,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: _userData?['profileImage'] != null && _userData!['profileImage'].isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          _userData!['profileImage'],
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.person, size: 40, color: Colors.grey);
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                            ),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: accentColor,
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ],
                        ),
                        
                        // Name
                        const SizedBox(height: 12),
                        Text(
                          _userData?['name'] ?? 'sanuda',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        // User ID - Short format
                        const SizedBox(height: 4),
                        Text(
                          _getFormattedUserId(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        
                        // Stats - 3 Cards in a row
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard('Rating', _userData?['rating']?.toString() ?? '0', Icons.star),
                            const SizedBox(width: 8),
                            _buildStatCard('Jobs', _userData?['jobsCount']?.toString() ?? '0', Icons.work),
                            const SizedBox(width: 8),
                            _buildStatCard('Experience', _userData?['experience']?.toString() ?? '0', Icons.trending_up),
                          ],
                        ),
                        
                        // Job Owner Dashboard Button
                        const SizedBox(height: 16),
                        _buildActionButton(
                          Icons.grid_view,
                          'Job Owner Dashboard',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JobOwnerDashboard(),
                              ),
                            );
                          },
                          accentColor,
                        ),
                        
                        // Account Settings Button
                        const SizedBox(height: 12),
                        _buildActionButton(
                          Icons.settings,
                          'Account Settings',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settings feature coming soon!')),
                            );
                          },
                          Colors.grey[200]!,
                          textColor: Colors.black87,
                        ),
                        
                        // Calendar
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: lightAccentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, color: accentColor),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Schedule',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, color: Colors.grey[300]),
                              // Calendar - full month view
                              SizedBox(
                                width: double.infinity,
                                child: TableCalendar(
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  calendarFormat: _calendarFormat,
                                  availableCalendarFormats: const {
                                    CalendarFormat.month: 'Month',
                                  },
                                  daysOfWeekHeight: 20,
                                  rowHeight: 38, // Smaller row height for better fit
                                  headerStyle: const HeaderStyle(
                                    formatButtonVisible: false,
                                    titleCentered: true,
                                    titleTextStyle: TextStyle(fontSize: 16),
                                    leftChevronIcon: Icon(Icons.chevron_left, size: 20),
                                    rightChevronIcon: Icon(Icons.chevron_right, size: 20),
                                    headerPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
                                    weekendStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    outsideDaysVisible: true,
                                    defaultTextStyle: const TextStyle(fontSize: 12),
                                    weekendTextStyle: TextStyle(fontSize: 12, color: Colors.red[300]),
                                    selectedDecoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    todayDecoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                    markersMaxCount: 1,
                                    cellMargin: const EdgeInsets.all(2),
                                    cellPadding: const EdgeInsets.all(0),
                                  ),
                                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF98C9C5), size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed, Color color, {Color textColor = Colors.white}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}