//
//  ViewController.swift
//  MySearchApp2
//
//  Created by 寺島 洋平 on 2019/08/08.
//  Copyright © 2019年 YoheiTerashima. All rights reserved.
//

import UIKit
import WebKit

// 商品ページを参照するための画面
class WebViewController: UIViewController {
    
    // 商品ページのURL
    var itemUrl: String?
    
    // 商品ページを参照するためのWebView
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // User-AgentをiPhoneに設定する
        webView.customUserAgent = "Mozilla/5.0 (iPhone: CPU iPhone OS 11_0_1 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A402 Safari/604.1"
        // WebViewのurlを読み込ませてWebページを表示させる
        guard let itemUrl = itemUrl else {
            return
        }
        guard let url = URL(string: itemUrl) else {
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

