import 'package:flutter/material.dart';
import 'package:crm_train/utills/app_colors.dart';

class PhotoCaptureScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  final String? platformId;
  final String? areaName;
  final String? activityName;
  const PhotoCaptureScreen({super.key, required this.stationId, required this.stationName, this.platformId, this.areaName, this.activityName});

  @override
  Widget build(BuildContext context) {
    final capturedPhotos = [
      {'time': '08:00 AM', 'type': 'Before Photo', 'status': 'Uploaded'},
      {'time': '08:25 AM', 'type': 'After Photo', 'status': 'Uploaded'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('CAPTURE EVIDENCE', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('LOCATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('Station:  Bhopal Junction', style: TextStyle(fontSize: 12)),
                const Text('Platform: PF-1', style: TextStyle(fontSize: 12)),
                const Text('Area:     Toilet Block', style: TextStyle(fontSize: 12)),
                const Text('Activity: Cleaning', style: TextStyle(fontSize: 12)),
                const Text('Time:     08:00 AM', style: TextStyle(fontSize: 12)),
              ])),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                const Text('CAPTURE PHOTO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                  child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tap to capture', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ])),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  ChoiceChip(label: const Text('Before Photo', style: TextStyle(fontSize: 11)), selected: true, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('After Photo', style: TextStyle(fontSize: 11)), selected: false, onSelected: (_) {}),
                  const SizedBox(width: 8),
                  ChoiceChip(label: const Text('Evidence', style: TextStyle(fontSize: 11)), selected: false, onSelected: (_) {}),
                ]),
              ])),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                const Icon(Icons.info, color: kRailwayBlue, size: 18),
                const SizedBox(width: 8),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Timestamp:  08:00 AM', style: TextStyle(fontSize: 11)),
                  Text('GPS:  ✅ Verified at PF-1', style: TextStyle(fontSize: 11, color: Colors.green)),
                  Text('Quality:  ✅ Good', style: TextStyle(fontSize: 11, color: Colors.green)),
                ]),
              ])),
            ),
            const SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Remarks', hintText: 'Add photo remarks...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), isDense: true), maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.camera_alt), label: const Text('Capture Photo', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.save), label: const Text('Save', style: TextStyle(fontSize: 12))),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload), label: const Text('Upload', style: TextStyle(fontSize: 12))),
            ]),
            const SizedBox(height: 12),
            Card(
              elevation: 2, child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CAPTURED PHOTOS (2)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                ...capturedPhotos.map((p) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.image, color: kRailwayBlue),
                  title: Text('${p['time']} - ${p['type']}', style: const TextStyle(fontSize: 12)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(p['status']!, style: TextStyle(fontSize: 11, color: Colors.green)),
                    const SizedBox(width: 8),
                    const Text('View', style: TextStyle(fontSize: 11, color: kRailwayBlue)),
                  ]),
                )),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoGalleryScreen extends StatelessWidget {
  final String stationId;
  final String stationName;
  const PhotoGalleryScreen({super.key, required this.stationId, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EVIDENCE GALLERY', style: TextStyle(color: Colors.white)), backgroundColor: kRailwayBlue, iconTheme: const IconThemeData(color: Colors.white)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(child: DropdownButtonFormField(value: 'All Activities', decoration: const InputDecoration(labelText: 'Filter', isDense: true), items: ['All Activities', 'Cleaning', 'Inspection'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
              const SizedBox(width: 8),
              Expanded(child: TextField(decoration: InputDecoration(labelText: 'Search date...', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(6))), style: const TextStyle(fontSize: 12))),
            ]),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: 12,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _showPhotoDialog(context, i),
                child: Container(
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.image, size: 32, color: Colors.grey.shade500), const SizedBox(height: 4), Text('Photo ${i + 1}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, int index) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(height: 300, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey))),
        const SizedBox(height: 12),
        const Text('Photo Details', style: TextStyle(fontWeight: FontWeight.bold)),
        const Text('Date: 15-01-2024   Time: 08:00 AM', style: TextStyle(fontSize: 12)),
        const Text('Area: PF-1 Toilet Block', style: TextStyle(fontSize: 12)),
        const Text('Activity: Cleaning - Before Photo', style: TextStyle(fontSize: 12)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')), TextButton(onPressed: () {}, child: const Text('Download'))],
    ));
  }
}
