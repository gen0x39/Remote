//
//  ViewController.swift
//  Remote
//
//  Created by shinji kikuchi on 2017/11/13.
//  Copyright © 2017年 shinji kikuchi. All rights reserved.
//

import UIKit
import Accounts     //twitterアカウント認証
import Social       //twitter機能利用


class ViewController: UIViewController {
    
    //--------------------------初期値の設定-------------------------
    //インターフェース定義
    @IBOutlet weak var RoomLabel: UILabel!   //室温表示用UI
    @IBOutlet weak var OutLabel: UILabel!    //外気温表示用UI
    @IBOutlet weak var SetLabel: UILabel!    //温度確認表示用UI
    @IBOutlet weak var TxT: UITextView!      //ツイート兼表示用
    @IBOutlet weak var state: UILabel!       //stateのUI
    
    //変数定義
    var RoomTmp:Int? = nil  //外気温(twitterから取得)
    var OutTmp:Int? = nil   //室温(twitterから取得)
    var Tmp:Int? = nil      //避難用(表示用)
    var BasicTxt:String = "#AirConditionER_Power  "  //デフォルトの文字
    var TweetTxt:String? = nil  //tweetするテキストの内容
    var St:Int = 100          //ON:(1),OFF:(-1)の管理(state)
    
    //デバッグ用
    var tmp:Int = 25
    
    
    var accountStore = ACAccountStore() //Twitter、Facebookなどの認証を行うクラス
    var twitterAccount: ACAccount? //Twitterのアカウントデータを格納する
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //アプリ実行時にTwitter認証を行うアカウントデータを取得
        getTwitterAccount()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //--------------------------ボタン制御--------------------------
    //温度上げる('+'が押された時実行)
    @IBAction func PlusBtnPush(sender: AnyObject) {
        if (tmp<28) {
            tmp += 1
            SetLabel.text = "\(tmp)℃"
        }
    }
    
    //温度下げる('-'が押された時実行)
    @IBAction func MinusBtnPush(sender: AnyObject) {
        if (tmp>18) {
            tmp -= 1
            SetLabel.text = "\(tmp)℃"
        }
    }
    
    //ツイートする('ON'が押された時実行)
    @IBAction func TouchTweet(sender: AnyObject) {
        //デバッグ用
        St = 1
        state.text = String(St)
        SetLabel.text = "電源ON"
        
        TweetTxt = BasicTxt + String(tmp) + " on"
        postTweet()
        //ツイートした後にアプリ表示用に加工
        TxT.text = String(tmp)+"℃に設定しました"
        
    }
    
    //ツイートする('OFF'が押された時実行)
    @IBAction func OffFunction(sender: AnyObject) {
        //デバック用
        St = -1
        state.text = String(St)
        SetLabel.text = "電源OFF"
        
        TweetTxt = BasicTxt + "off"
        postTweet()
        //ツイートした後にアプリ表示用に加工
        TxT.text = "電源を切ります"
        
    }
    
    
    
    //------------------------twitterの情報取得-------------------------
    private func getTwitterAccount() {
        
        //アカウントを取得するタイプをTwitterに設定する
        let accountType =
            accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        //Twitterのアカウントを取得する
        accountStore.requestAccessToAccountsWithType(accountType, options: nil)
        { (granted:Bool, error:NSError?) -> Void in
            
            if error != nil {
                // エラー処理
                print("error! \(error)")
                return
            }
            
            if !granted {
                print("error! Twitterアカウントの利用が許可されていません")
                return
            }
            
            // Twitterアカウント情報を取得
            let accounts = self.accountStore.accountsWithAccountType(accountType)
                as! [ACAccount]
            
            if accounts.count == 0 {
                print("error! 設定画面からアカウントを設定してください")
                return
            }
            
            // ActionSheetを表示
            self.selectTwitterAccount(accounts)
        }
    }
    
    
    private func selectTwitterAccount(accounts: [ACAccount]) {
        
        // ActionSheetのタイトルとメッセージを設定する
        let alert = UIAlertController(title: "Twitter",
                                      message: "アカウントを選択してください",
                                      preferredStyle: .ActionSheet)
        
        // アカウント選択のActionSheetを表示するボタン
        for account in accounts {
            alert.addAction(UIAlertAction(title: account.username, style: .Default,
                handler: { (action) -> Void in
                    
                    // 選択したTwitterアカウントのデータを変数に格納する
                    print("your select account is \(account)")
                    self.twitterAccount = account
            }))
        }
        
        // 表示する
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    // ツイートを投稿
    private func postTweet() {
        
        let URL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")
        
        
        /*
        // ツイートしたい文章をセット
        TxT.text = BasicTxt + "on  " + String(tmp)
        let params = ["status" : TxT.text]
        TxT.text = String(tmp)+"℃に設定しました"
        */
 
        // ツイートしたい文章をセット
        TxT.text = TweetTxt
        let params = ["status" : TxT.text]  //実質TweetTxt
        
        // リクエストを生成
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: .POST,
                                URL: URL,
                                parameters: params)
        
        // 取得したアカウントをセット
        request.account = twitterAccount
        
        // APIコールを実行
        request.performRequestWithHandler { (responseData, urlResponse, error) -> Void in
            
            if error != nil {
                print("error is \(error)")
            }
            else {
                // 結果の表示
                do {
                    let result = try NSJSONSerialization.JSONObjectWithData(responseData,
                        options: .AllowFragments) as! NSDictionary
                    
                    print("result is \(result)")
                    
                } catch {
                    return
                }
            }
        }
    }
    
 
    /*
     // タイムラインを取得する
     private func getTimeline() {
     let URL = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")
     
     // GET/POSTやパラメータに気をつけてリクエスト情報を生成
     let request = SLRequest(forServiceType: SLServiceTypeTwitter,
     requestMethod: .GET,
     URL: URL,
     parameters: nil)
     
     // 認証したアカウントをセット
     request.account = twitterAccount
     
     // APIコールを実行
     request.performRequestWithHandler { (responseData, urlResponse, error) -> Void in
     
     if error != nil {
     print("error is \(error)")
     }
     else {
     
     // デバッグ用
     
     /*
     // 結果の表示
     let result = NSJSONSerialization.JSONObjectWithData(responseData,
     options: .AllowFragments,
     error: nil)
     as NSArray
     println("result is \(result)")
     */
     
     do {
     let result = try NSJSONSerialization.JSONObjectWithData(responseData,
     options: .AllowFragments)
     for tweet in result as! [AnyObject] {
     print(tweet["text"] as! String)
     }
     } catch let error as NSError {
     print(error)
     }
     }
     }
     }
     */
    
    /*
    private func postTweet2() {
        
        let URL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")
        
        TxT.text = BasicTxt + "off"
        let params = ["status" : TxT.text]
        
        // リクエストを生成
        let request = SLRequest(forServiceType: SLServiceTypeTwitter,
                                requestMethod: .POST,
                                URL: URL,
                                parameters: params)
        
        // 取得したアカウントをセット
        request.account = twitterAccount
        
        // APIコールを実行
        request.performRequestWithHandler { (responseData, urlResponse, error) -> Void in
            
            if error != nil {
                print("error is \(error)")
            }
            else {
                // 結果の表示
                do {
                    let result = try NSJSONSerialization.JSONObjectWithData(responseData,
                        options: .AllowFragments) as! NSDictionary
                    
                    print("result is \(result)")
                    
                } catch {
                    return
                }
            }
        }
    }*/
}
