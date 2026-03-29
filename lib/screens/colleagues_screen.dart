import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ColleaguesScreen extends StatefulWidget {
  const ColleaguesScreen({super.key});

  @override
  State<ColleaguesScreen> createState() => _ColleaguesScreenState();
}

class _ColleaguesScreenState extends State<ColleaguesScreen> {
  List<dynamic> list = [];
  bool loading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  int currentPage = 1;

  final String apiUrl = 'https://www.buskirala.com/wp-admin/admin-ajax.php';
  final String secret = 'BuskiralaApp2026';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() => isLoadingMore = true);
      currentPage++;
    } else {
      setState(() {
        loading = true;
        currentPage = 1;
        hasMore = true;
        list.clear();
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    try {
      final res = await http.post(Uri.parse(apiUrl), body: {
        'action': 'bk_mobile_api', 
        'secret': secret, 
        'email': user!.email!, 
        'command': 'get_colleagues',
        'page': currentPage.toString(),
      });

      if (res.statusCode == 200 && mounted) {
        final newData = json.decode(res.body)['data'] ?? [];
        
        setState(() {
          if (isLoadMore) {
            list.addAll(newData);
            isLoadingMore = false;
          } else {
            list = newData;
            loading = false;
          }
          // Eğer gelen veri 20'den azsa, demek ki gösterilecek başka kimse kalmadı
          if (newData.length < 20) {
            hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF007BFF)));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Web admin arkaplan rengi
      body: list.isEmpty 
          ? const Center(child: Text('Kayıtlı meslektaş bulunmuyor.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)))
          : RefreshIndicator(
              onRefresh: () => _fetch(isLoadMore: false),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length + (hasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  // Eğer listenin sonuna geldiysek "Devamını Yükle" butonunu göster
                  if (i == list.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: isLoadingMore 
                            ? const CircularProgressIndicator(color: Color(0xFF007BFF))
                            : OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                  side: const BorderSide(color: Color(0xFF007BFF)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                                onPressed: () => _fetch(isLoadMore: true),
                                child: const Text('Devamını Yükle', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold)),
                              ),
                      ),
                    );
                  }

                  final item = list[i];
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4), 
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56, 
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9ECEF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.person, color: Color(0xFF6C757D), size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? 'İsimsiz Kullanıcı', 
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF212529)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Color(0xFF6C757D)),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['city'] ?? 'Belirtilmemiş', 
                                          style: const TextStyle(color: Color(0xFF6C757D), fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  border: Border.all(color: const Color(0xFF28A745)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  children: [
                                    const Text('PUAN', style: TextStyle(fontSize: 10, color: Color(0xFF28A745), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['score']}', 
                                      style: const TextStyle(fontSize: 18, color: Color(0xFF28A745), fontWeight: FontWeight.w900)
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFDEE2E6)),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            onPressed: () {
                              final phone = item['phone'].toString().replaceAll(RegExp(r'[^0-9]'), '');
                              launchUrl(Uri.parse("https://wa.me/90$phone"));
                            },
                            icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                            label: const Text('WhatsApp ile Mesaj Gönder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}