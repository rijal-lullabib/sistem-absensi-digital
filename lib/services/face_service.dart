import 'dart:io';
import 'package:image/image.dart' as img;

/// Simple perceptual-like hash: downscale to tiny grayscale and join bytes.
String computeSimpleHash(File f) {
  final bytes = f.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) return '';
  final small = img.copyResize(image, width: 16, height: 16);
  final gray = img.grayscale(small);
  final sb = StringBuffer();
  for (var y = 0; y < gray.height; y++) {
    for (var x = 0; x < gray.width; x++) {
      final p = gray.getPixel(x, y);
      final l = img.getLuminance(p);
      sb.write(l.toInt().toRadixString(16).padLeft(2, '0'));
    }
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
