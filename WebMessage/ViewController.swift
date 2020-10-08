//
//  ViewController.swift
//  WebMessage
//
//  Created by Jane Abernethy on 8/10/20.
//  Copyright © 2020 Jane Abernethy. All rights reserved.
//

import UIKit
import WebKit


struct WebMessage {
    let name: String
    let params: [String]
}

class ViewController: UIViewController {

    var changeColorFunction: WebMessage?
    
    let webview = WKWebView()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(webview)
       
        //1. Load the html into the webview
        let htmlPath = Bundle.main.path(forResource: "index", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
        webview.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl.deletingLastPathComponent())

        //2. set up the messaging - these lines are needed so that this file can recieve messages from the webview.
        //the "name changeColor" matches a snippet of code in the web code
        let contentController = self.webview.configuration.userContentController
        contentController.add(self, name: "changeColor")

        //3. adding a native button to the view, when the user presses it, tje function "changeBackgroundColor" will be called
        let button = UIButton(type: .roundedRect)
        button.addTarget(self, action: #selector(changeBackgroundColor(sender:)), for: .touchUpInside)
        button.frame = CGRect(x: 20, y: 300, width: self.view.frame.width-40, height: 80)
        button.setTitle("🎨 change color", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.systemFont(ofSize: 40)
        button.backgroundColor = .white
        self.view.addSubview(button)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webview.frame = self.view.bounds
    }

    @objc func changeBackgroundColor(sender: UIButton) {
        //8. called when the user presses the native "change color" button
        
        guard let changeColorInfo = changeColorFunction else { return }
        let colorList = ["red", "green", "blue", "orange", "magenta"]
        let selectedColor = colorList.randomElement()!
        
        let javascript = "\(changeColorInfo.name)('\(selectedColor)')"
        webview.evaluateJavaScript(javascript) { (_, error) in
            if let error = error {
                print(error)
            }
        }
    }
}

extension ViewController: WKScriptMessageHandler{
    
    //5. this is where the native code intercepts any messages sent from the webcode.
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }
        
        // 6.
        // a message will have a body which is a JSON dictionary, we can populate it with whatever we want.
        // I have populated this one with a dictionary to represent a javascript function the iOS app would want to call. I have given it a name (the name of the JS function) and a list of paramters that function would take.

        if let message = dict["message"] as? [String: Any], let functionName = message["function"] as? String, let params = message["params"] as? [String] {
            let webMessage = WebMessage(name: functionName, params: params)
            if webMessage.name == "changeBackgroundColor" {
                //7.
                //if the webMessage has a name of "changeBackgroundColor" I store it in our "changeColorFunction" to call when we press the change color button
                changeColorFunction = webMessage
            }
        }
    }
}
