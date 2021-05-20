//
//  ViewController.swift
//  BottomCardView
//
//  Created by jylee-mac on 2021/05/20.
//

import UIKit

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func buttonClickAction(_ sender: Any) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "CardViewController") as? CardViewController else {
              assertionFailure("No view controller ID CardViewController in storyboard")
              return
          }
          
          // set the modal presentation to full screen, in iOS 13, its no longer full screen by default
          vc.modalPresentationStyle = .fullScreen
          
          // present the view controller modally without animation
          self.present(vc, animated: false, completion: nil)
    }
    
}

