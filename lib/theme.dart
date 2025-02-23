import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.red.shade500,
      scaffoldBackgroundColor: Colors.transparent, // Set transparent so we can apply gradient manually
      textTheme: TextTheme(
        titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // 🌟 Gradient AppBar Theme
  static PreferredSizeWidget gradientAppBar(String title) {
    return AppBar(
      title: Text(title, style: TextStyle(color: Colors.white)),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.red.shade900,
              Colors.red.shade900,
              Colors.red.shade900,
              Colors.red.shade900,
            ],
            stops: [0.01, 0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  /// **🌟 Gradient AppBar with Icon**
  static PreferredSizeWidget gradientAppBarWithIcon(
      String title, IconData icon, Color iconColor, VoidCallback onPressed) {
    return AppBar(
      title: Text(title, style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Icon(icon, color: iconColor),
          onPressed: onPressed,
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.red.shade900,
              Colors.red.shade900,
              Colors.red.shade900,
            ],
            stops: [0.01, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  /// 🌟 Gradient AppBar for User with Notifications
  static PreferredSizeWidget gradientUserAppBarWithNotification({
    required String title,
    required bool hasNewNotification,
    required VoidCallback onNotificationPressed,
  }) {
    return AppBar(
      title: Text(title, style: TextStyle(color: Colors.white)),
      actions: [
        IconButton(
          icon: Stack(
            children: [
              Icon(Icons.notifications, color: Colors.white),
              if (hasNewNotification)
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: onNotificationPressed,
        ),
      ],
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.5,
            colors: [
              Colors.red.shade900,
              Colors.red.shade900,
              Colors.red.shade900,
            ],
            stops: [0.01, 0.4, 1.0],
          ),
        ),
      ),
    );
  }


  // 🔴 Gradient Background
  static BoxDecoration get gradientBackground {
    return BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          Colors.red.shade600,
          Colors.red.shade700,
          Colors.red.shade800,
          Colors.red.shade900,
        ],
        stops: [0.01, 0.4, 0.7, 1.0],
      ),
    );
  }

  // 🌟 Card Theme
  static CardTheme cardTheme() {
    return CardTheme(
      elevation: 4,
      color: Colors.grey.shade300.withOpacity(0.5),
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  // 🌟 Text Style for Card Title
  static TextStyle cardTitleTextStyle() {
    return TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      shadows: [
        Shadow(
          offset: Offset(1.5, 1.5),
          blurRadius: 5.0,
          color: Colors.black.withOpacity(0.7),
        ),
      ],
    );
  }

  // 🌟 Text Style for Card Description
  static TextStyle cardDescriptionTextStyle() {
    return TextStyle(
      fontSize: 14,
      color: Colors.grey[300],
      shadows: [
        Shadow(
          offset: Offset(1.5, 1.5),
          blurRadius: 7.0,
          color: Colors.black,
        ),
      ],
    );
  }

  // 🌟 Text Style for Full Description
  static TextStyle fullDescriptionTextStyle() {
    return TextStyle(
      fontSize: 14,
      color: Colors.grey[350],
      shadows: [
        Shadow(
          offset: Offset(0.5, 1.5),
          blurRadius: 7.0,
          color: Colors.black,
        ),
      ],
    );
  }

  // 🌟 Price Range Text Style
  static TextStyle priceRangeTextStyle() {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.green,
      shadows: [
        Shadow(
          offset: Offset(0.1, 0.1),
          blurRadius: 9.0,
          color: Colors.black.withOpacity(0.7),
        ),
      ],
    );
  }

  // 🌟 Button Styles for Card Buttons (Book Button)
  static ButtonStyle cardButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Color(0xFFF8CB20),  // Button background color
      elevation: 5,
      shadowColor: Colors.black.withOpacity(0.7),
    );
  }

  // 🌟 Button Styles for TextButton (Less/More)
  static ButtonStyle cardTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: Colors.white,  // Text color for the button
      shadowColor: Colors.black.withOpacity(0.7),
    );
  }

  // 🌸 Floating Icons Decoration
  static List<Widget> floatingIcons(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return [
      Positioned(
        top: screenHeight * 0.05,
        left: screenWidth * 0.08,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.17),
        ),
      ),
      Positioned(
        top: screenHeight * 0.10,
        right: screenWidth * 0.12,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.10),
        ),
      ),
      Positioned(
        top: screenHeight * 0.22,
        left: screenWidth * 0.25,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.08),
        ),
      ),
      Positioned(
        top: screenHeight * 0.25,
        right: screenWidth * 0.15,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.local_florist_sharp, color: Colors.red.shade200, size: screenWidth * 0.19),
        ),
      ),
      Positioned(
        bottom: screenHeight * 0.12,
        left: screenWidth * 0.35,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.20),
        ),
      ),
      Positioned(
        bottom: screenHeight * 0.12,
        right: screenWidth * 0.10,
        child: Opacity(
          opacity: 0.5, // Set your desired opacity value (0.0 - 1.0)
          child: Icon(
            Icons.eco,
            color: Colors.red.shade200,
            size: screenWidth * 0.08,
          ),
        ),
      ),
      Positioned(
        bottom: screenHeight * 0.25,
        left: screenWidth * 0.05,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.07),
        ),
      ),
      Positioned(
        bottom: screenHeight * 0.27,
        right: screenWidth * 0.10,
        child: Opacity(opacity: 0.5,
          child: Icon(Icons.local_florist, color: Colors.red.shade200, size: screenWidth * 0.2),
        ),
      ),
      Positioned(
        top: screenHeight * 0.40,
        left: screenWidth * 0.50,
        child: Opacity(
          opacity: 0.5,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.09),
        ),
      ),
      Positioned(
        bottom: screenHeight * 0.40,
        left: screenWidth * 0.150,
        child: Opacity(
          opacity: 0.5,
          child: Icon(Icons.eco, color: Colors.red.shade200, size: screenWidth * 0.25),
        ),
      ),
    ];
  }
}
