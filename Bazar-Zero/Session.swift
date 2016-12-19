//
//  Session.swift
//  Bazar-Zero
//
//  Created by Abrosimov Anton on 09.12.16.
//  Copyright © 2016 Abrosimov Anton. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RxSwift
class Session {
    public var nowLang : String?
    public var nowWord : String?
    public var langs : [String] = [String]()
    public var words = Variable([JSON]())
    init() {
        Alamofire.request(Api.getLangs)
            .responseJSON { response in
                if(response.result.error == nil) {
                    let js = JSON(response.result.value!)
                    if(js["code"] == JSON.null) {
                        for j in js {
                        self.langs.append(j.1.stringValue)
                        }
                    }
                    else {
                        self.Error(js["message"].stringValue)
                    }
                    self.nowLang = self.langs.first
                    print("Языков - " + String(self.langs.count))
                    SearchViewController.current?.lang.reloadAllComponents()
                }
                else {
                    self.Error("\(response.result.error!.localizedDescription)")
                }
        }
    }
    func Error(_ text : String) {
        
        let alertController = UIAlertController(title: "Ошибка!", message:
            text, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.default,handler: nil))
        
        SearchViewController.current?.present(alertController, animated: true, completion: nil)
    }
    func Lookup(_ word : String){
        var lang = ""
        if(nowLang != nil) {
        lang = nowLang!
        }
        Alamofire.request(Api.lookup("lang=" + lang + "&text=" + word.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))
            .responseJSON { response in
                if(response.result.error == nil) {
                    let js = JSON(response.result.value!)
                    print("JSON DEBUG \(js)")
                    var ok = false
                    if(js["code"] == JSON.null) {
                        if(js["def"] != JSON.null) {
                            if(js["def"][0]["tr"] != JSON.null) {
                                ok = true
                            }
                        }
                    }
                    else {
                        self.Error(js["message"].stringValue)
                    }
                    if(ok) {
                       self.words.value = js["def"][0]["tr"].array!
                        SearchViewController.current?.script.text = "[\(js["def"][0]["ts"].stringValue)]"
                        SearchViewController.current?.cop = self.words.value[0]["text"].stringValue
                    }
                    else {
                        self.words.value = [JSON]()
                        SearchViewController.current?.script.text = "[]"
                        SearchViewController.current?.cop = nil
                    }
                }
                else {
                    self.Error("\(response.result.error!.localizedDescription)")
                }

        }
    }
}

class Api {
    public static let key = "dict.1.1.20161209T130229Z.e0dcc6c930a79ce9.fe0ecbb0158070a59a27ab248560ffa5878af8d4"
    public static let url = "https://dictionary.yandex.net/api/v1/dicservice.json/"
    public static let getLangs = Api.url + "getLangs?key=" + Api.key
    public static func lookup(_ params : String) -> String{
        return Api.url + "lookup?ui=ru&key=" + Api.key + "&" + params
    }
}
