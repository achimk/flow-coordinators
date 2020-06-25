//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

class PlainFlowController: FlowController {
    
    private let rootViewController: UIViewController
    
    init(viewController: UIViewController) {
        self.rootViewController = viewController
    }
    
    override func start() -> UIViewController {
        return rootViewController
    }
}
