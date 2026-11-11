import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const OrionApp());

class OrionApp extends StatelessWidget {
  const OrionApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ORION AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF36B9E8), brightness: Brightness.dark),
      scaffoldBackgroundColor: const Color(0xFF080E18),
      useMaterial3: true,
    ),
    home: const OrionHome(),
  );
}

class OrionMessage {
  OrionMessage(this.text, this.fromUser, {DateTime? time}) : time = time ?? DateTime.now();
  final String text;
  final bool fromUser;
  final DateTime time;
  Map<String, Object?> toJson() => {'text': text, 'fromUser': fromUser, 'time': time.toIso8601String()};
  factory OrionMessage.fromJson(Map<String, Object?> json) => OrionMessage(
    json['text'] as String? ?? '',
    json['fromUser'] as bool? ?? false,
    time: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
  );
}

class OrionMemory {
  static const _key = 'orion.conversation.v1';
  Future<List<OrionMessage>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((line) {
      try { return OrionMessage.fromJson(Map<String, Object?>.from(Uri.splitQueryString(line))); }
      catch (_) { return OrionMessage(line, false); }
    }).toList();
  }
  Future<void> save(List<OrionMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, messages.map((m) =>
      'text=${Uri.encodeQueryComponent(m.text)}&fromUser=${m.fromUser}&time=${Uri.encodeQueryComponent(m.time.toIso8601String())}'
    ).toList());
  }
  Future<void> clear() async => (await SharedPreferences.getInstance()).remove(_key);
}

/// Safe offline baseline. This is deliberately not presented as a language model.
/// A real on-device model adapter will replace/extend this service in the next phase.
class OrionLocalEngine {
  String respond(String input) {
    final q = input.trim().toLowerCase();
    if (q.isEmpty) return 'فرمان خالی است. آماده دریافت دستور هستم.';
    if (q.contains('سلام') || q == 'hi' || q == 'hello') {
      return 'درود. ORION در حالت محلی فعال است. برای پردازش زبانی پیشرفته باید مدل محلی یا سرویس آنلاین پیکربندی شود.';
    }
    if (q.contains('وضعیت') || q.contains('status')) {
      return 'وضعیت هسته: فعال\nحافظه محلی: فعال\nمدل زبانی محلی: هنوز نصب نشده\nاتصال ابری: هنوز پیکربندی نشده';
    }
    if (q.contains('حافظه') || q.contains('memory')) {
      return 'گفت‌وگوها روی همین دستگاه ذخیره می‌شوند. اطلاعات حساس یا رمزهای عبور را وارد نکنید.';
    }
    return 'پیام دریافت شد. موتور پایه آفلاین هنوز مدل زبانی کامل ندارد؛ در این نسخه فقط فرمان‌های پایه و حافظه محلی فعال‌اند. در مرحله بعد، آداپتور مدل محلی و اتصال ابری امن اضافه می‌شوند.';
  }
}

class OrionHome extends StatefulWidget {
  const OrionHome({super.key});
  @override
  State<OrionHome> createState() => _OrionHomeState();
}

class _OrionHomeState extends State<OrionHome> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _memory = OrionMemory();
  final _local = OrionLocalEngine();
  final List<OrionMessage> _messages = [];
  bool _ready = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final saved = await _memory.load();
    if (!mounted) return;
    setState(() {
      _messages.addAll(saved);
      if (_messages.isEmpty) {
        _messages.add(OrionMessage('سامانه ORION راه‌اندازی شد. هسته محلی آماده است؛ مدل زبانی کامل هنوز نصب نشده است.', false));
      }
      _ready = true;
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _busy = true;
      _messages.add(OrionMessage(text, true));
    });
    final answer = _local.respond(text);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() {
      _messages.add(OrionMessage(answer, false));
      _busy = false;
    });
    await _memory.save(_messages);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  Future<void> _clear() async {
    await _memory.clear();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(OrionMessage('حافظه گفت‌وگو پاک شد. این عملیات فقط پیام‌های ذخیره‌شده داخل ORION را حذف می‌کند.', false));
    });
    await _memory.save(_messages);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [
        Icon(Icons.hub_outlined, color: Color(0xFF54D5FF)),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ORION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
          Text('PERSONAL INTELLIGENCE', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Colors.white54)),
        ]),
      ]),
      actions: [
        IconButton(tooltip: 'پاک‌کردن گفت‌وگو', onPressed: _clear, icon: const Icon(Icons.delete_outline)),
      ],
    ),
    body: SafeArea(child: Column(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10283A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1B6685)),
        ),
        child: const Row(children: [
          Icon(Icons.offline_bolt, color: Color(0xFF54D5FF)),
          SizedBox(width: 10),
          Expanded(child: Text('LOCAL BASELINE • آفلاین | موتور مدل زبانی هنوز نصب نشده', style: TextStyle(fontSize: 11))),
        ]),
      ),
      Expanded(child: !_ready ? const Center(child: CircularProgressIndicator()) : ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final m = _messages[index];
          return Align(
            alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: m.fromUser ? const Color(0xFF164A65) : const Color(0xFF172130),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: m.fromUser ? const Color(0xFF237A9E) : const Color(0xFF29384B)),
              ),
              child: Text(m.text, textDirection: TextDirection.rtl, style: const TextStyle(height: 1.5)),
            ),
          );
        },
      )),
      if (_busy) const LinearProgressIndicator(minHeight: 2),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 4,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'فرمان خود را وارد کن...',
              filled: true,
              fillColor: const Color(0xFF121D2B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            onSubmitted: (_) => _send(),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.arrow_upward),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFF087EA4), foregroundColor: Colors.white),
          ),
        ]),
      ),
    ])),
  );
}
