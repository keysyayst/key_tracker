import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WishlistView extends StatefulWidget {
  const WishlistView({super.key});

  @override
  State<WishlistView> createState() => _WishlistViewState();
}

class _WishlistViewState extends State<WishlistView> {
  // Soft-pink palette (konsisten)
  static const _bgTop = Color(0xFFFFF5F8);
  static const _bgBottom = Color(0xFFFFFBFD);

  static const _ink = Color(0xFF2D2A32);
  static const _muted = Color(0xFF6B5B63);

  static const _pink500 = Color(0xFFEC4899);
  static const _pink200 = Color(0xFFFFC4D6);
  static const _pink100 = Color(0xFFFFE4EC);
  static const _pink050 = Color(0xFFFFF1F6);

  static const _card = Color(0xFFFFFEFF);
  static const _line = Color(0x14000000);

  final supa = Supabase.instance.client;

  bool _loading = true;
  List<Map<String, dynamic>> _categories = [];
  Map<String, List<Map<String, dynamic>>> _itemsByCat = {};
  final Set<String> _expanded = <String>{};

  // Icon catalog (kecil tapi cukup buat kebutuhan kategori)
  static const List<String> _iconKeys = [
    'bookmark',
    'shopping_bag',
    'shopping_cart',
    'devices',
    'headphones',
    'spa',
    'fitness_center',
    'flight',
    'hotel',
    'home',
    'restaurant',
    'local_cafe',
    'school',
    'menu_book',
    'work',
    'palette',
    'camera_alt',
    'sports_esports',
    'pets',
    'directions_car',
    'card_giftcard',
  ];

  static const Map<String, IconData> _iconMap = {
    'bookmark': Icons.bookmark_border_rounded,
    'shopping_bag': Icons.shopping_bag_outlined,
    'shopping_cart': Icons.shopping_cart_outlined,
    'devices': Icons.devices_other_rounded,
    'headphones': Icons.headphones_rounded,
    'spa': Icons.spa_outlined,
    'fitness_center': Icons.fitness_center_rounded,
    'flight': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,
    'home': Icons.home_rounded,
    'restaurant': Icons.restaurant_rounded,
    'local_cafe': Icons.local_cafe_rounded,
    'school': Icons.school_rounded,
    'menu_book': Icons.menu_book_rounded,
    'work': Icons.work_outline_rounded,
    'palette': Icons.palette_outlined,
    'camera_alt': Icons.camera_alt_outlined,
    'sports_esports': Icons.sports_esports_rounded,
    'pets': Icons.pets_rounded,
    'directions_car': Icons.directions_car_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
  };

  IconData _iconFromKey(String? key) {
    final k = (key == null || key.trim().isEmpty) ? 'bookmark' : key.trim();
    return _iconMap[k] ?? Icons.bookmark_border_rounded;
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  String _uid() {
    final uid = supa.auth.currentUser?.id;
    if (uid == null) throw Exception('User belum login.');
    return uid;
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final uid = _uid();

    final cats = await supa
        .from('wishlist_categories')
        .select('*')
        .eq('user_id', uid)
        .order('sort_order')
        .order('created_at');

    final items = await supa
        .from('wishlist_items')
        .select('*')
        .eq('user_id', uid)
        .order('sort_order')
        .order('created_at');

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final raw in (items as List)) {
      final it = Map<String, dynamic>.from(raw as Map);
      final catId = it['category_id'].toString();
      grouped.putIfAbsent(catId, () => []);
      grouped[catId]!.add(it);
    }

    setState(() {
      _categories =
          (cats as List).map((e) => Map<String, dynamic>.from(e)).toList();
      _itemsByCat = grouped;
      _loading = false;

      if (_categories.isNotEmpty && _expanded.isEmpty) {
        _expanded.add(_categories.first['id'].toString());
      }
    });
  }

