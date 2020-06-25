//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import Foundation

struct FlowIdentifier: Equatable, Hashable {
    
    let value: String
    
    init(_ id: String = UUID().uuidString) {
        self.value = id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(value)
    }
    
    static func ==(lhs: FlowIdentifier, rhs: FlowIdentifier) -> Bool {
        return lhs.value == rhs.value
    }
}
