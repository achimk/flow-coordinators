//
//  Created by Joachim Kret on 12/03/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

class TemplateViewController: UIViewController {
    
    @IBOutlet private weak var pushButton: UIButton!
    @IBOutlet private weak var popButton: UIButton!
    
    @IBOutlet private weak var pushHeadButton: UIButton!
    @IBOutlet private weak var popHeadButton: UIButton!
    
    @IBOutlet private weak var replaceCurrentForwardButton: UIButton!
    @IBOutlet private weak var replaceCurrentBackwardButton: UIButton!
    
    @IBOutlet private weak var replaceHeadForwardButton: UIButton!
    @IBOutlet private weak var replaceHeadBackwardButton: UIButton!
    
    @IBOutlet private weak var rawViewControllerButton: UIButton!
    @IBOutlet private weak var dumpChainingButton: UIButton!
    
    @IBOutlet private weak var backButtonSwitch: UISwitch!
    @IBOutlet private weak var interactiveBackSwitch: UISwitch!
    
    @IBAction func push() {
        pushHandler?()
    }
    
    @IBAction func pop() {
        popHandler?()
    }
    
    @IBAction func pushHead() {
        pushHeadHandler?()
    }
    
    @IBAction func popHead() {
        popHeadHandler?()
    }
    
    @IBAction func replaceCurrentForward() {
        replaceCurrentForwardHandler?()
    }
    
    @IBAction func replaceCurrentBackward() {
        replaceCurrentBackwardHandler?()
    }
    
    @IBAction func replaceHeadForward() {
        replaceHeadForwardHandler?()
    }
    
    @IBAction func replaceHeadBackward() {
        replaceHeadBackwardHandler?()
    }
    
    @IBAction func rawViewController() {
        rawViewControllerHandler?()
    }
    
    @IBAction func dumpChaining() {
        dumpChainingHandler?()
    }
    
    @IBAction func backButtonChanged() {
        backButtonChangedHandler?(backButtonSwitch.isOn)
    }
    
    @IBAction func interactiveBackChanged() {
        interactiveBackChangedHandler?(interactiveBackSwitch.isOn)
    }
    
    var pushHandler: (() -> ())?
    var popHandler: (() -> ())?
    
    var pushHeadHandler: (() -> ())?
    var popHeadHandler: (() -> ())?
    
    var replaceCurrentForwardHandler: (() -> ())?
    var replaceCurrentBackwardHandler: (() -> ())?
    
    var replaceHeadForwardHandler: (() -> ())?
    var replaceHeadBackwardHandler: (() -> ())?
    
    var rawViewControllerHandler: (() -> ())?
    var dumpChainingHandler: (() -> ())?
    
    var backButtonChangedHandler: ((Bool) -> ())?
    var interactiveBackChangedHandler: ((Bool) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

}

