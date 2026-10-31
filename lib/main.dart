import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'aLS Sniper',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        primaryColor: const Color(0xFF00FFCC),
      ),
      home: const SniperApp(),
    );
  }
}

class SniperApp extends StatefulWidget {
  const SniperApp({Key? key}) : super(key: key);

  @override
  State<SniperApp> createState() => _SniperAppState();
}

class _SniperAppState extends State<SniperApp> {
  late final WebViewController _controller;
  final TextEditingController _targetController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: "10");
  
  String _status = "جاهز. سجل دخولك أولاً.";
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse('https://www.instagram.com/'));
  }

  // دالة حقن الجافاسكربت للقيام بالبلاغات
  Future<void> _startReporting() async {
    final target = _targetController.text.trim().replaceAll('@', '');
    final count = int.tryParse(_countController.text) ?? 10;

    if (target.isEmpty) {
      setState(() => _status = "❌ الرجاء كتابة اسم الهدف");
      return;
    }

    setState(() {
      _isReporting = true;
      _status = "⏳ جاري الانتقال لحساب @$target...";
    });

    // 1. الانتقال لصفحة الهدف
    await _controller.loadRequest(Uri.parse('https://www.instagram.com/$target/'));

    // ننتظر 4 ثواني حتى تفتح الصفحة
    await Future.delayed(const Duration(seconds: 4));

    setState(() => _status = "🎯 بدء القنص ($count بلاغ)...");

    // 2. حلقة التكرار للبلاغات
    for (int i = 1; i <= count; i++) {
      if (!_isReporting) break;
      
      setState(() => _status = "💥 إرسال البلاغ $i من $count...");

      // سكربت جافاسكربت يضغط على زر الخيارات (الثلاث نقاط) ويبلغ
      String jsCode = """
        (function() {
          // البحث عن زر الخيارات (الثلاث نقاط)
          let optionsBtn = document.querySelector('svg[aria-label="Options"]');
          if (optionsBtn) {
            optionsBtn.closest('button').click();
            setTimeout(() => {
              // البحث عن زر Report
              let buttons = Array.from(document.querySelectorAll('button, div[role="button"]'));
              let reportBtn = buttons.find(b => b.innerText === 'Report' || b.innerText.includes('Report'));
              if (reportBtn) {
                reportBtn.click();
                setTimeout(() => {
                  // اختيار Spam
                  let spamBtn = Array.from(document.querySelectorAll('button, div[role="button"]')).find(b => b.innerText.includes('Spam') || b.innerText.includes('Something about'));
                  if (spamBtn) {
                    spamBtn.click();
                    setTimeout(() => {
                      let submitBtn = Array.from(document.querySelectorAll('button, div[role="button"]')).find(b => b.innerText === 'Submit' || b.innerText === 'Done');
                      if (submitBtn) submitBtn.click();
                    }, 1500);
                  }
                }, 1500);
              }
            }, 1000);
            return true;
          }
          return false;
        })();
      """;

      try {
        await _controller.runJavaScript(jsCode);
      } catch (e) {
        debugPrint("JS Error: \$e");
      }

      // الانتظار 20 ثانية قبل البلاغ التالي (عشان الحماية)
      for (int sec = 20; sec > 0; sec--) {
        if (!_isReporting) break;
        setState(() => _status = "⏳ انتظار (\$sec ثانية) قبل البلاغ التالي...");
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    setState(() {
      _isReporting = false;
      _status = "✅ انتهت العملية. راجع الحساب.";
    });
  }

  void _stopReporting() {
    setState(() {
      _isReporting = false;
      _status = "🛑 تم إيقاف القنص.";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("👻 aLS Sniper"),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: const Color(0xFF00FFCC),
      ),
      body: Column(
        children: [
          // لوحة التحكم
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1A1A2E),
            child: Column(
              children: [
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(
                    labelText: "اسم حساب الهدف (بدون @)",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "عدد البلاغات",
                    border: OutlineInputBorder(),
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  _status,
                  style: const TextStyle(color: Color(0xFF00FFCC), fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isReporting ? null : _startReporting,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text("🎯 ابدأ القنص"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isReporting ? _stopReporting : null,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                        child: const Text("🛑 إيقاف"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // المتصفح (WebView)
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
