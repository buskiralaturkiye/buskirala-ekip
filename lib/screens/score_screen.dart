import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});
  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen>
    with SingleTickerProviderStateMixin {
  int score = 0;
  bool loading = true;
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fetch();
  }

  Future<void> _fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    try {
      final res = await http.post(
        Uri.parse('https://www.buskirala.com/wp-admin/admin-ajax.php'),
        body: {
          'action': 'bk_mobile_api',
          'secret': 'BuskiralaApp2026',
          'email': user!.email!,
          'command': 'get_trust_score',
        },
      );
      if (mounted) {
        final fetchedScore =
            int.parse(json.decode(res.body)['data']['score'].toString());
        setState(() {
          score = fetchedScore;
          loading = false;
        });

        // Animasyonu puan değerine göre başlat
        _animation = Tween<double>(
          begin: 0,
          end: fetchedScore / 100,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut),
        );
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 80) return 'Mükemmel';
    if (score >= 60) return 'İyi';
    if (score >= 40) return 'Orta';
    return 'Düşük';
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF007BFF)),
      );
    }

    final color = _getScoreColor(score);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Animasyonlu yuvarlak puan göstergesi
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: _animation.value,
                        strokeWidth: 14,
                        color: color,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${((_animation.value) * 100).toInt()}',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Puan etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              _getScoreLabel(score),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'GÜVEN PUANINIZ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 32),

          // Bilgi kartı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Puanınızı Nasıl Artırırsınız?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Güven puanınızı artırmak iş alma oranınızı da artırır. Puanınızı yükseltmek için araç görsellerinizi yüklemeniz ve gerçekleşen seyahatlerden şikayet almamanız yeterlidir.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                _infoRow(Icons.photo_camera, 'Araç görsellerinizi yükleyin', color: Colors.green),
                const SizedBox(height: 8),
                _infoRow(Icons.thumb_up, 'Seyahatlerinizi şikayetsiz tamamlayın', color: Colors.green),
                const SizedBox(height: 8),
                _infoRow(Icons.verified, 'Profilinizi eksiksiz doldurun', color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color color = Colors.green}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}