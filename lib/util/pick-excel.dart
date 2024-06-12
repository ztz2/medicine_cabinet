import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PickExcel extends StatefulWidget {
  String url;
  Function? onParsed;

  PickExcel({
    super.key,
    this.url = "assets/h5/pick-excel.html",
    this.onParsed,
  });

  @override
  State<PickExcel> createState() => _PickExcelState();
}

class _PickExcelState extends State<PickExcel> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // URL拦截处理
    // if (_url != null && _url.contains('')) {
    //   _url = _url.replaceAll(RegExp("/^http/"), "https");
    // }

    _initWebViewController();
    _initUrl();
  }

  _initWebViewController() {
    _webViewController = WebViewController()
      // 启用JS调用，设置非严格模式
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 设置16进制透明背景色
      ..setBackgroundColor(const Color(0x00000000))
      // 设置导航代理，用于URL的一些拦截处理
      ..setNavigationDelegate(
        NavigationDelegate(
          // 加载进度
          onProgress: (int progress) {},
          // 页面开始加载回调
          onPageStarted: (String url) {},
          // 页面加载完成回调，JS的执行在这里，Flutter可以动态的修改JS里面的代码
          onPageFinished: (String url) {},
          // WebView加载报错
          onWebResourceError: (WebResourceError error) {},
          // 控制WebView哪些页面可以打开，这里就可以做和 _backPreviewUrls 进行匹配，然后阻断跳转，回到flutter应用中
          // return NavigationDecision.prevent 阻断，不会打开下一个页面
          // return NavigationDecision.navigate 正常加载
          onNavigationRequest: (NavigationRequest request) {
            // if (
            //  request.url.startsWith('自定义Schema协议://xxxx')
            //  request.url.startsWith('https://www.youtube.com/')
            // ) {
            //   return NavigationDecision.prevent;
            // }
            // 例子
            // if (_backPreviewUrls.contains(request.url)) {
            //   // 返回
            //   Navigator.pop(context);
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel('pickExcelChannel', onMessageReceived: (data) {
        if (widget.onParsed != null) {
          widget.onParsed!(data.message);
        }
      });
  }

  _initUrl() async {
    var url = await rootBundle.loadString(widget.url);
    _webViewController.loadRequest(
        Uri.dataFromString(
          url,
          mimeType: 'text/html',
          encoding: Encoding.getByName('utf-8'),
        )
    );
  }

  pickExcel(base64Data) {
    _webViewController.runJavaScriptReturningResult('window.pickExcel("$base64Data");');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 0,
      child: WebViewWidget(
        controller: _webViewController,
      ),
    );
  }
}
