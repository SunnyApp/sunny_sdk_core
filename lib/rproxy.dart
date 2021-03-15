import 'package:equatable/equatable.dart';
import 'package:sunny_sdk_core/model_exports.dart';

RProxyServer? _rp;

RProxyServer get rproxy =>
    _rp ??
    illegalState(
        "Proxy server instance not loaded.  Set it first using RProxyServer.initialize");

class RProxy {
  final RProxyServer server;
  final String path;
  final String proxiedUrl;

  RProxy(this.server, this.path, this.proxiedUrl);

  String call([String toProxy = "/"]) {
    if (!server.isProxied) {
      return toProxy.startsWith("/") ? "$proxiedUrl$toProxy" : toProxy;
    }
    final uri = toProxy.toUri()!;
    var url = "${server.baseUrl}/$path${uri.path}".trimEnd('/');
    if (uri.query.isNotNullOrBlank) {
      url += "?${uri.query}";
    }
    return url;
  }
}

class RProxyServer extends Equatable {
  static initialize(String baseUrl, {bool isProxied = true}) {
    _rp = RProxyServer(baseUrl, isProxied: isProxied);
  }

  final String baseUrl;
  final bool isProxied;
  RProxyServer(this.baseUrl, {this.isProxied = true});

  @override
  List<Object> get props => [baseUrl];

  @override
  bool get stringify => true;

  RProxy proxy(String path, String proxiedUrl) =>
      RProxy(this, path, proxiedUrl);
}
