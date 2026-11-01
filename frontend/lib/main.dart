import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

const String apiBase = 'http://127.0.0.1:8000';
const String kAppName = 'SiebenKI'; // ganti sesuka kamu

const kTeal = Color(0xFF1F6B66);
const kDeep = Color(0xFF14504C);
const kBg = Color(0xFFFAF6F0);
const kSoft = Color(0xFFF1ECE4);
const kBorder = Color(0xFFE8E2D8);

class HairInfo {
  final String name;
  final String walker;
  final String title;
  final String desc;
  const HairInfo(this.name, this.walker, this.title, this.desc);
}

const Map<String, HairInfo> hairInfo = {
  'straight': HairInfo(
    'Lurus (Straight)',
    'Tipe 1',
    'Tipe 1: Lurus (Straight Hair)',
    'Helai rambut jatuh lurus tanpa pola lengkung berarti. Minyak alami mudah turun dari kulit kepala ke ujung, sehingga akar cepat terlihat berminyak.',
  ),
  'wavy': HairInfo(
    'Bergelombang (Wavy)',
    'Tipe 2',
    'Tipe 2: Bergelombang (Wavy Hair)',
    'Membentuk pola gelombang longgar seperti huruf S. Rambut mudah mengembang (frizz) dan pola gelombangnya gampang rusak oleh gesekan.',
  ),
  'curly': HairInfo(
    'Keriting (Curly)',
    'Tipe 3',
    'Tipe 3: Keriting (Curly Hair)',
    'Bentuk ikal berpegas dengan pola S yang tegas. Minyak alami sulit turun sampai ke ujung, sehingga ujung rambut cenderung kering.',
  ),
  'kinky': HairInfo(
    'Kinky (Coily)',
    'Tipe 4',
    'Tipe 4: Kinky / Coily',
    'Pola gulungan sangat rapat dan kecil seperti pegas atau zig-zag. Rambut ini paling mudah kering dan patah, sehingga butuh pelembap berlapis dan penanganan yang lembut.',
  ),
};

void main() => runApp(const HairApp());

class HairApp extends StatelessWidget {
  const HairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal).copyWith(primary: kTeal),
        scaffoldBackgroundColor: kBg,
      ),
      home: const HomePage(),
    );
  }
}

// ---------------- latar belakang dekoratif ----------------

class _Background extends StatelessWidget {
  const _Background();

