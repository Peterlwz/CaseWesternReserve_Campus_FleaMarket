import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart'; // ✅ 新增：去掉 # 号
import 'package:url_launcher/url_launcher.dart';
import 'pages/auth_page.dart';
import 'pages/post_page.dart';
import 'pages/verify_success.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ 让 Flutter Web 使用干净路径（去掉 #）
  usePathUrlStrategy();

  await dotenv.load(fileName: "assets/.env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CWRUFleaMarketApp());
}

class CWRUFleaMarketApp extends StatelessWidget {
  const CWRUFleaMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CWRU Flea Market',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Arial',
      ),
      // ✅ 根路径 “/” 即为主页，不再是 /main
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(), // 👈 直接改成根路径
        '/auth': (context) => const Auth(initialLogin: true),
        '/post': (context) => const PostPage(),
        '/verify-success': (context) => const VerifySuccessPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];

  // 👇 新增：当前登录用户名（abc123）
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCurrentUser(); // 如果已经登录了，进来就显示用户名
  }

  // 如果当前已有 session，就把邮箱前缀取出来
  void _loadCurrentUser() {
    final user = supabase.auth.currentUser;
    if (user != null && user.email != null) {
      setState(() {
        _username = user.email!.split('@').first;
      });
    }
  }

  /// 从 Supabase 获取商品数据
  Future<void> _loadItems() async {
    try {
      final data = await supabase
          .from('items')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _items = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint('Error loading items: $e');
    }
  }

  /// 跳转到发布页面
  Future<void> _navigateToPostPage() async {
    final result = await Navigator.pushNamed(context, '/post');
    // ✅ 如果发布成功，刷新主页
    if (result == true) {
      _loadItems(); // 发布后刷新主页
    }
  }

  /// 👇 单独写一个去登录页的方法，这样能拿到返回的 username
  Future<void> _openAuthPage() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const Auth(initialLogin: true)),
    );

    // 如果登录页返回了用户名，就存起来
    if (result != null && result.isNotEmpty) {
      setState(() {
        _username = result;
      });
    }
  }

  /// 打开 GitHub
  Future<void> _launchGitHub() async {
    final Uri url = Uri.parse('https://github.com/Peterlwz');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
      // --- Top Bar ---
      Container(
        color: const Color(0xFF1A2C63),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 👇 如果用户已登录，显示邮箱 + Log Out
            if (_username != null) ...[
              Text(
                '$_username@case.edu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  decoration: TextDecoration.underline, // 加下划线
                  decorationColor: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () async {
                  await supabase.auth.signOut(); // 🔥 退出登录
                  setState(() {
                    _username = null; // 清空用户名
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have been logged out.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 24), // 留点空间再放 GitHub
            ],

            // 👇 GitHub 按钮保持不变
            TextButton.icon(
              onPressed: _launchGitHub,
              icon: const Icon(Icons.code, color: Colors.white),
              label: const Text(
                'GitHub',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),


            // --- Hero Section ---
            Container(
              color: const Color(0xFF1A2C63),
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discover & Share',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The best marketplace for CWRU students — buy, sell, and share safely.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _openAuthPage, // 👈 这里改成用我们写的函数
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: _navigateToPostPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Post an Item'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  SizedBox(
                    width: 400,
                    child: Image.asset(
                      'assets/images/student_laptop.png',
                      height: 400,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText:
                              'Search for items... (e.g., textbooks, bikes, laptops)',
                          hintStyle: TextStyle(fontSize: 16),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search, size: 32),
                    ),
                  ],
                ),
              ),
            ),

            // --- Popular Categories ---
            const SectionTitle(title: 'Popular Categories'),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 30,
              runSpacing: 20,
              children: const [
                CategoryCard(icon: Icons.menu_book, label: 'Textbooks'),
                CategoryCard(icon: Icons.computer, label: 'Electronics'),
                CategoryCard(icon: Icons.chair, label: 'Furniture'),
                CategoryCard(icon: Icons.directions_bike, label: 'Bikes & Sports'),
              ],
            ),

            const SizedBox(height: 40),

            // --- Latest Listings ---
            const SectionTitle(title: 'Latest Listings'),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No items yet — be the first to post!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            else
              Column(
                children: _items.map((item) {
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 3,
                    child: ListTile(
                      leading: item['image_url'] != null &&
                              (item['image_url'] as String).isNotEmpty
                          ? Image.network(
                              item['image_url'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.image,
                              size: 60, color: Colors.grey),
                      title: Text(item['description'] ?? 'No description'),
                      subtitle: Text(
                        '\$${item['price'] ?? ''} • ${item['category'] ?? ''}',
                      ),
                      trailing: Text(
                        item['phone'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- Section Title ---
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// --- Category Card ---
class CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const CategoryCard({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: Colors.indigo),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
