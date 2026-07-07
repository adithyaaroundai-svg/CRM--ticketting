import 'dart:js' as js;

dynamic evalJs(String code) {
  return js.context.callMethod('eval', [code]);
}
