import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;
  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _whatsappController;
  late TextEditingController _bioController;

  String perfilPrivado = 'N';
  File? _imageFile;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _nameController = TextEditingController(text: user['name']);
    _usernameController = TextEditingController(text: user['username']);
    _emailController = TextEditingController(text: user['email']);
    _whatsappController = TextEditingController(text: user['whatsapp']);
    _bioController = TextEditingController(text: user['bio']);
    perfilPrivado = user['perfil_privado'] ?? 'N';
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final uri = Uri.parse('https://adivinheganhe.com.br/api/usuario/update');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${widget.currentUser['token']}'
      ..fields['name'] = _nameController.text
      ..fields['username'] = _usernameController.text
      ..fields['email'] = _emailController.text
      ..fields['whatsapp'] = _whatsappController.text
      ..fields['perfil_privado'] = perfilPrivado
      ..fields['bio'] = _bioController.text;

    if (_imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resBody);
      // Atualiza usuário no FlutterSecureStorage
      await _storage.write(key: 'user', value: json.encode(data['user']));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
      Navigator.pop(context, data['user']); // retorna usuário atualizado
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar perfil: ${resBody}')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil' , style: TextStyle(color: Colors.white))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Foto
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (widget.currentUser['image'] != null
                                ? NetworkImage(widget.currentUser['image']) as ImageProvider
                                : const AssetImage('assets/default_avatar.png')),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nome
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 8),

                    // Usuário
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Usuário'),
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 8),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 8),

                    // WhatsApp
                    TextFormField(
                      controller: _whatsappController,
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp', hintText: '(99) 99999-9999'),
                    ),
                    const SizedBox(height: 8),

                    // Perfil Privado
                    DropdownButtonFormField<String>(
                      value: perfilPrivado,
                      items: const [
                        DropdownMenuItem(value: 'N', child: Text('Não')),
                        DropdownMenuItem(value: 'S', child: Text('Sim')),
                      ],
                      onChanged: (v) => setState(() => perfilPrivado = v ?? 'N'),
                      decoration: const InputDecoration(labelText: 'Perfil Privado'),
                    ),
                    const SizedBox(height: 8),

                    // Bio
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Salvar Alterações'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
