import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../main.dart';
import '../models/category.dart';
import '../data/categories_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _showDropdowns = true;
  
  Map<String, String> _selectedValues = {};
  Map<String, String> _customValues = {};
  List<Category> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initCamera();
  }
  
  void _loadCategories() {
    _categories = CategoriesData.getCategories();
    for (var cat in _categories) {
      _selectedValues[cat.name] = cat.options.isNotEmpty ? cat.options.first.id : '';
    }
  }
  
  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.storage.request();
    
    if (cameras.isEmpty) return;
    
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      setState(() => _isCameraReady = true);
    } catch (e) {
      print('Camera init error: $e');
    }
  }
  
  String _generateFileName() {
    List<String> parts = [];
    
    for (var cat in _categories) {
      String selectedId = _selectedValues[cat.name] ?? '';
      if (selectedId.isEmpty || selectedId == 'none') continue;
      
      CategoryOption? option = cat.options.firstWhere(
        (o) => o.id == selectedId,
        orElse: () => CategoryOption(id: '', label: '', output: ''),
      );
      
      if (option.customInput) {
        String customVal = _customValues[cat.name] ?? '';
        if (customVal.isNotEmpty) parts.add(customVal);
      } else if (option.output.isNotEmpty) {
        parts.add(option.output);
      }
    }
    
    return parts.join(' - ');
  }
  
  Future<void> _takePhoto() async {
    if (_cameraController == null || !_isCameraReady) return;
    
    try {
      String fileName = _generateFileName();
      if (fileName.isEmpty) {
        fileName = 'Photo_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      final XFile photo = await _cameraController!.takePicture();
      
      final Directory? extDir = await getExternalStorageDirectory();
      final String dirPath = '${extDir?.path ?? '/storage/emulated/0'}/PhotoNamer';
      await Directory(dirPath).create(recursive: true);
      
      final String filePath = '$dirPath/$fileName.jpg';
      await File(photo.path).copy(filePath);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 $fileName.jpg'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  void _showCustomInputDialog(Category category) {
    final controller = TextEditingController(text: _customValues[category.name] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom ${category.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter custom value...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _customValues[category.name] = controller.text);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FULLSCREEN CAMERA
          Positioned.fill(
            child: _isCameraReady && _cameraController != null
                ? CameraPreview(_cameraController!)
                : Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
          ),
          
          // TOP OVERLAY - Filename + Dropdowns
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  // Filename preview bar
                  GestureDetector(
                    onTap: () => setState(() => _showDropdowns = !_showDropdowns),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.black.withOpacity(0.7),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _generateFileName().isEmpty ? 'Tap to configure...' : _generateFileName(),
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(_showDropdowns ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  
                  // Collapsible dropdowns
                  if (_showDropdowns)
                    Container(
                      color: Colors.black.withOpacity(0.6),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: _categories.map((cat) => _buildDropdown(cat)).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // BOTTOM CAPTURE BUTTON
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 70,
              child: ElevatedButton(
                onPressed: _takePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 32),
                    SizedBox(width: 12),
                    Text('CAPTURE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdown(Category category) {
    String selectedId = _selectedValues[category.name] ?? '';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: category.optional ? Colors.grey.shade400 : Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade800.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  dropdownColor: Colors.grey.shade800,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: category.options.map((opt) {
                    return DropdownMenuItem(
                      value: opt.id,
                      child: Text(
                        opt.customInput && _customValues[category.name] != null
                            ? '${opt.label}: ${_customValues[category.name]}'
                            : opt.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedValues[category.name] = value ?? '');
                    CategoryOption? opt = category.options.firstWhere(
                      (o) => o.id == value,
                      orElse: () => CategoryOption(id: '', label: '', output: ''),
                    );
                    if (opt.customInput) _showCustomInputDialog(category);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
