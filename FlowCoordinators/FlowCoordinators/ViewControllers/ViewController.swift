//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

open class ViewController: UIViewController {
    
    private(set) var appearFirstTime = true

    open override func viewWillAppear(_ animated: Bool) {
        
        if appearFirstTime {
            viewWillAppearFirstTime(animated)
        }
        
        super.viewWillAppear(animated)
    }
    
    open func viewWillAppearFirstTime(_ animated: Bool) {
        assert(appearFirstTime, "Should only be called on first time!")
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        
        if appearFirstTime {
            viewDidAppearFirstTime(animated)
            appearFirstTime = false
        }
        
        super.viewDidAppear(animated)
    }
    
    open func viewDidAppearFirstTime(_ animated: Bool) {
        assert(appearFirstTime, "Should only be called on first time!")
    }
    
}
