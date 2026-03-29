import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://buskirala.com/api/'; 

  // Standart E-posta ve Şifre ile Giriş
  Future<dynamic> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile-api.php'),
        body: {'action': 'login', 'email': email, 'password': password},
      );

      print("--- MANUEL GİRİŞ SUNUCU YANITI ---");
      print(response.body); 

      if (!response.body.trim().startsWith('{')) {
        return {'status': 'error', 'message': 'Sunucu JSON yerine HTML döndürdü. Terminali kontrol et!'};
      }

      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Hata oluştu: $e'};
    }
  }

  // Google ile Giriş (Yeni Eklenen Fonksiyon)
  Future<dynamic> googleLogin(String email, String googleId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mobile-api.php'),
        body: {
          'action': 'google_login', 
          'email': email, 
          'google_id': googleId
        },
      );

      print("--- GOOGLE GİRİŞ SUNUCU YANITI ---");
      print(response.body); 

      if (!response.body.trim().startsWith('{')) {
        return {'status': 'error', 'message': 'Google girişi sırasında sunucu hatası oluştu.'};
      }

      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Google bağlantı hatası: $e'};
    }
  }
}