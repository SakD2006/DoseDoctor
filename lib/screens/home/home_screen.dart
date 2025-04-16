import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../patient/scan_patient_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String doctorName;
  final String doctorId;

  const HomeScreen({Key? key, required this.doctorName, required this.doctorId})
    : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _selectedIndex = 0;
  late String _currentTime;
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _updateDateTime();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('hh:mm a').format(now);
    _currentDate = DateFormat('EEEE, MMMM d, yyyy').format(now);

    // Update time every minute
    Future.delayed(Duration(minutes: 1)).then((_) {
      if (mounted) {
        setState(() {
          _updateDateTime();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 220, 255, 228),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildBody(context),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animationController.value * 10 - 5),
            child: FloatingActionButton.extended(
              elevation: 4,
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            QrScannerScreen(doctorName: widget.doctorName),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text(
                'Scan Patient',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.blueGrey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, ${widget.doctorName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 156, 88),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currentTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${widget.doctorId.substring(0, 8)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () async {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content: const Text(
                            'Are you sure you want to sign out?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text('SIGN OUT'),
                            ),
                          ],
                        ),
                  );
                },
                child: CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: const Icon(Icons.person, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Stats Cards
        _buildQuickStats(),
        const SizedBox(height: 24),

        // Today's Appointments Section
        _buildSectionHeader('Today\'s Appointments'),
        _buildAppointmentsList(),
        const SizedBox(height: 24),

        // Recent Activities Section
        _buildSectionHeader('Recent Activities'),
        _buildRecentActivities(),
        const SizedBox(height: 24),

        // Quick Actions Section
        _buildSectionHeader('Quick Actions'),
        _buildQuickActions(context),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '8',
                  'Appointments',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '3',
                  'Pending',
                  Icons.access_time,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '12',
                  'Patients',
                  Icons.person,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildAppointmentsList() {
    final appointments = [
      {
        'time': '09:00 AM',
        'patient': 'Saksham Dubey',
        'reason': 'Annual Check-up',
        'status': 'Confirmed',
      },
      {
        'time': '10:30 AM',
        'patient': 'Prakyath Tejsundar',
        'reason': 'Follow-up',
        'status': 'In Progress',
      },
      {
        'time': '02:15 PM',
        'patient': 'Aryaman Sodha',
        'reason': 'Consultation',
        'status': 'Waiting',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: appointments.length,
        separatorBuilder:
            (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          Color statusColor;

          switch (appointment['status']) {
            case 'Confirmed':
              statusColor = Colors.green;
              break;
            case 'In Progress':
              statusColor = Colors.blue;
              break;
            default:
              statusColor = Colors.orange;
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                appointment['patient']!.split(' ').map((e) => e[0]).join(''),
                style: const TextStyle(color: Colors.blueAccent),
              ),
            ),
            title: Text(
              appointment['patient']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(appointment['reason']!),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      appointment['time']!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                appointment['status']!,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onTap: () {
              // Handle appointment tap
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {
        'time': '11:45 AM',
        'description': 'Updated medical records for Saksham Dubey',
        'icon': Icons.edit_document,
      },
      {
        'time': 'Yesterday',
        'description': 'Sent prescription to Aryaman Sodha',
        'icon': Icons.medical_services,
      },
      {
        'time': 'Yesterday',
        'description': 'Scheduled follow-up with Prakyath Tejsundar',
        'icon': Icons.calendar_month,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: activities.length,
        separatorBuilder:
            (context, index) => Divider(height: 1, color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final activity = activities[index];

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Icon(
                activity['icon'] as IconData,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
            title: Text(activity['description'] as String),
            trailing: Text(
              activity['time'] as String,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.qr_code_scanner,
        'label': 'Scan Patient',
        'color': Colors.blue,
      },
      {'icon': Icons.note_add, 'label': 'New Record', 'color': Colors.green},
      {
        'icon': Icons.calendar_month,
        'label': 'Schedule',
        'color': Colors.orange,
      },
      {'icon': Icons.message, 'label': 'Messages', 'color': Colors.purple},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children:
          actions.map((action) {
            return InkWell(
              onTap: () {
                if (action['label'] == 'Scan Patient') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              QrScannerScreen(doctorName: widget.doctorName),
                    ),
                  );
                }
                // Handle other actions
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 48) / 2,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (action['color'] as Color).withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: (action['color'] as Color).withOpacity(
                        0.1,
                      ),
                      radius: 24,
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      action['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