  Widget _blob(double size, Color c) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [c, c.withAlpha(0)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(top: -160, left: -160, child: _blob(460, kTeal.withAlpha(60))),
          Positioned(
              top: 280,
              right: -200,
              child: _blob(520, const Color(0xFFF0C987).withAlpha(90))),
          Positioned(bottom: -200, left: -140, child: _blob(500, kTeal.withAlpha(45))),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const scalpOptions = ['Normal', 'Berminyak', 'Kering'];
  static const conditionOptions = [
    'Normal',
    'Rusak/bercabang',
    'Diwarnai/proses kimia'
  ];
  static const complaintOptions = [
    'Frizz',
    'Rontok',
    'Ketombe',
    'Kusam',
    'Kering/mudah patah'
  ];

  final ScrollController _scroll = ScrollController();
  final GlobalKey _howKey = GlobalKey();
  final GlobalKey _typesKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  Uint8List? _bytes;
  String _name = '';
  bool _loading = false;
  bool _dragging = false;
  String? _error;
  Map<String, dynamic>? _result;

  String _scalp = 'Normal';
  String _condition = 'Normal';
  final Set<String> _complaints = {};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ---------------- logic ----------------

  void _setImage(Uint8List b, String name) {
    final n = name.toLowerCase();
    final hasExt = n.contains('.');
    final okExt = !hasExt ||
        n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.webp');
    setState(() {
      _result = null;
      if (!okExt) {
        _error = 'Format tidak didukung. Gunakan JPG, PNG, atau WEBP.';
        return;
      }
      if (b.length > 10 * 1024 * 1024) {
        _error = 'Ukuran file melebihi 10MB.';
        return;
      }
      _bytes = b;
      _name = name;
      _error = null;
    });
  }

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src);
    if (x == null) return;
    _setImage(await x.readAsBytes(), x.name);
  }

  Future<void> _takePhoto() async {
    final p = Theme.of(context).platform;
    final isMobile = p == TargetPlatform.android || p == TargetPlatform.iOS;
    if (isMobile) {
      await _pick(ImageSource.camera); // HP: kamera bawaan
      return;
    }
    // Laptop/PC: webcam lewat dialog
    final shot = await showDialog<XFile>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const WebcamDialog(),
    );
    if (shot == null) return;
    _setImage(
        await shot.readAsBytes(), shot.name.isEmpty ? 'webcam.jpg' : shot.name);
  }

  MediaType _mime(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.png')) return MediaType('image', 'png');
    if (n.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  Future<void> _predict() async {
    if (_bytes == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$apiBase/predict'));
      req.fields['scalp'] = _scalp;
      req.fields['condition'] = _condition;
      req.fields['complaints'] = _complaints.join(',');
      req.files.add(http.MultipartFile.fromBytes(
        'file',
        _bytes!,
        filename: _name.isEmpty ? 'foto.jpg' : _name,
        contentType: _mime(_name),
      ));
      final streamed = await req.send().timeout(const Duration(seconds: 90));
      final resp = await http.Response.fromStream(streamed);
      final body = utf8.decode(resp.bodyBytes);
      if (resp.statusCode == 200) {
        setState(() => _result = jsonDecode(body) as Map<String, dynamic>);
        if (_scroll.hasClients) _scroll.jumpTo(0);
      } else {
        String msg = 'Server error ${resp.statusCode}';
        try {
          msg = jsonDecode(body)['detail'].toString();
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error =
          'Gagal terhubung ke server. Pastikan backend jalan di $apiBase');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _bytes = null;
      _name = '';
      _error = null;
    });
  }

  void _goHome() {
    if (_result != null) _reset();
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void _scrollTo(GlobalKey k) {
    final ctx = k.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  Future<void> _copy(Map<String, dynamic> r) async {
    final label = r['label'] as String;
    final info = hairInfo[label];
    final conf = (r['confidence'] as num).toDouble();
    final recs = (r['recommendations'] as List).cast<Map<String, dynamic>>();
    final inputs = r['inputs'] as Map<String, dynamic>;
    final complaints = (inputs['complaints'] as List).cast<String>();

    final b = StringBuffer()
      ..writeln('HASIL KLASIFIKASI JENIS RAMBUT')
      ..writeln('Jenis rambut : ${info?.title ?? label}')
      ..writeln('Keyakinan    : ${(conf * 100).toStringAsFixed(1)}%')
      ..writeln('Kulit kepala : ${inputs['scalp']}')
      ..writeln('Kondisi      : ${inputs['condition']}')
      ..writeln('Keluhan      : ${complaints.isEmpty ? '-' : complaints.join(', ')}')
      ..writeln();
    if (recs.isEmpty) {
      b.writeln('Rekomendasi: tidak ditampilkan (model kurang yakin).');
    } else {
      b.writeln('PANDUAN PERAWATAN');
      for (final rec in recs) {
        b.writeln('- ${rec['title']}: ${rec['text']}');
      }
    }
    b
      ..writeln()
      ..writeln(r['disclaimer'] ?? '');

    await Clipboard.setData(ClipboardData(text: b.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hasil disalin ke clipboard')),
    );
  }

  // ---------------- small widgets ----------------

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
    Color? borderColor,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? kBorder),
      ),
      child: child,
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _choiceRow(String title, List<String> options, String selected,
      void Function(String) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final o in options)
              ChoiceChip(
                label: Text(o),
                selected: selected == o,
                onSelected: _loading ? null : (_) => onSelected(o),
              ),
          ],
        ),
      ],
    );
  }

  Widget _errorCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _card(
        color: Colors.red.shade50,
        borderColor: Colors.red.shade100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(child: Text(_error!)),
          ],
        ),
      ),
    );
  }

  // ---------------- layout helpers ----------------

  Widget _section({
    required Widget child,
    Key? key,
    Color? color,
    EdgeInsets padding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
  }) {
    return Container(
      key: key,
      width: double.infinity,
      color: color,
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w800, color: kTeal),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _cardsRow(List<Widget> cards) {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 860;
      if (wide) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        );
      }
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            cards[i],
          ],
        ],
      );
    });
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kTeal.withAlpha(25),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 22, color: kTeal),
    );
  }

  Widget _infoCard(IconData icon, String title, String text, {String? step}) {
    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _iconCircle(icon),
              const Spacer(),
              if (step != null)
                Text(step,
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: kTeal.withAlpha(60))),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(height: 1.5, fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _typeCard(String key) {
    final i = hairInfo[key]!;
    return _card(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge(i.walker.toUpperCase(), kTeal),
          const SizedBox(height: 10),
          Text(i.name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(i.desc, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String big, String small) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kTeal.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: kTeal),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(big,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              Text(small,
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- navbar & footer ----------------

  Widget _navBar() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(210),
        border: const Border(bottom: BorderSide(color: kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: LayoutBuilder(builder: (context, c) {
            final showLinks = c.maxWidth > 680 && _result == null;
            final showBadge = c.maxWidth > 480;
            return Row(
              children: [
                InkWell(
                  onTap: _goHome,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kTeal,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.spa_outlined,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(kAppName,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: kTeal)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (showLinks) ...[
                  TextButton(
                      onPressed: () => _scrollTo(_howKey),
                      child: const Text('Cara Kerja')),
                  TextButton(
                      onPressed: () => _scrollTo(_typesKey),
                      child: const Text('Tipe Rambut')),
                  TextButton(
                      onPressed: () => _scrollTo(_aboutKey),
                      child: const Text('Tentang')),
                  const SizedBox(width: 8),
                ],
                if (showBadge) _badge('Model: EfficientNetB0', kTeal),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: kDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_outlined, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Text(kAppName,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Sistem rekomendasi perawatan rambut berbasis CNN EfficientNetB0, pengolahan citra, dan basis aturan.',
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Wrap(
                spacing: 24,
                runSpacing: 6,
                children: const [
                  Text('© 2026 $kAppName',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    'Hasil bersifat umum dan bukan pengganti konsultasi dokter kulit/trikolog.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- screen 1: upload ----------------

  Widget _dropzone() {
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) async {
        setState(() => _dragging = false);
        if (d.files.isEmpty) return;
        final f = d.files.first;
        _setImage(await f.readAsBytes(), f.name);
      },
      child: _card(
        borderColor: _dragging ? kTeal : null,
        color: _dragging ? const Color(0xFFE3F0EE) : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          children: [
            const Icon(Icons.photo_camera_outlined, size: 40, color: kTeal),
            const SizedBox(height: 12),
            const Text(
              'Tarik & lepas foto helai rambut di sini,\natau pilih file dari perangkat',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Format didukung: JPG, PNG, WEBP (Maksimal 10MB)',
              style: TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed:
                      _loading ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Pilih Foto'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _takePhoto,
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Ambil Foto'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipsCard() {
    return _card(
      color: kSoft,
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: kTeal),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Petunjuk Pengambilan Citra',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                  'Tips Akurasi: gunakan foto yang hanya berisi satu orang, rambut terlihat jelas, cahaya alami cukup, '
                  'tanpa filter, rambut cukup panjang dan tidak tertutup topi/hijab, serta fokus pada tekstur helai rambut. '
                  'Foto dengan beberapa orang sekaligus tidak bisa dianalisis.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _conditionCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kondisi Rambut & Kulit Kepala (opsional)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Dipakai untuk menyesuaikan rekomendasi perawatan.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 12),
          _choiceRow('Kondisi kulit kepala', scalpOptions, _scalp,
              (v) => setState(() => _scalp = v)),
          const SizedBox(height: 12),
          _choiceRow('Kondisi rambut', conditionOptions, _condition,
              (v) => setState(() => _condition = v)),
          const SizedBox(height: 12),
          const Text('Keluhan (boleh pilih lebih dari satu)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in complaintOptions)
                FilterChip(
                  label: Text(c),
                  selected: _complaints.contains(c),
                  onSelected: _loading
                      ? null
                      : (sel) => setState(() {
                            if (sel) {
                              _complaints.add(c);
                            } else {
                              _complaints.remove(c);
                            }
                          }),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    final has = _bytes != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18, color: kTeal),
              const SizedBox(width: 6),
              const Text('Pratinjau Sampel',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              _badge(has ? 'SIAP DIANALISIS' : 'BELUM ADA FOTO',
                  has ? const Color(0xFF2E9E6B) : Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: has
                  ? Image.memory(_bytes!, fit: BoxFit.cover)
                  : Container(
                      color: kSoft,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            size: 48, color: Colors.black26),
                      ),
                    ),
            ),
          ),
          if (has)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '$_name  •  ${(_bytes!.length / 1024).toStringAsFixed(0)} KB',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: (!has || _loading) ? null : _predict,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16)),
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Memproses...' : 'Analisis Rambut'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _pick(ImageSource.gallery),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.sync),
            label: const Text('Ganti Foto'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadView() {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 860;
      final left = Column(
        children: [
          _dropzone(),
          const SizedBox(height: 16),
          _tipsCard(),
          const SizedBox(height: 16),
          _conditionCard(),
        ],
      );
      final right = _previewCard();

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: kTeal.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kTeal.withAlpha(60)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: kTeal),
                SizedBox(width: 6),
                Text('Analisis rambut berbasis AI',
                    style: TextStyle(
                        color: kTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Kenali Jenis Rambutmu,\nDapatkan Perawatan yang Tepat',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: kTeal,
                height: 1.2),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: const Text(
              'Unggah foto rambut untuk mendeteksi klasifikasi tekstur rambut secara presisi '
              'dengan AI dan memperoleh panduan perawatan berbasis aturan yang disesuaikan secara personal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.5),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _stat(Icons.category_outlined, '4 jenis', 'tekstur rambut'),
              _stat(Icons.verified_outlined, '±92%', 'akurasi pada data uji'),
              _stat(Icons.spa_outlined, 'Panduan perawatan', 'sesuai kondisimu'),
            ],
          ),
          const SizedBox(height: 32),
          if (_error != null) _errorCard(),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: right),
              ],
            )
          else
            Column(children: [left, const SizedBox(height: 16), right]),
        ],
      );
    });
  }

  // ---------------- bagian bawah halaman upload ----------------

  Widget _howSection() {
    return _section(
      key: _howKey,
      color: Colors.white.withAlpha(150),
      child: Column(
        children: [
          _sectionTitle('Cara Kerja',
              'Tiga langkah singkat dari foto sampai panduan perawatan.'),
          const SizedBox(height: 28),
          _cardsRow([
            _infoCard(
              Icons.upload_file_outlined,
              'Unggah foto',
              'Pilih foto rambut dari galeri, tarik & lepas ke area unggah, atau ambil langsung lewat kamera. '
                  'Pastikan hanya ada satu orang di foto.',
              step: '01',
            ),
            _infoCard(
              Icons.auto_awesome,
              'Analisis AI',
              'Foto dicek dulu apakah rambutnya terlihat jelas, dianalisis dengan teknik pengolahan citra '
                  '(filtering, CLAHE, deteksi tepi, segmentasi, fitur tekstur), dan model CNN mengenali tekstur rambutmu.',
              step: '02',
            ),
            _infoCard(
              Icons.spa_outlined,
              'Dapat panduan',
              'Terima panduan perawatan yang disesuaikan dengan tipe rambut dan kondisimu.',
              step: '03',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _typesSection() {
    return _section(
      key: _typesKey,
      child: Column(
        children: [
          _sectionTitle('4 Tipe Rambut yang Dikenali',
              'Model mengelompokkan rambut ke empat tipe tekstur, dari lurus sampai kinky/coily.'),
          const SizedBox(height: 28),
          _cardsRow([
            _typeCard('straight'),
            _typeCard('wavy'),
            _typeCard('curly'),
            _typeCard('kinky'),
          ]),
        ],
      ),
    );
  }

  Widget _aboutSection() {
    return _section(
      key: _aboutKey,
      color: Colors.white.withAlpha(150),
      child: Column(
        children: [
          _sectionTitle('Tentang Aplikasi',
              'Biar kamu tahu apa yang ada di balik hasilnya, termasuk batasannya.'),
          const SizedBox(height: 28),
          _cardsRow([
            _infoCard(
              Icons.memory_outlined,
              'Model AI',
              'Klasifikasi memakai CNN EfficientNetB0 yang dilatih pada foto rambut dalam 4 kelas, dengan akurasi sekitar 92% pada data uji.',
            ),
            _infoCard(
              Icons.filter_b_and_w_outlined,
              'Pengolahan citra',
              'Analisis tambahan memakai filter Gaussian, CLAHE, deteksi tepi Canny, segmentasi Otsu + morfologi, '
                  'serta fitur tekstur GLCM dan LBP. Bagian ini tidak mengubah hasil klasifikasi CNN.',
            ),
            _infoCard(
              Icons.rule_outlined,
              'Panduan berbasis aturan',
              'Rekomendasi disusun dari basis aturan yang menggabungkan tipe rambut, kondisi kulit kepala, kondisi rambut, dan keluhanmu.',
            ),
            _infoCard(
              Icons.info_outline,
              'Batasan',
              'Model hanya mengenali 4 tipe dan bisa meleset pada foto di luar data latih (cahaya buruk, rambut sangat pendek, tertutup topi/hijab). '
                  'Satu foto hanya boleh berisi satu orang. Hasil bukan diagnosis medis.',
            ),
          ]),
        ],
      ),
    );
  }

  // ---------------- screen 2: result ----------------

  Widget _teleItem(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _probRow(int i, Map<String, dynamic> p) {
    final lbl = p['label'] as String;
    final v = (p['prob'] as num).toDouble();
    final name = hairInfo[lbl]?.name ?? lbl;
    final first = i == 0;
    final w = first ? FontWeight.w700 : FontWeight.w400;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('${i + 1}. $name',
                      style: TextStyle(fontWeight: w))),
              if (first) _badge('Terpilih', kTeal),
              const SizedBox(width: 8),
              Text('${(v * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: w)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 8,
              backgroundColor: kSoft,
              color: first ? kTeal : const Color(0xFF9DBFBC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _careItem(Map<String, dynamic> rec) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 18, color: kTeal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec['title'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(rec['text'] as String? ?? '',
                    style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- kartu pengolahan citra ----------

  Widget _stageTile(int i, Map<String, dynamic> s) {
    final bytes = base64Decode(s['image_b64'] as String);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: kSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: Image.memory(bytes,
                fit: BoxFit.contain, gaplessPlayback: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration:
                    const BoxDecoration(color: kTeal, shape: BoxShape.circle),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(s['title'] as String? ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s['desc'] as String? ?? '',
            style: const TextStyle(
                fontSize: 12, height: 1.4, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _lbpChart(List<double> hist) {
    final mx = hist.fold<double>(0, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 90,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < hist.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: mx <= 0 ? 0 : 60 * hist[i] / mx,
                      decoration: BoxDecoration(
                        color: kTeal,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$i',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pcdCard(Map<String, dynamic> pcd) {
    final stages = (pcd['stages'] as List).cast<Map<String, dynamic>>();
    final feat = (pcd['features'] as Map).cast<String, dynamic>();
    final glcm = (feat['glcm'] as Map).cast<String, dynamic>();
    final lbp =
        (feat['lbp_hist'] as List).map((e) => (e as num).toDouble()).toList();
    final segOk = feat['segmentation_ok'] != false;

    String f(dynamic v, [int d = 3]) => v is num ? v.toStringAsFixed(d) : '-';

    return _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tahapan Pengolahan Citra',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Teknik pengolahan citra yang dijalankan backend pada fotomu. Bagian ini adalah analisis tambahan; '
            'jenis rambut tetap diklasifikasikan oleh CNN EfficientNetB0.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 18,
            children: [
              for (var i = 0; i < stages.length; i++) _stageTile(i, stages[i]),
            ],
          ),
          if (!segOk)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Segmentasi otomatis kurang berhasil pada foto ini (latar atau pencahayaan terlalu rumit), '
                'jadi fitur tekstur dihitung dari seluruh citra.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: kBorder),
          const SizedBox(height: 14),
          const Text('Fitur Tekstur',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              _teleItem('GLCM Contrast', f(glcm['contrast'])),
              _teleItem('GLCM Dissimilarity', f(glcm['dissimilarity'])),
              _teleItem('GLCM Homogeneity', f(glcm['homogeneity'])),
              _teleItem('GLCM Energy', f(glcm['energy'])),
              _teleItem('GLCM Correlation', f(glcm['correlation'])),
              _teleItem('Entropi LBP', f(feat['lbp_entropy'])),
              _teleItem('Kerapatan tepi', '${f(feat['edge_density_pct'], 1)}%'),
              _teleItem('Koherensi arah', f(feat['coherence'])),
              _teleItem('Area rambut', '${f(feat['mask_area_pct'], 1)}%'),
              _teleItem('Waktu proses', '${feat['process_ms'] ?? '-'} ms'),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Histogram LBP (uniform, P=8, R=1)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          _lbpChart(lbp),
          const SizedBox(height: 12),
          const Text(
            'Cara baca: koherensi arah yang mendekati 1 berarti helai cenderung searah (khas rambut lurus), '
            'makin rendah berarti arah helai beragam (khas rambut ikal/keriting). Kontras GLCM dan entropi LBP yang '
            'tinggi menandakan tekstur yang lebih kompleks. Angka-angka ini indikatif dan belum dipakai untuk '
            'menentukan kelas.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    final r = _result!;
    final label = r['label'] as String;
    final info = hairInfo[label] ?? HairInfo(label, '-', label, '');
    final conf = (r['confidence'] as num).toDouble();
    final low = r['low_confidence'] == true;
    final probs = (r['probs'] as List).cast<Map<String, dynamic>>();
    final recs = (r['recommendations'] as List).cast<Map<String, dynamic>>();
    final inputs = r['inputs'] as Map<String, dynamic>;
    final complaints = (inputs['complaints'] as List).cast<String>();
    final tele = (r['telemetry'] as Map<String, dynamic>?) ?? {};
    final pcd = r['pcd'] as Map<String, dynamic>?;
    final disclaimer = r['disclaimer'] as String? ?? '';

    final level = conf >= 0.8 ? 'Tinggi' : (conf >= 0.6 ? 'Sedang' : 'Rendah');
    final levelColor = conf >= 0.8
        ? const Color(0xFF2E9E6B)
        : (conf >= 0.6 ? const Color(0xFFC98A00) : const Color(0xFFD9534F));

    final header = Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hasil Klasifikasi Tekstur & Panduan Perawatan',
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: kTeal),
              ),
              SizedBox(height: 6),
              Text(
                'Jenis rambut dikenali dengan model CNN EfficientNetB0, lalu dipadukan '
                'dengan basis aturan perawatan.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
              label: const Text('Analisis Foto Lain'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _copy(r),
              icon: const Icon(Icons.copy),
              label: const Text('Salin Hasil'),
            ),
          ],
        ),
      ],
    );

    final left = Column(
      children: [
        _card(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_bytes != null)
                        Image.memory(_bytes!, fit: BoxFit.cover),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E9E6B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('CITRA VALID',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _card(
          color: kSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TELEMETRI PEMROSESAN CITRA',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  _teleItem('Resolusi',
                      '${tele['width'] ?? '-'} × ${tele['height'] ?? '-'}'),
                  _teleItem(
                      'Waktu Inferensi', '${tele['inference_ms'] ?? '-'} ms'),
                  _teleItem('Model Visi', 'EfficientNetB0'),
                  _teleItem('Pencahayaan', '${tele['lighting'] ?? '-'}'),
                  _teleItem('Ketajaman', '${tele['focus'] ?? '-'}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final right = _card(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: kTeal),
                  SizedBox(width: 8),
                  Text('KLASIFIKASI DOMINAN TERIDENTIFIKASI',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54)),
                ],
              ),
              _badge('${(conf * 100).toStringAsFixed(1)}% Keyakinan Model ($level)',
                  levelColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kTeal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'TIPE UTAMA  •  Setara Walker: ${info.walker}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(info.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(info.desc,
                    style: const TextStyle(color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: Text('Distribusi Probabilitas Model',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              Text('4 Kategori Tekstur',
                  style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Seberapa mirip foto ini dengan tiap jenis rambut menurut model (total 100%).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < probs.length; i++) _probRow(i, probs[i]),
        ],
      ),
    );

    final Widget recommendation = low
        ? _card(
            color: const Color(0xFFFFF4E0),
            borderColor: const Color(0xFFF2D9A6),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFC98A00)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Model kurang yakin dengan foto ini, jadi rekomendasi perawatan tidak ditampilkan. '
                    'Coba foto lain: satu orang saja, rambut terlihat jelas, cahaya cukup, tanpa topi/hijab.',
                  ),
                ),
              ],
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _card(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Panduan Perawatan',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _badge('Kulit kepala: ${inputs['scalp']}',
                            Colors.black54),
                        _badge('Kondisi rambut: ${inputs['condition']}',
                            Colors.black54),
                        _badge(
                            'Keluhan: ${complaints.isEmpty ? '-' : complaints.join(', ')}',
                            Colors.black54),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (final rec in recs) _careItem(rec),
                  ],
                ),
              ),
              if (disclaimer.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    disclaimer,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.black54,
                        fontSize: 12),
                  ),
                ),
            ],
          );

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 860;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 20),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: right),
              ],
            )
          else
            Column(children: [left, const SizedBox(height: 16), right]),
          if (pcd != null) ...[
            const SizedBox(height: 16),
            _pcdCard(pcd),
          ],
          const SizedBox(height: 16),
          recommendation,
        ],
      );
    });
  }

  // ---------------- root ----------------

  @override
  Widget build(BuildContext context) {
    final onResult = _result != null;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _Background(),
          SafeArea(
            child: SingleChildScrollView(
              controller: _scroll,
              child: Column(
                children: [
                  _navBar(),
                  _section(
                    padding: const EdgeInsets.fromLTRB(20, 36, 20, 56),
                    child: onResult ? _buildResultView() : _buildUploadView(),
                  ),
                  if (!onResult) ...[
                    _howSection(),
                    _typesSection(),
                    _aboutSection(),
                  ],
                  _footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- dialog webcam (laptop/PC) ----------------

class WebcamDialog extends StatefulWidget {
  const WebcamDialog({super.key});

  @override
  State<WebcamDialog> createState() => _WebcamDialogState();
}

class _WebcamDialogState extends State<WebcamDialog> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        if (mounted) setState(() => _error = 'Kamera tidak ditemukan.');
        return;
      }
      final c = CameraController(cams.first, ResolutionPreset.high,
          enableAudio: false);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Kamera tidak bisa diakses. Pastikan izin kamera di Chrome diizinkan dan kamera tidak sedang dipakai aplikasi lain.');
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      final f = await c.takePicture();
      if (mounted) Navigator.of(context).pop(f);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gagal mengambil foto. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return AlertDialog(
      title: const Text('Ambil Foto dengan Kamera'),
      content: SizedBox(
        width: 480,
        child: _error != null
            ? Text(_error!)
            : (c == null || !c.value.isInitialized)
                ? const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AspectRatio(
                    aspectRatio: c.value.aspectRatio,
                    child: CameraPreview(c),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton.icon(
          onPressed: (c == null || _busy) ? null : _shoot,
          icon: const Icon(Icons.camera_alt),
          label: Text(_busy ? 'Memproses...' : 'Jepret'),
        ),
      ],
    );
  }
}