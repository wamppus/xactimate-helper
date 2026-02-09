import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';
import 'dart:typed_data';
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
  int _currentCameraIndex = 0;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  
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
  
  Future<void> _initCamera([int? cameraIndex]) async {
    await Permission.camera.request();
    await Permission.storage.request();
    
    if (cameras.isEmpty) return;
    
    int idx = cameraIndex ?? _currentCameraIndex;
    if (idx >= cameras.length) idx = 0;
    
    // Dispose previous controller
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }
    
    setState(() => _isCameraReady = false);
    
    _cameraController = CameraController(
      cameras[idx],
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      _minZoom = await _cameraController!.getMinZoomLevel();
      _maxZoom = await _cameraController!.getMaxZoomLevel();
      _currentZoom = _minZoom;
      _currentCameraIndex = idx;
      setState(() => _isCameraReady = true);
    } catch (e) {
      print('Camera init error: $e');
    }
  }
  
  void _switchCamera() {
    if (cameras.length < 2) return;
    int nextIndex = (_currentCameraIndex + 1) % cameras.length;
    _initCamera(nextIndex);
  }
  
  Future<void> _setZoom(double zoom) async {
    if (_cameraController == null) return;
    zoom = zoom.clamp(_minZoom, _maxZoom);
    await _cameraController!.setZoomLevel(zoom);
    setState(() => _currentZoom = zoom);
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
      
      // Read photo bytes and save to gallery
      final File photoFile = File(photo.path);
      final Uint8List bytes = await photoFile.readAsBytes();
      
      // Save to gallery with proper name
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: fileName,
      );
      
      print('Gallery save result: $result');
      
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
  
  String _getCameraLabel() {
    if (cameras.isEmpty || _currentCameraIndex >= cameras.length) return '?';
    var lens = cameras[_currentCameraIndex].lensDirection;
    var name = cameras[_currentCameraIndex].name.toLowerCase();
    
    // Front camera
    if (lens == CameraLensDirection.front) return '🤳';
    
    // Try to detect lens type from name/index
    // Camera order is usually: 0=main, 1=front, 2=ultrawide, 3=tele
    if (name.contains('wide') || name.contains('0.5') || name.contains('ultra')) return '0.5x';
    if (name.contains('tele') || name.contains('2x') || name.contains('3x')) return '2x';
    
    // Fallback: show camera index for back cameras
    if (lens == CameraLensDirection.back) {
      // Count which back camera this is
      int backIndex = 0;
      for (int i = 0; i < _currentCameraIndex; i++) {
        if (cameras[i].lensDirection == CameraLensDirection.back) backIndex++;
      }
      if (backIndex == 0) return '1x';
      if (backIndex == 1) return '0.5x';  // Usually ultrawide is 2nd back cam
      if (backIndex == 2) return '2x';
      return '${backIndex + 1}';
    }
    
    return '1x';
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
          // FULLSCREEN CAMERA with pinch-to-zoom
          Positioned.fill(
            child: GestureDetector(
              onScaleUpdate: (details) {
                double newZoom = _currentZoom * details.scale;
                _setZoom(newZoom);
              },
              child: _isCameraReady && _cameraController != null
                  ? CameraPreview(_cameraController!)
                  : Container(color: Colors.black, child: const Center(child: CircularProgressIndicator())),
            ),
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
          
          // RIGHT SIDE - Camera switch + Zoom
          Positioned(
            right: 16,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                // Camera switch button (tap to cycle through lenses)
                if (cameras.length > 1)
                  GestureDetector(
                    onTap: _switchCamera,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getCameraLabel(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${_currentCameraIndex + 1}/${cameras.length}',
                            style: const TextStyle(color: Colors.white60, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Zoom slider (vertical)
                if (_maxZoom > _minZoom)
                  Container(
                    height: 150,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Slider(
                        value: _currentZoom,
                        min: _minZoom,
                        max: _maxZoom,
                        onChanged: _setZoom,
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                      ),
                    ),
                  ),
                
                // Zoom level indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentZoom.toStringAsFixed(1)}x',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // BOTTOM CAPTURE BUTTON (compact)
          Positioned(
            bottom: 20,
            left: 60,
            right: 60,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _takePhoto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  elevation: 8,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 24),
                    SizedBox(width: 8),
                    Text('CAPTURE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
