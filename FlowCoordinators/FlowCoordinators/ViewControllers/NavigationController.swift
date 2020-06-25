//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

open class NavigationController: UINavigationController {
    
    public weak var navigationBarDelegate: UINavigationBarDelegate?
}

extension NavigationController: UINavigationBarDelegate {
    
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool {
        return navigationBarDelegate?.navigationBar?(navigationBar, shouldPush: item) ?? true
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem) {
        navigationBarDelegate?.navigationBar?(navigationBar, didPush: item)
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        return navigationBarDelegate?.navigationBar?(navigationBar, shouldPop: item) ?? true
    }
    
    public func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        navigationBarDelegate?.navigationBar?(navigationBar, didPop: item)
    }
}
