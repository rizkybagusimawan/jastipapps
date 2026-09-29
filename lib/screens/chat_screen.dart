import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String orderTitle;

  const ChatScreen({
    super.key,
    required this.orderId,
    required this.orderTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingImage = false;

  File? _selectedImage;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _loadMessages();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _apiService.getMessages(widget.orderId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      await _apiService.markMessagesAsRead(widget.orderId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _pickImage() async {
    if (_isSending || _isUploadingImage) return;

    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile == null || !mounted) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  void _removeSelectedImage() {
    if (_isSending || _isUploadingImage) return;

    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();

    if ((text.isEmpty && _selectedImage == null) || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      String? imageUrl;

      // Upload gambar terlebih dahulu jika ada.
      if (_selectedImage != null) {
        setState(() {
          _isUploadingImage = true;
        });

        imageUrl = await _apiService.uploadImage(_selectedImage!);

        if (!mounted) return;

        setState(() {
          _isUploadingImage = false;
        });
      }

      await _apiService.sendMessage(
        orderId: widget.orderId,
        message: text.isEmpty ? null : text,
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      _messageController.clear();

      setState(() {
        _selectedImage = null;
      });

      await _loadMessages();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim pesan: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedImagePreview() {
    if (_selectedImage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 90,
      width: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _selectedImage!,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: _removeSelectedImage,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (_isUploadingImage)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final imageUrl = msg.hasImage ? AppConfig.getImageUrl(msg.imageUrl!) : null;

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: msg.isMine
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!msg.isMine)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                child: Text(
                  '${msg.senderName} (${msg.senderRole})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),

            // Gambar
            if (imageUrl != null)
              GestureDetector(
                onTap: () => _showImagePreview(imageUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 220,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        width: 220,
                        height: 150,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Jarak antara gambar dan teks
            if (imageUrl != null && msg.hasText) const SizedBox(height: 6),

            // Text
            if (msg.hasText)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  msg.message!,
                  style: TextStyle(
                    color: msg.isMine ? Colors.white : Colors.black87,
                  ),
                ),
              ),

            const SizedBox(height: 2),

            // Read status
            if (msg.isMine)
              Padding(
                padding: const EdgeInsets.only(right: 4, top: 2),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    msg.readAt != null ? Icons.done_all : Icons.done,
                    size: 15,
                    color: msg.readAt != null
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat • ${widget.orderTitle}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada pesan.\n'
                      'Mulai chat sekarang!',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = _messages.length - 1 - index;

                      return _buildMessageBubble(_messages[reversedIndex]);
                    },
                  ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  _buildSelectedImagePreview(),

                  Row(
                    children: [
                      // Tombol gambar
                      IconButton(
                        onPressed: (_isSending || _isUploadingImage)
                            ? null
                            : _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        tooltip: 'Pilih gambar',
                      ),

                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          enabled: !_isSending && !_isUploadingImage,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),

                      const SizedBox(width: 8),

                      IconButton.filled(
                        onPressed: (_isSending || _isUploadingImage)
                            ? null
                            : _handleSend,
                        icon: _isSending
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
