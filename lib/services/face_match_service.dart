import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A simple face matching service that works on both web and mobile
class FaceMatchService {
  /// Compute a perceptual hash from an image
  static Future<String> computeImageHash(ui.Image image) async {
    // Resize image to 16x16
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, 16, 16),
      Paint()..filterQuality = FilterQuality.low,
    );
    
    final picture = recorder.endRecording();
    final smallImage = await picture.toImage(16, 16);
    
    // Get pixel data
    final byteData = await smallImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return '';
    
    final pixels = byteData.buffer.asUint8List();
    final sb = StringBuffer();
    
    // Convert to grayscale and compute hash
    for (var i = 0; i < pixels.length; i += 4) {
      final gray = (pixels[i] * 0.299 + pixels[i + 1] * 0.587 + pixels[i + 2] * 0.114).round();
      sb.write(gray.toRadixString(16).padLeft(2, '0'));
    }
    
    return sb.toString();
  }
  
  /// Compare two hashes and return their Hamming distance
  static int hammingDistance(String a, String b) {
    if (a.length != b.length) return 1 << 30;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) diff++;
    }
    return diff;
  }
  
  /// Find the best match among known hashes
  static int matchHash(String probe, List<String> knownHashes, {int threshold = 60}) {
    var best = -1;
    var bestScore = 1 << 30;
    for (var i = 0; i < knownHashes.length; i++) {
      final d = hammingDistance(probe, knownHashes[i]);
      if (d < bestScore) {
        bestScore = d;
        best = i;
      }
    }
    if (bestScore <= threshold) return best;
    return -1;
  }

  /// Compute face hash from image file path
  static Future<String> computeFaceHash(String imagePath) async {
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return computeImageHash(frame.image);
  }
}
