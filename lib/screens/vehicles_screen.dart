import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  List<dynamic> list = [];
  bool isLoading = true;
  final String apiUrl = 'https://www.buskirala.com/wp-admin/admin-ajax.php';
  final String secret = 'BuskiralaApp2026';

  final List<String> types = [
    "Otomobil", "8 Kişilik Minibüs", "16 Kişilik Minibüs", "19 Kişilik Minibüs",
    "27 Kişilik Midibüs", "31 Kişilik Midibüs", "35 Kişilik Otobüs",
    "41 Kişilik Otobüs", "46 Kişilik Otobüs", "50 Kişilik Otobüs", "54 Kişilik Otobüs"
  ];
  final List<String> certs = ["A1", "A2", "B1", "B2", "D1", "D2"];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;
    try {
      final res = await http.post(Uri.parse(apiUrl), body: {
        'action': 'bk_mobile_api', 'secret': secret, 'email': user!.email!, 'command': 'get_vehicles',
      });
      if (res.statusCode == 200 && mounted) {
        setState(() {
          list = json.decode(res.body)['data'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showAddDialog() {
    final plate = TextEditingController();
    final city = TextEditingController();
    final year = TextEditingController();
    String selectedType = types[0];
    String selectedCert = certs[0];
    List<XFile> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Araç Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF333333))),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(color: Colors.grey, height: 24),
                    
                    // FORM ALANI
                    _webLabel('Plaka *'),
                    TextField(controller: plate, decoration: _webInputDec('34 ABC 123')),
                    const SizedBox(height: 16),
                    
                    _webLabel('Şehir *'),
                    TextField(controller: city, decoration: _webInputDec('İstanbul')),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _webLabel('Araç Tipi *'),
                              Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedType,
                                    items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 14)))).toList(),
                                    onChanged: (v) => setModalState(() => selectedType = v.toString()),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _webLabel('Model Yılı *'),
                              TextField(controller: year, keyboardType: TextInputType.number, decoration: _webInputDec('2024')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _webLabel('Yetki Belgesi *'),
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCert,
                          items: certs.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setModalState(() => selectedCert = v.toString()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // WEB TARZI DROPZONE (RESİM YÜKLEME ALANI)
                    _webLabel('Araç Görselleri (Maksimum 5)'),
                    GestureDetector(
                      onTap: () async {
                        final List<XFile> images = await picker.pickMultiImage();
                        if (images.isNotEmpty) {
                          setModalState(() {
                            selectedImages.addAll(images);
                            if (selectedImages.length > 5) selectedImages = selectedImages.sublist(0, 5);
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          border: Border.all(color: const Color(0xFFCED4DA), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF6C757D)),
                            SizedBox(height: 8),
                            Text('Görsel seçmek için tıklayın', style: TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text('PNG, JPG, JPEG', style: TextStyle(color: Color(0xFF6C757D), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    
                    // SEÇİLEN RESİMLERİN ÖNİZLEMESİ
                    if (selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedImages.map((img) {
                          return Stack(
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade300),
                                  image: DecorationImage(image: FileImage(File(img.path)), fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                right: 0, top: 0,
                                child: GestureDetector(
                                  onTap: () => setModalState(() => selectedImages.remove(img)),
                                  child: Container(
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                                  ),
                                ),
                              )
                            ],
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    // KAYDET BUTONU
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28A745),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        onPressed: () async {
                          if (plate.text.isEmpty || city.text.isEmpty || year.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen zorunlu alanları doldurun.')));
                            return;
                          }
                          final user = FirebaseAuth.instance.currentUser;
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(ctx);
                          messenger.showSnackBar(const SnackBar(content: Text('Araç sisteme yükleniyor...')));

                          try {
                            var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
                            request.fields['action'] = 'bk_mobile_api';
                            request.fields['secret'] = secret;
                            request.fields['email'] = user!.email!;
                            request.fields['command'] = 'add_vehicle';
                            request.fields['plate'] = plate.text;
                            request.fields['city'] = city.text;
                            request.fields['type'] = selectedType;
                            request.fields['year'] = year.text;
                            request.fields['cert'] = selectedCert;

                            for (var img in selectedImages) {
                              request.files.add(await http.MultipartFile.fromPath('vehicle_images[]', img.path));
                            }

                            var streamedResponse = await request.send();
                            var response = await http.Response.fromStream(streamedResponse);
                            
                            if (response.statusCode == 200 && mounted) {
                              messenger.showSnackBar(const SnackBar(content: Text('✅ Araç başarıyla eklendi.'), backgroundColor: Colors.green));
                              _fetch();
                            }
                          } catch (e) {
                            if (mounted) messenger.showSnackBar(const SnackBar(content: Text('❌ Yükleme hatası!'), backgroundColor: Colors.red));
                          }
                        },
                        child: const Text('KAYDET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await http.post(Uri.parse(apiUrl), body: {
        'action': 'bk_mobile_api', 'secret': secret, 'email': user!.email!, 'command': 'delete_vehicle', 'id': id,
      });
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('✅ Araç silindi.'), backgroundColor: Colors.green));
        _fetch();
      }
    } catch (e) {
      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('❌ Bağlantı hatası.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF007BFF)));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Web admin arkaplan rengi
      body: list.isEmpty 
          ? const Center(child: Text('Kayıtlı aracınız bulunmuyor.', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)))
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final v = list[i];
                  List<String> images = (v['vehicle_images']?.toString() ?? '').split(',').where((e) => e.isNotEmpty).toList();
                  final bool isApproved = v['is_approved'].toString() == "1";

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade300)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WEB TABLO BAŞLIĞI
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Color(0xFFDEE2E6))),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(v['plate'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF212529))),
                              Row(
                                children: [
                                  if (!isApproved)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFFFFC107), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('ONAY BEKLİYOR', style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: const Color(0xFF28A745), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('ONAYLI', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              )
                            ],
                          ),
                        ),
                        // WEB TABLO İÇERİĞİ
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoRow('Şehir', v['city']),
                              const Divider(color: Color(0xFFF8F9FA)),
                              _infoRow('Araç Tipi', v['vehicle_type']),
                              const Divider(color: Color(0xFFF8F9FA)),
                              _infoRow('Model Yılı', v['model_year']),
                              const Divider(color: Color(0xFFF8F9FA)),
                              _infoRow('Yetki Belgesi', v['auth_cert']),
                              
                              if (images.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                const Align(alignment: Alignment.centerLeft, child: Text('Araç Görselleri', style: TextStyle(fontSize: 14, color: Color(0xFF212529), fontWeight: FontWeight.bold))),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: images.length,
                                    itemBuilder: (context, imgIndex) => Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(4),
                                        image: DecorationImage(image: NetworkImage(images[imgIndex].trim()), fit: BoxFit.cover),
                                      ),
                                    ),
                                  ),
                                )
                              ],

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        title: const Text('Emin misiniz?'),
                                        content: Text('${v['plate']} plakalı aracı silmek üzeresiniz.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal', style: TextStyle(color: Colors.black54))),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC3545), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                                            onPressed: () { Navigator.pop(ctx); _delete(v['id'].toString()); }, 
                                            child: const Text('Sil', style: TextStyle(color: Colors.white))
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC3545)),
                                  label: const Text('Aracı Sil', style: TextStyle(color: Color(0xFFDC3545))),
                                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFDC3545)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF007BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Araç Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF6C757D), fontSize: 14, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF212529), fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _webLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF495057))));
  InputDecoration _webInputDec(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFADB5BD)), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: Colors.grey.shade400)));
}