  // ---------- CRUD: Category ----------
  Future<void> _createCategory() async {
    final result = await _promptCategory(
      title: 'Kategori baru',
      initialName: '',
      initialIconKey: 'bookmark',
    );
    if (result == null) return;

    final name = result.$1.trim();
    final iconKey = result.$2.trim();

    if (name.isEmpty) return;

    await supa.from('wishlist_categories').insert({
      'user_id': _uid(),
      'name': name,
      'icon_key': iconKey.isEmpty ? 'bookmark' : iconKey,
    });

    await _loadAll();
  }

  Future<void> _editCategory(Map<String, dynamic> cat) async {
    final currentName = (cat['name'] ?? '').toString();
    final currentIconKey = (cat['icon_key'] ?? 'bookmark').toString();

    final result = await _promptCategory(
      title: 'Edit kategori',
      initialName: currentName,
      initialIconKey: currentIconKey,
    );
    if (result == null) return;

    final nextName = result.$1.trim();
    final nextIconKey = result.$2.trim();
    if (nextName.isEmpty) return;

    await supa.from('wishlist_categories').update({
      'name': nextName,
      'icon_key': nextIconKey.isEmpty ? 'bookmark' : nextIconKey,
    }).eq('id', cat['id']);

    await _loadAll();
  }

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final ok = await _confirm(
      title: 'Hapus kategori?',
      body: 'Semua item di kategori ini juga akan terhapus.',
      confirmText: 'Hapus',
    );
    if (ok != true) return;

