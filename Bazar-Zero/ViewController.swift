//
//  ViewController.swift
//  Bazar-Zero
//
//  Created by Abrosimov Anton on 09.12.16.
//  Copyright © 2016 Abrosimov Anton. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
class SearchViewController : ViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    public static var current : SearchViewController? = nil
    @IBOutlet weak var table: UITableView!
    @IBOutlet public var lang: UIPickerView!
    @IBOutlet weak var search: UISearchBar!
    @IBOutlet public var script: UILabel!
    @IBOutlet weak var copyInfo: UIButton!
    @IBAction func cpy(_ sender: AnyObject) {
        info = !info
        if(info == false) {
            copyInfo.setTitleColor(.red, for: .normal)
        }
        else {
            copyInfo.setTitleColor(.blue, for: .normal)
        }
    }
    public var cop : String?
    var info : Bool = true
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // pickerdatasource
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AppDelegate.session!.langs.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(AppDelegate.session!.langs[row])"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        AppDelegate.session!.nowLang = AppDelegate.session!.langs[row]
        if(search.text! != "") {
        AppDelegate.session!.Lookup(search.text!)
        }
    }
    let bag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        search.text = AppDelegate.session!.nowWord
        SearchViewController.current = self
        if(AppDelegate.session!.nowLang != nil) {
        lang.selectRow(AppDelegate.session!.langs.index(of: AppDelegate.session!.nowLang!)!, inComponent:  0, animated: false)
        }
        _ = search.rx.text
            .subscribe(onNext: {
                AppDelegate.session!.nowWord = self.search.text
                if($0! != "") {
                    AppDelegate.session!.Lookup("\($0!)")
                }
                else {
                    AppDelegate.session!.words.value = [JSON]()
                    self.script.text = "[]"
                    SearchViewController.current?.cop = nil
                }
        }).addDisposableTo(bag)
        AppDelegate.session!.words.asObservable().bindTo(self.table.rx.items(cellIdentifier: "Cell")) { row, js, cell in
            cell.textLabel?.text = js["text"].stringValue
            cell.detailTextLabel?.text = js["pos"].stringValue
        }.addDisposableTo(bag)
        table.rx.modelSelected(JSON.self).subscribe(onNext: {
            if(self.info) {
            CloserViewController.word = $0
            self.performSegue(withIdentifier: "Look", sender: self)
            }
            else {
                UIPasteboard.general.string = $0["text"].stringValue
                self.cpy(self)
            }
        }).addDisposableTo(bag)
    }
}
class CloserViewController : ViewController {
    let bag = DisposeBag()
    public static var word : JSON = JSON.null
    var props = Variable([Property]())
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var header: UINavigationItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        let word = CloserViewController.word
        CloserViewController.word = JSON.null
        header.title = word["text"].stringValue
        props.asObservable().bindTo(self.table.rx.items(cellIdentifier: "Cell2")) { row, prop, cell in
            cell.textLabel?.text = prop.name
            cell.detailTextLabel?.text = prop.params.joined(separator: "\n")
            }.addDisposableTo(bag)
        //props
        for str in CloserViewController.rus.keys {
        var propArray = [String]()
        for p in word[str] {
            propArray.append(p.1["text"].stringValue)
        }
            if(propArray.count > 0) {
        let prop = Property(name: CloserViewController.rus[str]!, params: propArray)
        props.value.append(prop)
            }
        }
        if(props.value.count > 0) {
        table.rowHeight = table.frame.height / CGFloat(props.value.count)
        }
    }
    static let rus = ["mean":"Значения","syn":"Синонимы","ex":"Примеры"]
}
struct Property {
    var name : String
    var params : [String]
}

