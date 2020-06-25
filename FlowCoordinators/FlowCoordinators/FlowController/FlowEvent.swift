//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import Foundation

protocol FlowEvent { }

extension FlowEvent {
    
    var identifier: String {
        return Self.identifier
    }
    
    static var identifier: String {
        return String(describing: self)
    }
}
