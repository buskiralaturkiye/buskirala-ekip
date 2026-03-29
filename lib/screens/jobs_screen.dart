import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  List<dynamic> jobs = [];
  bool isLoading = true;
  int _previousJobCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchJobs();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNewJobSound() async {
    await _audioPlayer.play(AssetSource('sounds/new_job.mp3'));
  }

  Future<void> fetchJobs() async {
    try {
      final response = await http.post(
        Uri.parse('https://www.buskirala.com/wp-admin/admin-ajax.php'),
        body: {'action': 'bk_get_open_tenders'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          final newJobs = data['data'] as List;
          final newCount = newJobs.length;

          if (!isLoading && newCount > _previousJobCount) {
            _playNewJobSound();
          }

          setState(() {
            jobs = newJobs;
            _previousJobCount = newCount;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String formatMoney(dynamic amount) {
    if (amount == null) return '';
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: 'TL', decimalDigits: 0);
    if (amount is String) {
      final parsed = double.tryParse(amount);
      return parsed != null ? formatter.format(parsed) : amount;
    } else if (amount is num) {
      return formatter.format(amount);
    }
    return amount.toString();
  }

  void _showBidModal(dynamic job) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Teklif Ver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${job['vehicle_type']} için teklif', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const Divider(height: 16),
                  const Text('Teklif Tutarı (TL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Örn: 5000',
                      filled: true,
                      fillColor: Colors.grey[100],
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Notunuz (Opsiyonel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Eklemek istedikleriniz...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('İPTAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2ECC71),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final amount = amountController.text;
                            if (amount.isEmpty) return;

                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null || user.email == null) return;

                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);

                            messenger.showSnackBar(const SnackBar(content: Text('Teklifiniz gönderiliyor...')));

                            try {
                              final response = await http.post(
                                Uri.parse('https://www.buskirala.com/wp-admin/admin-ajax.php'),
                                body: {
                                  'action': 'bk_mobile_api',
                                  'secret': 'BuskiralaApp2026',
                                  'email': user.email!,
                                  'command': 'submit_bid',
                                  'tender_id': job['id'].toString(),
                                  'amount': amount,
                                  'note': noteController.text,
                                },
                              );

                              if (response.statusCode == 200 && mounted) {
                                final result = json.decode(response.body);
                                if (result['success'] == true) {
                                  messenger.showSnackBar(SnackBar(content: Text('✅ ${result['data']}'), backgroundColor: Colors.green));
                                  setState(() => isLoading = true);
                                  fetchJobs();
                                } else {
                                  messenger.showSnackBar(SnackBar(content: Text('❌ Hata: ${result['data']}'), backgroundColor: Colors.red));
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                messenger.showSnackBar(const SnackBar(content: Text('❌ Bağlantı hatası!'), backgroundColor: Colors.red));
                              }
                            }
                          },
                          child: const Text('GÖNDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.orange))
        else if (jobs.isEmpty)
          RefreshIndicator(
            onRefresh: fetchJobs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - 200,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('📭', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 15),
                    Text('Şu an açık iş fırsatı yok.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
        else
          RefreshIndicator(
            onRefresh: fetchJobs,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 70, left: 16, right: 16, bottom: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                final bool isAssigned = job['card_status'] == 'assigned';
                final bool isClosed = job['is_closed'] == true || job['card_status'] == 'closed';
                final String priceStr = job['price'] ?? '';
                final double? minBidVal = job['min_bid'] != null ? double.tryParse(job['min_bid'].toString()) : null;

                Widget priceWidget = const SizedBox.shrink();
                if (minBidVal != null && minBidVal > 0) {
                  priceWidget = Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      border: Border.all(color: const Color(0xFFFFD591)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🔥 Son Alınan Teklif', style: TextStyle(color: Color(0xFFD46B08), fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(formatMoney(minBidVal), style: const TextStyle(color: Color(0xFFD4380D), fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  );
                } else if (priceStr.isNotEmpty) {
                  priceWidget = Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6FFFA),
                      border: Border.all(color: const Color(0xFFB2F5EA)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('💰 Tahmini Bütçe', style: TextStyle(color: Color(0xFF2C7A7B), fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(priceStr, style: const TextStyle(color: Color(0xFF285E61), fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('🚗 ${job['vehicle_type']} Aranıyor', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                            ),
                            if (isAssigned) _buildStatusBadge('TAMAMLANDI', Colors.green)
                            else if (isClosed) _buildStatusBadge('SÜRESİ DOLDU', Colors.red),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow('Güzergah', job['title'] ?? '-'),
                        _buildInfoRow('Başlangıç', job['start_time'] ?? '-'),
                        _buildInfoRow('Bitiş', job['end_time'] ?? '-'),
                        _buildInfoRow('Nereden', job['pickup']?.toString() ?? '-'),
                        _buildInfoRow('Nereye', job['dropoff']?.toString() ?? '-'),
                        _buildInfoRow('Mesafe', job['total_km']?.toString() ?? '-'),
                        _buildInfoRow('İş Detayı', job['job_type'] ?? '-', valueColor: Colors.deepOrange),
                        priceWidget,
                        if (job['note'] != null && job['note'].toString().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBE6),
                              border: const Border(left: BorderSide(color: Color(0xFFFFE58F), width: 3)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('📝 Not: ${job['note']}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                          ),
                        const SizedBox(height: 16),
                        if (isAssigned)
                          _buildAssigneeInfo(job['winner_name'] ?? '-')
                        else
                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isClosed ? Colors.grey : const Color(0xFF2ECC71),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: isClosed ? null : () => _showBidModal(job),
                                  child: Text(isClosed ? 'SÜRESİ DOLDU' : 'TEKLİF VER', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (!isClosed) Padding(padding: const EdgeInsets.only(top: 8), child: Text('📢 ${job['bid_count'] ?? 0} Teklif', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600))),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('GÜNCELLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                setState(() => isLoading = true);
                fetchJobs();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAssigneeInfo(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4EDDA),
        border: Border.all(color: const Color(0xFFC3E6CB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('✅ BU İŞ ONAYLANDI - Yüklenici: $name', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF155724), fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}