import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

void triggerDownload(List<int> bytes, String fileName) {
  final uint8 = Uint8List.fromList(bytes);
  final blob = web.Blob(
    [uint8.toJS].toJS,
    web.BlobPropertyBag(type: 'application/zip'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
