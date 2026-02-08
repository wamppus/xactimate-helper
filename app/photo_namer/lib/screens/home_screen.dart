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
  
  // Selected values for each category
  Map<String, String> _selectedValues = {};
  Map<String, String> _customValues = {};
  
  // Categories from data
  List<Category> _categories = [];
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initCamera();
  }
  
  void _loadCategories() {
    _categories = CategoriesData.getCategories();
    // Initialize selected values
    for (var cat in _categories) {
      _selectedValues[cat.name] = cat.options.isNotEmpty ? cat.options.first.id : '';
    }
  }
  
  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.storage.request();
    
    if (cameras.isEmpty) {
      print('No cameras available');
      return;
    }
    
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
      
      // Skip if none/skip selected
      if (selectedId.isEmpty || selectedId == 'none') continue;
      
      // Find the option
      CategoryOption? option = cat.options.firstWhere(
        (o) => o.id == selectedId,
        orElse: () => CategoryOption(id: '', label: '', output: ''),
      );
      
      // Handle custom input
      if (option.customInput) {
        String customVal = _customValues[cat.name] ?? '';
        if (customVal.isNotEmpty) {
          parts.add(customVal);
        }
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
      
      // Sanitize filename
      fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      
      final XFile photo = await _cameraController!.takePicture();
      
      // Get storage directory
      final Directory? extDir = await getExternalStorageDirectory();
      final String dirPath = '${extDir?.path ?? '/storage/emulated/0'}/PhotoNamer';
      await Directory(dirPath).create(recursive: true);
      
      // Save with custom name
      final String filePath = '$dirPath/$fileName.jpg';
      await File(photo.path).copy(filePath);
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: $fileName.jpg'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showCustomInputDialog(Category category) {
    final controller = TextEditingController(
      text: _customValues[category.name] ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom ${category.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter custom value...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _customValues[category.name] = controller.text;
              });
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
      body: SafeArea(
        child: Column(
          children: [
            // File name preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.black87,
              child: Text(
                _generateFileName().isEmpty 
                    ? 'Select options below...' 
                    : _generateFileName(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Dropdowns
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: _categories.map((cat) => _buildDropdown(cat)).toList(),
                ),
              ),
            ),
            
            // Camera preview
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _isCameraReady && _cameraController != null
                    ? CameraPreview(_cameraController!)
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            ),
            
            // Capture button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _takePhoto,
                  icon: const Icon(Icons.camera_alt, size: 32),
                  label: const Text(
                    'CAPTURE',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDropdown(Category category) {
    String selectedId = _selectedValues[category.name] ?? '';
    CategoryOption? selectedOption = category.options.firstWhere(
      (o) => o.id == selectedId,
      orElse: () => category.options.first,
    );
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              category.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: category.optional ? Colors.grey : Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  dropdownColor: Colors.grey[800],
                  items: category.options.map((opt) {
                    return DropdownMenuItem(
                      value: opt.id,
                      child: Text(
                        opt.customInput && _customValues[category.name] != null
                            ? '${opt.label}: ${_customValues[category.name]}'
                            : opt.label,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedValues[category.name] = value ?? '';
                    });
                    
                    // Show custom input dialog if needed
                    CategoryOption? opt = category.options.firstWhere(
                      (o) => o.id == value,
                      orElse: () => CategoryOption(id: '', label: '', output: ''),
                    );
                    if (opt.customInput) {
                      _showCustomInputDialog(category);
                    }
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
