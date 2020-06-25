//
//  Created by Joachim Kret on 22/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

// MARK: FlowController

class FlowController {
    
    let id: FlowIdentifier
    lazy var wireframe: (FlowEvent) -> () = prepareWireframe()
    lazy var viewController: UIViewController = {
        isViewControllerLoaded = true
        return start()
    }()
    
    private(set) var isViewControllerLoaded: Bool = false
    private(set) weak var parent: FlowController?
    private var eventObservers: [String: AnyFlowEventHandler] = [:]
    private var eventHandlers: [String: AnyFlowEventHandler] = [:]

    // MARK: Init
    
    init(id: FlowIdentifier = .init()) {
        self.id = id
    }
    
    // MARK: Start
    
    func start() -> UIViewController {
        fatalError("Subclasses should override start() method!")
    }
}

// MARK: Observe & Handle for FlowEvent

extension FlowController {

    func observe<Event: FlowEvent>(_ event: Event.Type, observer: @escaping (Event) -> ()) {
        let flowEventHandler = AnyFlowEventHandler(observer)
        eventObservers[event.identifier] = flowEventHandler
    }
    
    func handle<Event: FlowEvent>(_ event: Event.Type, handler: @escaping (Event) -> ()) {
        let flowEventHandler = AnyFlowEventHandler(handler)
        eventHandlers[event.identifier] = flowEventHandler
    }
    
    func addToParent(_ parent: FlowController) {
        assert(self.parent == nil, "Unabled to add to parent - flow controller already installed to parent!")
        self.parent = parent
    }
    
    func removeFromParent() {
        self.parent = nil
    }
    
    private func prepareWireframe() -> (FlowEvent) -> () {
        return { [weak self] event in
            self?.accept(event)
        }
    }
    
    private func accept(_ event: FlowEvent) {
        assert(Thread.isMainThread, "FlowEvent should be always dispatched on main thread!")
        
        // observe event first
        let observer = eventObservers[event.identifier]
        observer?.handle(event)
        
        // handle event next, if found just break
        let handler = eventHandlers[event.identifier]
        if let handler = handler {
            handler.handle(event)
            return
        }
        
        // pass event to parent
        parent?.accept(event)
    }
}

// MARK: - Debug

extension FlowController {
    
    func dumpChaining(isInitial: Bool = true) {
        if isInitial {
            print("Chaining starting from:")
        }
        print("-> ", self)
        parent?.dumpChaining(isInitial: false)
    }
}

// MARK: - AnyFlowEventHandler

fileprivate final class AnyFlowEventHandler {
    
    private let canHandle: (FlowEvent) -> Bool
    private let handler: (FlowEvent) -> ()
    
    init<Event: FlowEvent>(_ handler: @escaping (Event) -> ()) {
        self.canHandle = { event in
            return (event as? Event) != nil
        }
        self.handler = { event in
            if let event = event as? Event {
                handler(event)
            }
        }
    }
    
    func canHandle(_ event: FlowEvent) -> Bool {
        canHandle(event)
    }
    
    func handle(_ event: FlowEvent) {
        handler(event)
    }
}
