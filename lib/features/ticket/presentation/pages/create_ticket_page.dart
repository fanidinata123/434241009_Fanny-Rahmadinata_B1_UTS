import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../bloc/ticket_bloc.dart';
import '../../../../core/constants/app_colors.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedPriority = 'low';
  String? _selectedCategory;
  final List<File> _pickedFiles = [];
  final _picker = ImagePicker();

  final _priorities = [
    {'value': 'low',      'label': 'Rendah',  'color': AppColors.priorityLow},
    {'value': 'medium',   'label': 'Sedang',  'color': AppColors.priorityMedium},
    {'value': 'high',     'label': 'Tinggi',  'color': AppColors.priorityHigh},
    {'value': 'critical', 'label': 'Kritis',  'color': AppColors.priorityCritical},
  ];

  final _categories = [
    'Hardware', 'Software', 'Jaringan', 'Akun & Akses', 'Email', 'Lainnya',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) {
      setState(() => _pickedFiles.add(File(xFile.path)));
    }
  }

  Future<void> _pickFile() async {
    // Menggunakan image_picker; untuk file umum gunakan file_picker package
    final xFile = await _picker.pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      setState(() => _pickedFiles.add(File(xFile.path)));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file_outlined),
              title: const Text('Pilih File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    List<MultipartFile>? attachments;
    if (_pickedFiles.isNotEmpty) {
      attachments = await Future.wait(
        _pickedFiles.map(
          (f) => MultipartFile.fromFile(f.path,
              filename: f.path.split('/').last),
        ),
      );
    }

    if (!mounted) return;
    context.read<TicketBloc>().add(CreateTicket(
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          priority: _selectedPriority,
          categoryId: _selectedCategory,
          attachments: attachments,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket Baru')),
      body: BlocListener<TicketBloc, TicketState>(
        listener: (ctx, state) {
          if (state is TicketCreated) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('Tiket berhasil dibuat!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(ctx);
          } else if (state is TicketError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Judul
              Text('Judul Tiket', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ringkasan masalah yang dialami',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Judul wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // Deskripsi
              Text('Deskripsi', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Jelaskan masalah secara detail: kapan terjadi, pesan error, langkah yang sudah dicoba...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Deskripsi wajib diisi' : null,
              ),

              const SizedBox(height: 16),

              // Kategori
              Text('Kategori', style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Pilih kategori'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),

              const SizedBox(height: 16),

              // Prioritas
              Text('Prioritas', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p['value'];
                  final color = p['color'] as Color;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedPriority = p['value'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.15)
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            p['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? color : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Upload lampiran
              Text('Lampiran (opsional)', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_pickedFiles.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedFiles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      if (i == _pickedFiles.length) {
                        return _AddMoreButton(onTap: _showAttachmentOptions);
                      }
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _pickedFiles[i],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _pickedFiles.removeAt(i)),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                GestureDetector(
                  onTap: _showAttachmentOptions,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.4),
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 28,
                            color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(height: 4),
                        Text('Tambah foto / file',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              BlocBuilder<TicketBloc, TicketState>(
                builder: (ctx, state) => ElevatedButton.icon(
                  onPressed: state is TicketLoading ? null : _submit,
                  icon: state is TicketLoading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded),
                  label: Text(
                      state is TicketLoading ? 'Mengirim...' : 'Kirim Tiket'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}