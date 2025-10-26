// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: unused_import
import 'dart:typed_data';
// ignore: unused_import
import 'dart:convert';

/// Compute a simple perceptual hash for web platform
Future<String> computeWebHash(String imagePath) async {
  final img = html.ImageElement(src: imagePath);
  await img.decode();
  
  final canvas = html.CanvasElement(width: 16, height: 16);
  final ctx = canvas.context2D;
  
  // Draw and resize image to 16x16
  ctx.drawImageScaled(img, 0, 0, 16, 16);
  
  // Get pixel data
  final imageData = ctx.getImageData(0, 0, 16, 16);
  final pixels = imageData.data;
  
  final sb = StringBuffer();
  for (var i = 0; i < pixels.length; i += 4) {
    // Convert RGB to grayscale
    final gray = (pixels[i] * 0.299 + pixels[i + 1] * 0.587 + pixels[i + 2] * 0.114).round();
    sb.write(gray.toRadixString(16).padLeft(2, '0'));
  }
  
  return sb.toString();
}

int hammingDistance(String a, String b) {
  if (a.length != b.length) return 1 << 30;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) diff++;
  }
  return diff;
}

/// Return matched employee index or -1 if none.
int matchHash(String probe, List<String> knownHashes, {int threshold = 60}) {
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