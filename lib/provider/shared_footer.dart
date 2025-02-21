import 'package:flutter/material.dart';
import 'package:online_service_booking/provider/home_page.dart';
import 'package:online_service_booking/provider/profile_page.dart';
import 'package:online_service_booking/provider/bookings_page.dart';

class SharedFooter extends StatelessWidget {
  final String providerId;
  final int currentIndex;

  const SharedFooter({super.key, required this.providerId, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      backgroundColor: Colors.red.shade900,
      selectedItemColor: const Color(0xFFF8CB20),
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
        ),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceProviderHomePage(providerId: providerId),
            ),
          );
        }
        if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceProviderProfile(providerId: providerId),
            ),
          );
        }
        if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderBookingsPage(providerId: providerId),
            ),
          );
        }
      },
    );
  }
}
