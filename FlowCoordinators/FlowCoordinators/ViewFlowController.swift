//
//  Created by Joachim Kret on 22/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

enum ViewWireframe: FlowEvent {
    case push
    case pop
    case replaceForward
    case repalceBackward
}

final class ViewFlowController: NavigationFlowController, CustomDebugStringConvertible {
    
    private let isRoot: Bool
    private var index: Int
    
    private var allowsInteractiveTransition = true
    private var allowsBackButton = true
    
    var debugDescription: String {
        return "ViewFlowCoordinator: { isRoot: \(isRoot), index: \(index) }"
    }
    
    init(isRoot: Bool = true, index: Int = 0) {
        self.isRoot = isRoot
        self.index = index
    }
    
    deinit {
        print("['] deinit flow controller: \(index)")
    }
    
    override func shouldAllowDismissFlowCoordinator(isInteractive: Bool) -> Bool {
        if isInteractive {
            let action = allowsInteractiveTransition ? "allowed" : "refused"
            print("-> interactive dismiss \(action) for flow controller:", index)
            return allowsInteractiveTransition
        } else {
            let action = allowsBackButton ? "allowed" : "refused"
            print("-> back dismiss \(action) for flow controller:", index)
            return allowsBackButton
        }
    }
    
    override func willPresentFlowController(animated: Bool) {
        print("-> will present flow controller:", index)
    }
    
    override func didPresentFlowController(animated: Bool) {
        print("-> did present flow controller:", index)
    }
    
    override func didStartInteractiveTransition() {
        print("-> did start interactive transition for flow controller:", index)
    }
    
    override func didChangeInteractiveTransition(isCancelled: Bool) {
        print("-> did change interactive transition for flow controller:", index)
    }

    override func didCompleteInteractiveTransition(isCancelled: Bool) {
        print("-> did complete interactive transition for flow controller:", index)
    }
    
    override func start() -> UIViewController {
        registerWireframe()
        return prepareViewController()
    }
    
    private func prepareViewController() -> UIViewController {
        let viewController = TemplateViewController()
        viewController.pushHandler = { [weak self] in self?.presentNext() }
        viewController.popHandler = { [ weak self] in self?.presentPrevious() }
        viewController.pushHeadHandler = { [weak self] in self?.wireframe(ViewWireframe.push) }
        viewController.popHeadHandler = { [weak self] in self?.wireframe(ViewWireframe.pop) }
        viewController.replaceCurrentForwardHandler = { [weak self] in self?.replaceCurrentForward() }
        viewController.replaceCurrentBackwardHandler = { [weak self] in self?.replaceCurrentBackward() }
        viewController.replaceHeadForwardHandler = { [weak self] in self?.wireframe(ViewWireframe.replaceForward) }
        viewController.replaceHeadBackwardHandler = { [weak self] in self?.wireframe(ViewWireframe.repalceBackward) }
        viewController.rawViewControllerHandler = { [weak self] in self?.presentRawViewController() }
        viewController.dumpChainingHandler = { [weak self] in self?.dumpChaining() }
        viewController.backButtonChangedHandler = { [weak self] in self?.allowsBackButton = $0 }
        viewController.interactiveBackChangedHandler = { [weak self] in self?.allowsInteractiveTransition = $0 }
        viewController.title = "\(index)"
        return viewController
    }
    
    private func registerWireframe() {
        
        guard isRoot else { return }
        
        handle(ViewWireframe.self) { [weak self] (event) in
            switch event {
            case .push:
                self?.presentNext()
            case .pop:
                self?.presentCurrent()
            case .replaceForward:
                self?.replaceCurrentForward()
            case .repalceBackward:
                self?.replaceCurrentBackward()
            }
        }
    }
    
    private func presentRawViewController() {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        push(viewController, completion: { print("-> raw UIViewController push completed") })
    }
    
    private func presentNext() {
        let flowController = createFlowController(isRoot: false)
        let index = flowController.index
        push(flowController, completion: { print("-> child flow controller push completed:", index) })
    }
    
    private func presentPrevious() {
        let index = self.index
        popToPrevious(completion: { print("-> pop from flow controller completed:", index) })
    }
    
    private func presentCurrent() {
        let index = self.index
        popToCurrent(completion: { print("-> pop to flow controller completed:", index) })
    }
    
    private func replaceCurrentForward() {
        let flowController = createFlowController(isRoot: isRoot)
        let isRoot = flowController.isRoot
        let index = flowController.index
        replace(with: flowController, animation: .push, completion: {
            print("-> replaced \(isRoot ? "root" : "child") flow controller completed:", index)
        })
    }
    
    private func replaceCurrentBackward() {
        let flowController = createFlowController(isRoot: isRoot)
        let isRoot = flowController.isRoot
        let index = flowController.index
        replace(with: flowController, animation: .pop, completion: {
            print("-> replaced \(isRoot ? "root" : "child") flow controller completed:", index)
        })
    }

    private func createFlowController(isRoot: Bool) -> ViewFlowController {
        let flowController = ViewFlowController(isRoot: isRoot, index: index + 1)
        return flowController
    }
}
