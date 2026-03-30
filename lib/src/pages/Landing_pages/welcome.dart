
import 'package:flutter/material.dart';

import 'buyer_pages/buyer_login.dart';
import 'farmer_pages/Farmer_login.dart';

class welcome extends StatefulWidget {
  const welcome({super.key});

  @override
  State<welcome> createState() => _welcomeState();
}

class _welcomeState extends State<welcome> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      body: Stack(
        children: [
          // Decorative background blobs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF337233).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF337233).withOpacity(0.06),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),

                        // Logo / Hero image
                        Container(
                          height: size.width * 0.72,
                          width: size.width * 0.72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF337233).withOpacity(0.15),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                            image: const DecorationImage(
                              image: AssetImage("assets/images/main.jpg"),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // App name
                        const Text(
                          "FarmMate",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF337233),
                            fontFamily: 'Poppins-SemiBold',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "From Farm to Business",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins-SemiBold',
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Text(
                          "Sell Smarter, Grow Bigger!",
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                            fontFamily: 'Poppins-SemiBold',
                          ),
                        ),

                        const SizedBox(height: 48),

                        // Farmer button
                        _RoleButton(
                          label: "I'm a Farmer",
                          subtitle: "List and manage your crops",
                          icon: Icons.agriculture_rounded,
                          color: const Color(0xFF337233),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FarmerLogin()),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Buyer button
                        _RoleButton(
                          label: "I'm a Buyer",
                          subtitle: "Browse & buy fresh produce",
                          icon: Icons.shopping_basket_rounded,
                          color: const Color(0xFF1A5276),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BuyerLogin()),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontFamily: 'Poppins-SemiBold',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.8), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}