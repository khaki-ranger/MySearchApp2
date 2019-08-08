//
//  SearchItemTableViewController.swift
//  MySearchApp2
//
//  Created by 寺島 洋平 on 2019/08/08.
//  Copyright © 2019年 YoheiTerashima. All rights reserved.
//

import UIKit

class SearchItemTableViewController: UITableViewController, UISearchBarDelegate {
    
    var itemDataArray = [ItemData]()
    
    var imageChash = NSCache<AnyObject, UIImage>()
    
    // APIを利用するためのクライアントID
    let appid = "dj00aiZpPVdZbzU5TEsxREFoWiZzPWNvbnN1bWVyc2VjcmV0Jng9ZTU-"
    
    let entryUrl: String = "https://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch"
    
    // 数字を金額の形式に整形するためのフォーマッター
    let priceFormat = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 価格のフォーマット指定
        priceFormat.numberStyle = .currency
        priceFormat.currencyCode = "JPY"
    }
    
    // キーボードのsearchボタンがタップされたときに呼び出される
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        // 入力された文字の取り出し
        guard let inputText = searchBar.text else {
            // 入力なし
            return
        }
        
        // 入力文字数が0文字より多いかどうかチェックする
        guard inputText.lengthOfBytes(using: String.Encoding.utf8) > 0 else {
            // 0文字より多くはなかった
            return
        }
        
        // 保持している商品をいったん削除
        itemDataArray.removeAll()
        
        // パラメータを指定する
        let parameter = ["appid": appid, "query": inputText]
        
        // パラメータをエンコードしたURLを作成する
        let requestUrl = createRequestUrl(parameter: parameter)
        
        // APIをリクエストする
        request(requestUrl: requestUrl)
        
        // キーボードを閉じる
        searchBar.resignFirstResponder()
    }
    
    // パラメータのURLエンコード処理
    func encodeParameter(key: String, value: String) -> String? {
        // 値をエンコードする
        guard let escapedValue = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) else {
            // エンコード失敗
            return nil
        }
        // エンコードした値をkey=vakueの形式で返却する
        return "\(key)=\(escapedValue)"
    }
    
    // URL作成処理
    func createRequestUrl(parameter: [String: String]) -> String {
        var parameterString = ""
        for key in parameter.keys {
            // 値の取り出し
            guard let value = parameter[key] else {
                // 値なし
                // 次のfor分の処理を行う
                continue
            }
            // すでにパラメータが設定されていた場合
            if parameterString.lengthOfBytes(using: String.Encoding.utf8) > 0 {
                // パラメータ同時のセパレータである&を追加する
                parameterString += "&"
            }
            // 値をエンコードする
            guard let encodeValue = encodeParameter(key: key, value: value) else {
                // エンコード失敗
                // 次のfor分の処理を行う
                continue
            }
            // エンコードした値をパラメータとして追加する
            parameterString += encodeValue
        }
        let requestUrl = entryUrl + "?" + parameterString
        return requestUrl
    }
    
    // リクエストを行う
    func request(requestUrl: String) {
        // URL作成
        guard let url = URL(string: requestUrl) else {
            // URL作成失敗
            return
        }
        // リクエスト作成
        let request = URLRequest(url: url)
        // 商品検索APIをコールして商品検索を行う
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data: Data?, response:URLResponse?, error: Error?) in
            // 通信完了後の処理
            // エラーチェック
            guard error == nil else {
                // エラー表示
                let alert = UIAlertController(title: "エラー", message: error?.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                // UIに関する処理はメインスレッド上で行う
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            // JSONで返却されたデータをパースして格納する
            guard let data = data else {
                // データなし
                return
            }
            
            do {
                // パース実施
                let resultSet = try JSONDecoder().decode(ItemSearchResultSet.self, from: data)
                // 商品のリストに追加
                self.itemDataArray.append(contentsOf: resultSet.resultSet.firstObject.result.items)
            } catch let error {
                print("## error: \(error)")
            }
            
            // テーブルの描画処理を実施
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        // 通信開始
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    // テーブルのセクジョン数を取得
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    // セクション内の商品巣を取得
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemDataArray.count
    }

    // テーブルセルの取得処理
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemCell", for: indexPath) as? ItemTableViewCell else {
            return UITableViewCell()
        }
        
        let itemData = itemDataArray[indexPath.row]
        
        // 商品のタイトル設定
        cell.itemTitleLabel.text = itemData.name
        // 商品価格設定処理
        // 日本通過の形式で設定する
        let number = NSNumber(integerLiteral: Int(itemData.priceInfo.price!)!)
        cell.itemPriceLabel.text = priceFormat.string(from: number)
        // 商品のURL設定
        cell.itemUrl = itemData.url
        // 画像の設定処理
        // すでにセルに設定されている画像と同じかどうかチェックする
        // 画像がまだ設定されていない場合に処理を行う
        guard let itemImageUrl = itemData.imageInfo.medium else {
            // 画像なし
            return cell
        }
        // キャッシュの画像を取り出す
        if let cacheImage = imageChash.object(forKey: itemImageUrl as AnyObject) {
            // キャッシュ画像の設定
            cell.itemImageView.image = cacheImage
            return cell
        }
        // キャッスの画像がないためダウンロードする
        guard let url = URL(string: itemImageUrl) else {
            // urlが生成できなかった
            return cell
        }
        let request = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            guard error == nil else {
                // エラーあり
                return
            }
            guard let data = data else {
                // データが存在しない
                return
            }
            guard let image = UIImage(data: data) else {
                // imageが生成できなかった
                return
            }
            // ダウンロードした画像をキャッシュに登録しておく
            self.imageChash.setObject(image, forKey: itemImageUrl as AnyObject)
            // 画像はメインスレッド上で設定する
            DispatchQueue.main.async {
                cell.itemImageView.image = image
            }
        }
        // 画像の読み込み処理開始
        task.resume()

        return cell
    }
    
    // 商品をタップして次の画面に遷移する前の処理
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? ItemTableViewCell {
            if let webViewController = segue.destination as? WebViewController {
                // 商品ページのURLを設定する
                webViewController.itemUrl = cell.itemUrl
            }
        }
    }

}