    await supa.from('wishlist_categories').delete().eq('id', cat['id']);
    _expanded.remove(cat['id'].toString());
    await _loadAll();
  }

  // ---------- CRUD: Item ----------
  Future<void> _createItem(String categoryId) async {
    final title = await _promptText(
      title: 'Wishlist baru',
      label: 'Nama keinginan',
      hint: 'Contoh: Upgrade headset',
    );
    if (title == null || title.trim().isEmpty) return;

    final note = await _promptText(
      title: 'Catatan (opsional)',
      label: 'Catatan',
      hint: 'Opsional',
      required: false,
    );

    await supa.from('wishlist_items').insert({
      'user_id': _uid(),
      'category_id': categoryId,
      'title': title.trim(),
      'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'is_done': false,
    });

    setState(() => _expanded.add(categoryId));
    await _loadAll();
  }

  Future<void> _toggleDone(Map<String, dynamic> item, bool value) async {
    await supa.from('wishlist_items').update({
      'is_done': value,
    }).eq('id', item['id']);

    final catId = item['category_id'].toString();
    final list = _itemsByCat[catId];
    if (list != null) {
      final idx = list.indexWhere((e) => e['id'] == item['id']);
      if (idx != -1) {
        setState(() {
          list[idx] = {...list[idx], 'is_done': value};
        });
      }
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final currentTitle = (item['title'] ?? '').toString();
    final currentNote = (item['note'] ?? '').toString();

    final nextTitle = await _promptText(
      title: 'Edit wishlist',
      label: 'Nama keinginan',
      initial: currentTitle,
    );
    if (nextTitle == null || nextTitle.trim().isEmpty) return;

    final nextNote = await _promptText(
      title: 'Catatan (opsional)',
      label: 'Catatan',
      initial: currentNote,
      required: false,
    );

    await supa.from('wishlist_items').update({
      'title': nextTitle.trim(),
      'note': (nextNote == null || nextNote.trim().isEmpty)
          ? null
          : nextNote.trim(),
    }).eq('id', item['id']);

    await _loadAll();
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final ok = await _confirm(
      title: 'Hapus wishlist?',
      body: 'Item ini akan dihapus permanen.',
      confirmText: 'Hapus',
    );
    if (ok != true) return;

    await supa.from('wishlist_items').delete().eq('id', item['id']);
    await _loadAll();
  }

  // ---------- Styling ----------
  BoxDecoration _softCard({bool accent = false}) {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _line),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
      gradient: accent
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBFD), Color(0xFFFFF1F6)],
            )
          : null,
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _pink050,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
      ),
      child: child,
    );
  }

  // ---------- Bottom sheets / dialogs ----------
  void _openCategoryMenu(Map<String, dynamic> cat) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Kategori',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CuteActionTile(
                icon: Icons.edit_outlined,
                text: 'Edit',
                onTap: () async {
                  Navigator.pop(context);
                  await _editCategory(cat);
                },
              ),
              _CuteActionTile(
                icon: Icons.delete_outline,
                text: 'Hapus',
                danger: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteCategory(cat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openItemMenu(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Wishlist',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CuteActionTile(
                icon: Icons.edit_outlined,
                text: 'Edit',
                onTap: () async {
                  Navigator.pop(context);
                  await _editItem(item);
                },
              ),
              _CuteActionTile(
                icon: Icons.delete_outline,
                text: 'Hapus',
                danger: true,
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _promptText({
    required String title,
    required String label,
    String? hint,
    String? initial,
    bool required = true,
  }) async {
    final c = TextEditingController(text: initial ?? '');
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: title,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CuteField(
                  controller: c,
                  label: label,
                  hint: hint,
                  fill: _pink050,
                ),
                const SizedBox(height: 12),
                _CutePrimaryButton(
                  text: 'Simpan',
                  onTap: () async {
                    final v = c.text.trim();
                    if (required && v.isEmpty) return;
                    if (context.mounted) Navigator.pop(context, v);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<(String, String)?> _promptCategory({
    required String title,
    required String initialName,
    required String initialIconKey,
  }) async {
    final nameC = TextEditingController(text: initialName);
    String picked = initialIconKey;

    return showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModal) {
            return _CuteSheet(
              title: title,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CuteField(
                      controller: nameC,
                      label: 'Nama kategori',
                      hint: 'Contoh: Travel',
                      fill: _pink050,
                    ),
                    const SizedBox(height: 12),

                    // Icon picker preview
                    Container(
                      decoration: BoxDecoration(
                        color: _pink050,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _line),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _pink100,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _line),
                            ),
                            child: Icon(_iconFromKey(picked), color: _pink500),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pilih icon kategori',
                              style: TextStyle(
                                color: _muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final res = await _pickIconKey(picked);
                              if (res == null) return;
                              setModal(() => picked = res);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _pink500,
                              textStyle: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            child: const Text('Pilih'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    _CutePrimaryButton(
                      text: 'Simpan',
                      onTap: () async {
                        final name = nameC.text.trim();
                        if (name.isEmpty) return;
                        if (context.mounted) Navigator.pop(context, (name, picked));
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _pickIconKey(String current) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: 'Pilih icon',
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: GridView.builder(
              itemCount: _iconKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (_, i) {
                final key = _iconKeys[i];
                final active = key == current;

                return InkWell(
                  onTap: () => Navigator.pop(context, key),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: active ? _pink100 : _pink050,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: active ? _pink200 : _line),
                    ),
                    child: Icon(
                      _iconFromKey(key),
                      color: active ? _pink500 : _ink.withOpacity(.72),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String confirmText,
  }) async {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _CuteSheet(
          title: title,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(body, style: TextStyle(color: _muted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: BorderSide(color: Colors.black.withOpacity(.08)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pink100,
                        foregroundColor: const Color(0xFFD13B57),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      appBar: AppBar(
        title: const Text('Wishlist'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Tambah kategori',
            onPressed: _createCategory,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                  children: [
                    if (_categories.isEmpty)
                      Container(
                        decoration: _softCard(accent: true),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Belum ada kategori. Tambahkan kategori dari tombol + di kanan atas.',
                          style: TextStyle(
                            color: _muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_categories.length, (i) {
                        final cat = _categories[i];
                        final catId = cat['id'].toString();
                        final name = (cat['name'] ?? '').toString();
                        final iconKey = (cat['icon_key'] ?? 'bookmark').toString();
                        final items = _itemsByCat[catId] ?? const [];

                        final doneCount =
                            items.where((e) => e['is_done'] == true).length;
                        final totalCount = items.length;
                        final expanded = _expanded.contains(catId);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: _softCard(),
                            child: Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (expanded) {
                                        _expanded.remove(catId);
                                      } else {
                                        _expanded.add(catId);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(14, 12, 10, 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _pink100,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: _line),
                                          ),
                                          child: Icon(
                                            _iconFromKey(iconKey),
                                            color: _pink500,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: _ink,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              _pill(
                                                child: Text(
                                                  '$doneCount/$totalCount',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                    color: _ink,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Tambah wishlist',
                                          onPressed: () => _createItem(catId),
                                          icon: const Icon(Icons.add_circle_outline),
                                        ),
                                        IconButton(
                                          tooltip: 'Menu kategori',
                                          onPressed: () => _openCategoryMenu(cat),
                                          icon: const Icon(Icons.more_horiz),
                                        ),
                                        AnimatedRotation(
                                          turns: expanded ? .5 : 0,
                                          duration: const Duration(milliseconds: 160),
                                          child: const Icon(
                                            Icons.expand_more_rounded,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (expanded)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 0, 12, 12),
                                    child: Column(
                                      children: [
                                        if (items.isEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _pink050,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(color: _line),
                                            ),
                                            child: Text(
                                              'Belum ada item.',
                                              style: TextStyle(
                                                color: _muted,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        else
                                          for (final it in items)
                                            _WishlistItemTile(
                                              ink: _ink,
                                              muted: _muted,
                                              line: _line,
                                              pink100: _pink100,
                                              pink500: _pink500,
                                              item: it,
                                              onToggle: (v) =>
                                                  _toggleDone(it, v),
                                              onMenu: () => _openItemMenu(it),
                                            ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}

class _WishlistItemTile extends StatelessWidget {
  const _WishlistItemTile({
    required this.ink,
    required this.muted,
    required this.line,
    required this.pink100,
    required this.pink500,
    required this.item,
    required this.onToggle,
    required this.onMenu,
  });

  final Color ink;
  final Color muted;
  final Color line;
  final Color pink100;
  final Color pink500;

  final Map<String, dynamic> item;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? '').toString();
    final note = (item['note'] ?? '').toString();
    final done = item['is_done'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CheckboxListTile.adaptive(
        value: done,
        onChanged: (v) {
          if (v == null) return;
          onToggle(v);
        },
        activeColor: pink500,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? muted : ink,
          ),
        ),
        subtitle: note.trim().isEmpty
            ? null
            : Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: muted, fontWeight: FontWeight.w600),
              ),
        secondary: InkResponse(
          onTap: onMenu,
          radius: 18,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.more_horiz, color: Colors.black45),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
    );
  }
}

class _CuteSheet extends StatelessWidget {
  const _CuteSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  static const _line = Color(0x14000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(99),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CuteField extends StatelessWidget {
  const _CuteField({
    required this.controller,
    required this.label,
    this.hint,
    required this.fill,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: fill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
      ),
    );
  }
}

class _CutePrimaryButton extends StatelessWidget {
  const _CutePrimaryButton({required this.text, required this.onTap});

  final String text;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () async => onTap(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC4D6),
          foregroundColor: const Color(0xFF2D2A32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _CuteActionTile extends StatelessWidget {
  const _CuteActionTile({
    required this.icon,
    required this.text,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFD13B57) : const Color(0xFF2D2A32);
    final bg = danger ? const Color(0xFFFFEEF3) : const Color(0xFFFFF1F6);

    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Icon(icon, size: 18, color: fg),
      ),
      title: Text(
        text,
        style: TextStyle(fontWeight: FontWeight.w900, color: fg),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
