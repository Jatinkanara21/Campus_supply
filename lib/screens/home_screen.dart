import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // ================= HEADER =================

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),

                child: Row(
                  children: [

                    Container(
                      width: 48,
                      height: 48,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 10,
                          ),
                        ],
                      ),

                      padding: const EdgeInsets.all(7),

                      child: Image.asset(
                        'assets/images/campus_supply.jpeg',
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            'CampusSupply',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF123A70),
                            ),
                          ),

                          Text(
                            'Student essentials',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      width: 45,
                      height: 45,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),

                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.notifications_none,
                          color: Color(0xFF123A70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= WELCOME =================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  15,
                  20,
                  0,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Hello, Student 👋',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'What do you need for your campus today?',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= SEARCH =================

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(16),

                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x10000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),

                      child: const TextField(
                        decoration: InputDecoration(
                          hintText:
                          'Search books, pens, bags...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF1769E0),
                          ),

                          suffixIcon: Icon(
                            Icons.tune,
                            color: Color(0xFF1769E0),
                          ),

                          border: InputBorder.none,

                          contentPadding:
                          EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= BANNER =================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1255C7),
                        Color(0xFF2186F3),
                      ],
                    ),

                    borderRadius:
                    BorderRadius.circular(24),

                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x301769E0),
                        blurRadius: 15,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            const Text(
                              'Everything you need',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Make your campus life easier with CampusSupply.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),

                            const SizedBox(height: 15),

                            ElevatedButton(
                              onPressed: () {},
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.white,
                                foregroundColor:
                                Color(0xFF1769E0),
                              ),

                              child: const Text(
                                'Explore Now',
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Icon(
                        Icons.school,
                        size: 75,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ================= CATEGORIES =================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 125,

                child: ListView(
                  scrollDirection: Axis.horizontal,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),

                  children: [

                    category(
                      Icons.edit,
                      'Pens',
                      const Color(0xFFE8F1FF),
                    ),

                    category(
                      Icons.menu_book,
                      'Books',
                      const Color(0xFFFFF0DD),
                    ),

                    category(
                      Icons.backpack,
                      'Bags',
                      const Color(0xFFE7F8EF),
                    ),

                    category(
                      Icons.calculate,
                      'Math',
                      const Color(0xFFF1E9FF),
                    ),

                    category(
                      Icons.palette,
                      'Art',
                      const Color(0xFFFFE8EF),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= POPULAR =================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [

                    const Text(
                      'Popular Items',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF102A43),
                      ),
                    ),

                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'See All',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Row(
                  children: [

                    product(
                      Icons.edit,
                      'Premium Pen',
                      'Smooth writing',
                    ),

                    const SizedBox(width: 14),

                    product(
                      Icons.menu_book,
                      'Notebook',
                      'A4 College Book',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= LOGIN CARD =================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(20),

                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),

                  child: Column(
                    children: [

                      const Icon(
                        Icons.account_circle_outlined,
                        size: 45,
                        color: Color(0xFF1769E0),
                      ),

                      const SizedBox(height: 10),

                      const Text(
                        'Join CampusSupply',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Create an account to get the full experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/login',
                                );
                              },

                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(
                                  0xFF1769E0,
                                ),
                                foregroundColor:
                                Colors.white,
                              ),

                              child: const Text(
                                'LOGIN',
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/register',
                                );
                              },

                              child: const Text(
                                'REGISTER',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ================= CATEGORY CARD =================

  Widget category(
      IconData icon,
      String title,
      Color background,
      ) {
    return Container(
      width: 105,

      margin: const EdgeInsets.only(right: 12),

      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Icon(
            icon,
            size: 35,
            color: const Color(0xFF1769E0),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================= PRODUCT CARD =================

  Widget product(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),

          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 10,
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Container(
              height: 90,
              width: double.infinity,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius:
                BorderRadius.circular(15),
              ),

              child: Icon(
                icon,
                size: 45,
                color: const Color(0xFF1769E0),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}