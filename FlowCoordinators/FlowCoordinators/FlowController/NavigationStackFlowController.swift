//
//  Created by Joachim Kret on 23/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

// MARK: - NavigationStackFlowController

final class NavigationStackFlowController: FlowController {
    
    private let presenter: NavigationPresenter
    private let stack = NavigationStack()
    
    init(presenter: NavigationPresenter = .init()) {
        self.presenter = presenter
    }
    
    override func start() -> UIViewController {
        return presenter.navigationController
    }
    
    // MARK: Operations
    
    func set(_ flowControllers: FlowController..., animated: Bool = true, completion: (() -> ())? = nil) {
        set(flowControllers, animated: animated, completion: completion)
    }
    
    func set(_ flowControllers: [FlowController], animated: Bool = true, completion: (() -> ())? = nil) {
        
        stack.set((flowControllers.map { $0.toNavigationItem(self) })) { (stack) in
            
            prepareParentChaining(for: flowControllers)
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .foreward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func push(_ flowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        let last = stack.items.last?.flowController
        stack.push(flowController.toNavigationItem(self)) { (stack) in
            
            prepareParentChaining(from: last ?? self, pushed: flowController)
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .foreward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func push(_ flowController: FlowController, from source: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        stack.push(flowController.toNavigationItem(self), from: source.toNavigationItem(self)) { (stack) in
            
            prepareParentChaining(from: source, pushed: flowController)
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .foreward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func pop(from flowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        stack.pop(from: flowController.toNavigationItem(self)) { (stack) in
            
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .backward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func pop(to flowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        stack.pop(to: flowController.toNavigationItem(self)) { (stack) in
            
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .backward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func replaceForeward(_ flowController: FlowController, with newFlowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        let sourceFlowController = flowController.parent ?? self
        stack.replace(flowController.toNavigationItem(self), with: newFlowController.toNavigationItem(self)) { (stack) in
            
            prepareParentChaining(from: sourceFlowController, replacedWith: newFlowController)
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .foreward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    func replaceBackward(_ flowController: FlowController, with newFlowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        
        let sourceFlowController = flowController.parent ?? self
        stack.replace(flowController.toNavigationItem(self), with: newFlowController.toNavigationItem(self)) { (stack) in
            
            prepareParentChaining(from: sourceFlowController, replacedWith: newFlowController)
            let descriptor = prepareNavigationDescriptor(for: stack)
            let animation: NavigationAnimation = animated ? .backward : .none
            presenter.present(descriptor: descriptor, animation: animation, completion: completion)
        }
    }
    
    private func interactiveTransitionCompleted(to flowController: FlowController) {
        stack.pop(to: flowController.toNavigationItem(self))
    }
    
    // MARK: Setup Parent Chaining
    
    private func prepareParentChaining(for flowControllers: [FlowController]) {
        var parent: FlowController = self
        flowControllers.forEach { (flowController) in
            flowController.addToParent(parent)
            parent = flowController
        }
    }
    
    private func prepareParentChaining(from sourceFlowController: FlowController, pushed pushedFlowController: FlowController) {
        pushedFlowController.addToParent(sourceFlowController)
    }
    
    private func prepareParentChaining(from sourceFlowController: FlowController, replacedWith replaceFlowController: FlowController) {
        replaceFlowController.addToParent(sourceFlowController)
    }
    
    // MARK: Prepare Descriptors
    
    private func prepareNavigationDescriptor(for stack: NavigationStack) -> NavigationDescriptor {
        
        let items: [NavigationItemDescriptor] = stack.items.map { item in
            prepareNavigationItemDescriptor(for: item.flowController)
        }
        
        return NavigationDescriptor(items: items)
    }
    
    private func prepareNavigationItemDescriptor(for flowController: NavigationFlowController) -> NavigationItemDescriptor {
        
        let viewController = flowController.viewController
        let willAppearHandler: (Bool) -> () = { [weak flowController] animated in
            flowController?._willPresentFlowController(animated: animated)
        }
        let didAppearHandler: (Bool) -> () = { [weak flowController] animated in
            flowController?._didPresentFlowController(animated: animated)
        }
        let shouldDismissHandler: () -> () = { [weak flowController] in
            flowController?._shouldDismissFlowController(isInteractive: false)
        }
        let shouldStartInteractiveTransition: () -> Bool = { [weak flowController] in
            return flowController?._shouldDismissFlowController(isInteractive: true) ?? false
        }
        let startInteractiveTransitionHandler: (NavigationTransitionInfo) -> () = { [weak flowController] _ in
            flowController?._didStartInteractiveTransition()
        }
        let changeInteractiveTransitionHandler: (NavigationTransitionInfo) -> () = { [weak flowController] info in
            flowController?._didChangeInteractiveTransition(isCancelled: info.isCancelled)
        }
        let completeInteractiveTransitionHandler: (NavigationTransitionInfo) -> () = { [weak self, weak flowController] info in
            if let flowController = flowController {
                if !info.isCancelled {
                    self?.interactiveTransitionCompleted(to: flowController)
                }
            }
            flowController?._didCompleteInteractiveTransition(isCancelled: info.isCancelled)
        }
        
        return NavigationItemDescriptor(
            viewController: viewController,
            willAppearHandler: willAppearHandler,
            didAppearHandler: didAppearHandler,
            shouldDismissHandler: shouldDismissHandler,
            shouldStartInteractiveTransition: shouldStartInteractiveTransition,
            startInteractiveTransitionHandler: startInteractiveTransitionHandler,
            changeInteractiveTransitionHandler: changeInteractiveTransitionHandler,
            completeInteractiveTransitionHandler: completeInteractiveTransitionHandler)
    }
}

// MARK: - FlowController to NavigationItem

extension FlowController {
    fileprivate func toNavigationItem(_ stack: NavigationStackFlowController) -> NavigationItem {
        let navigationFlowController = AnyNavigationFlowController.create(self)
        return NavigationItem(flowController: navigationFlowController, navigationStackFlowController: stack)
    }
}

// MARK: - NavigationItem

fileprivate final class NavigationItem: Hashable, CustomDebugStringConvertible {
    var id: FlowIdentifier { flowController.id }
    let flowController: NavigationFlowController
    let shouldResetNavigationStackFlowController: Bool
    
    var debugDescription: String {
        return "NavigationItem { id: \(id.value), flowController: \(flowController) }"
    }
    
    init(flowController: NavigationFlowController, navigationStackFlowController: NavigationStackFlowController) {
        self.flowController = flowController
        if flowController.navigationStackFlowController == nil {
            flowController.navigationStackFlowController = navigationStackFlowController
            shouldResetNavigationStackFlowController = true
        } else {
            shouldResetNavigationStackFlowController = false
        }
    }
    
    deinit {
        if shouldResetNavigationStackFlowController {
            flowController.navigationStackFlowController = nil
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.value)
    }
    
    static func == (lhs: NavigationItem, rhs: NavigationItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - NavigationStack

fileprivate final class NavigationStack {
    
    private(set) var items: [NavigationItem] = []
    var verbose: Bool = false
    
    func contains(_ id: FlowIdentifier) -> Bool {
        return items.first(where: { $0.id == id }) != nil
    }
    
    func contains(_ item: NavigationItem) -> Bool {
        return items.contains(item)
    }
    
    func index(of item: NavigationItem) -> Int? {
        return items.firstIndex(of: item)
    }

    func set(_ items: [NavigationItem], ifModified: (NavigationStack) -> () = { _ in }) {
        guard !items.isEmpty else {
            log("-> set prohibited, stack cannot be empty!")
            return
        }
        guard items.first(where: { contains($0) }) == nil else {
            log("-> set prohibited, one of flow controllers already on stack!")
            return
        }
        self.items = items
        ifModified(self)
    }
    
    func push(_ item: NavigationItem, ifModified: ((NavigationStack) -> ()) = { _ in }) {
        guard !contains(item) else {
            log("-> push prohibited, flow controller already on stack:", item.flowController)
            return
        }
        items.append(item)
        ifModified(self)
    }
    
    func push(_ item: NavigationItem, from source: NavigationItem, ifModified: ((NavigationStack) -> ()) = { _ in }) {
        guard !contains(item) else {
            log("-> push prohibited, flow controller already on stack:", item.flowController)
            return
        }
        guard let index = index(of: source) else {
            log("-> push prohibited, source flow controller not exists:", source.flowController)
            return
        }
        var newItems = Array(items[0...index])
        newItems.append(item)
        items = newItems
        ifModified(self)
    }
    
    func pop(from item: NavigationItem, ifModified: ((NavigationStack) -> ()) = { _ in }) {
        guard let index = index(of: item) else {
            log("-> pop prohibited, from flow controller not exists:", item.flowController)
            return
        }
        guard index > 0 else {
            log("-> pop prohibited, flow controllers stack cannot be empty!")
            return
        }
        items = Array(items[0..<index])
        ifModified(self)
    }
    
    func pop(to item: NavigationItem, ifModified: ((NavigationStack) -> ()) = { _ in }) {
        guard let index = index(of: item) else {
            log("-> pop prohibited, to flow controller not exists:", item.flowController)
            return
        }
        guard index < (items.count - 1) else {
            log("-> pop prohibited, flow controller already on top!")
            return
        }
        items = Array(items[0...index])
        ifModified(self)
    }
    
    func replace(_ item: NavigationItem, with newItem: NavigationItem, ifModified: ((NavigationStack) -> ()) = { _ in }) {
        guard !contains(newItem) else {
            log("-> replace prohibited, flow controller already on stack:", newItem.flowController)
            return
        }
        guard let index = index(of: item) else {
            log("-> replace prohibited, source flow controller not exists:", item.flowController)
            return
        }
        items = Array(items[0..<index])
        items.append(newItem)
        ifModified(self)
    }
    
    private func log(_ message: String, _ param: Any? = nil) {
        if verbose {
            if let param = param {
                print(message, "\n", param)
            } else {
                print(message)
            }
        }
    }
}

// MARK: - NavigationFlowController

class NavigationFlowController: FlowController {
    
    enum Animation {
        case push
        case pop
        case none
    }
        
    fileprivate weak var navigationStackFlowController: NavigationStackFlowController? {
        didSet {
            if navigationStackFlowController == nil {
                removeFromParent()
            }
        }
    }
    
    // MARK: Present / Transitions
    
    fileprivate func _willPresentFlowController(animated: Bool) {
        // Additional operations can be managed here
        // without any interuption for subclasses
        willPresentFlowController(animated: animated)
    }
    
    fileprivate func _didPresentFlowController(animated: Bool) {
        // Additional operations can be managed here
        // without any interuption for subclasses
        didPresentFlowController(animated: animated)
    }
    
    @discardableResult
    fileprivate func _shouldDismissFlowController(isInteractive: Bool) -> Bool {
        // Additional operations can be managed here
        // without any interuption for subclasses
        let isAllowed = shouldAllowDismissFlowCoordinator(isInteractive: isInteractive)
        if !isInteractive && isAllowed { popToPrevious() }
        return isAllowed
    }
    
    fileprivate func _didStartInteractiveTransition() {
        // Additional operations can be managed here
        // without any interuption for subclasses
        didStartInteractiveTransition()
    }
    
    fileprivate func _didChangeInteractiveTransition(isCancelled: Bool) {
        // Additional operations can be managed here
        // without any interuption for subclasses
        didChangeInteractiveTransition(isCancelled: isCancelled)
    }
    
    fileprivate func _didCompleteInteractiveTransition(isCancelled: Bool) {
        // Additional operations can be managed here
        // without any interuption for subclasses
        didCompleteInteractiveTransition(isCancelled: isCancelled)
    }
    
    /// Subclasses can override this method, base implementation is empty
    /// this can be also unbalanced (without invoking didPresentFlowController)
    /// when iteractive transition will be cancelled
    func willPresentFlowController(animated: Bool) {
    }
    
    /// Subclasses can override this method, base implementation is empty
    func didPresentFlowController(animated: Bool) {
    }
    
    /// Subclasses can override this method, base implementation returns true
    func shouldAllowDismissFlowCoordinator(isInteractive: Bool) -> Bool {
        return true
    }
    
    /// Invoked when interactive transition starts
    /// Subclasses can override this method, base implementation is empty
    func didStartInteractiveTransition() {
    }
    
    /// Invoked when interactive transition changes
    /// Subclasses can override this method, base implementation is empty
    func didChangeInteractiveTransition(isCancelled: Bool) {
    }
    
    /// Invoked when interactive transition completes
    /// Subclasses can override this method, base implementation is empty
    func didCompleteInteractiveTransition(isCancelled: Bool) {
    }
    
    // MARK: Navigation Operations
    
    final func push(_ viewController: UIViewController, animated: Bool = true, completion: (() -> ())? = nil) {
        let flowController = PlainFlowController(viewController: viewController)
        push(flowController, animated: animated, completion: completion)
    }

    final func push(_ flowController: FlowController, animated: Bool = true, completion: (() -> ())? = nil) {
        navigationStackFlowController?.push(flowController, from: self, animated: animated, completion: completion)
    }
    
    final func popToPrevious(animated: Bool = true, completion: (() -> ())? = nil) {
        navigationStackFlowController?.pop(from: self, animated: animated, completion: completion)
    }
    
    final func popToCurrent(animated: Bool = true, completion: (() -> ())? = nil) {
        navigationStackFlowController?.pop(to: self, animated: animated, completion: completion)
    }
    
    final func replace(with flowController: FlowController, animation: Animation = .push, completion: (() -> ())? = nil) {
        switch animation {
        case .push:
            navigationStackFlowController?.replaceForeward(self, with: flowController, animated: true, completion: completion)
        case .pop:
            navigationStackFlowController?.replaceBackward(self, with: flowController, animated: true, completion: completion)
        case .none:
            navigationStackFlowController?.replaceForeward(self, with: flowController, animated: false, completion: completion)
        }
    }
}

// MARK: - AnyNavigationFlowController

fileprivate class AnyNavigationFlowController: NavigationFlowController {
    
    private let flowController: FlowController
    
    static func create(_ flowController: FlowController) -> NavigationFlowController {
        if let navigationFlowController = flowController as? NavigationFlowController {
            return navigationFlowController
        } else {
            return AnyNavigationFlowController(flowController: flowController)
        }
        
    }
    
    private init(flowController: FlowController) {
        self.flowController = flowController
    }
    
    override func start() -> UIViewController {
        return flowController.viewController
    }
}
