//
//  Created by Joachim Kret on 24/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

struct NavigationDescriptor {
    let items: [NavigationItemDescriptor]
    
    var viewControllers: [UIViewController] {
        return items.map { $0.viewController }
    }
    
    func lastItemDescriptor(for viewController: UIViewController) -> NavigationItemDescriptor? {
        return items.reversed().first(where: { $0.viewController === viewController })
    }
    
    func lastItemDescriptor() -> NavigationItemDescriptor? {
        return items.last
    }
    
    func descriptorByDropLast() -> NavigationDescriptor {
        if items.count > 1 { return NavigationDescriptor(items: items.dropLast())}
        else { return self }
    }
}

struct NavigationItemDescriptor {
    var viewController: UIViewController
    var willAppearHandler: ((Bool) -> ())?
    var didAppearHandler: ((Bool) -> ())?
    var shouldDismissHandler: (() -> ())?
    var shouldStartInteractiveTransition: (() -> Bool)?
    var startInteractiveTransitionHandler: ((NavigationTransitionInfo) -> ())?
    var changeInteractiveTransitionHandler: ((NavigationTransitionInfo) -> ())?
    var completeInteractiveTransitionHandler: ((NavigationTransitionInfo) -> ())?
}

enum NavigationAnimation {
    case foreward
    case backward
    case none
}

class NavigationPresenter: NSObject, UINavigationControllerDelegate, UINavigationBarDelegate, UIGestureRecognizerDelegate {
    
    let navigationController: UINavigationController

    private var descriptor: NavigationDescriptor = .init(items: [])
    private var transitionInfo: NavigationTransitionInfo?
    private var completion: (() -> ())?
    
    override init() {
        let navigationController = NavigationController()
        self.navigationController = navigationController
        super.init()
        navigationController.delegate = self
        navigationController.navigationBarDelegate = self
    }
    
    // MARK: Present
    
    func present(descriptor: NavigationDescriptor, animation: NavigationAnimation, completion: (() -> ())? = nil) {
        self.completion = completion
        self.descriptor = descriptor
        let viewControllers = descriptor.viewControllers
        navigationController.interactivePopGestureRecognizer?.delegate = self
        
        switch animation {
        case .foreward:
            if navigationController.viewControllers.isEmpty {
                navigationController.viewControllers = viewControllers
            } else {
                navigationController.setViewControllers(viewControllers, animated: true)
            }
        case .backward:
            if let topViewController = navigationController.topViewController {
                navigationController.viewControllers = viewControllers + [topViewController]
                navigationController.popViewController(animated: true)
            } else {
                navigationController.viewControllers = viewControllers
            }
        case .none:
            navigationController.setViewControllers(viewControllers, animated: false)
        }
    }
    
    // MARK: Interactive
    
    private func handleInteractive(for navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        guard let itemDescriptor = descriptor.lastItemDescriptor(for: viewController) else {
            return
        }
        
        let transitionInfo = NavigationTransitionInfo(itemDescriptor)
        self.transitionInfo = transitionInfo
        let token = OnceToken { [weak self] in
            if transitionInfo.isInteractive == true, transitionInfo.isCancelled == false {
                if let descriptor = self?.descriptor {
                    self?.descriptor = descriptor.descriptorByDropLast()
                }
            }
            self?.transitionInfo = nil
        }
        let transitionCoordinator = navigationController.topViewController?.transitionCoordinator
        // FIXME: Should we get fromViewController by:
        // navigationController.transitionCoordinator?.viewController(forKey: .from)
        
        transitionCoordinator?.notifyWhenInteractionChanges({ (context) in
            transitionInfo.change(with: context)
        })
        
        transitionCoordinator?.animate(alongsideTransition: { (context) in
            transitionInfo.start(with: context)
        }, completion: { (context) in
            transitionInfo.complete(with: context)
            token.execute()
        })
    }
    
    // MARK: UINavigationControllerDelegate
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        handleInteractive(for: navigationController, willShow: viewController, animated: animated)
        descriptor.lastItemDescriptor(for: viewController)?.willAppearHandler?(animated)
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        descriptor.lastItemDescriptor(for: viewController)?.didAppearHandler?(animated)
        completion?()
        completion = nil
    }
    
    // MARK: UINavigationBarDelegate
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool {
        // no operation
        return false
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem) {
        // no operation
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool {
        descriptor.lastItemDescriptor()?.shouldDismissHandler?()
        return false
    }
    
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {
        // no operation
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if descriptor.items.count > 1 {
            return descriptor.lastItemDescriptor()?.shouldStartInteractiveTransition?() ?? false
        }
        return false
    }
}

final class NavigationTransitionInfo {

    enum State {
        case idle
        case started
        case changed
        case completed
    }
    
    private var state: State = .idle
    private let descriptor: NavigationItemDescriptor
    private(set) var isInterruptible: Bool = false
    private(set) var isInteractive: Bool = false
    private(set) var isCancelled: Bool = false
    private(set) var isAnimated: Bool = false
    var verbose: Bool = false
    
    init(_ descriptor: NavigationItemDescriptor) {
        self.descriptor = descriptor
    }
    
    func start(with context: UIViewControllerTransitionCoordinatorContext) {
        
        accept(.started) {
        
            isInterruptible = context.isInterruptible
            isInteractive = context.isInteractive
            isCancelled = context.isCancelled
            isAnimated = context.isAnimated
            
            ifInteractive {
                descriptor.startInteractiveTransitionHandler?(self)
            }
            
            logStart(context)
        }
    }
    
    func change(with context: UIViewControllerTransitionCoordinatorContext) {
        
        accept(.changed) {
            
            isInterruptible = context.isInterruptible
            isCancelled = context.isCancelled
            isAnimated = context.isAnimated
            
            ifInteractive {
                descriptor.changeInteractiveTransitionHandler?(self)
            }
            
            logChange(context)
        }
    }
    
    func complete(with context: UIViewControllerTransitionCoordinatorContext) {
        
        accept(.completed) {
            
            isInterruptible = context.isInterruptible
            isCancelled = context.isCancelled
            isAnimated = context.isAnimated
            
            ifInteractive {
                descriptor.completeInteractiveTransitionHandler?(self)
            }
            
            logComplete(context)
        }
    }
    
    private func accept(_ newState: State, then action: () -> ()) {
        switch (state, newState) {
        case (.idle, .started):
            self.state = newState
            action()
        case (.started, .changed):
            self.state = newState
            action()
        case (.changed, .completed):
            self.state = newState
            action()
        default:
            break
        }
    }
    
    private func ifInteractive(_ action: () -> ()) {
        if isInteractive {
            action()
        }
    }
    
    private func logStart(_ context: UIViewControllerTransitionCoordinatorContext) {
        log(title: "Start", context: context)
    }
    
    private func logChange(_ context: UIViewControllerTransitionCoordinatorContext) {
        log(title: "Change", context: context)
    }
    
    private func logComplete(_ context: UIViewControllerTransitionCoordinatorContext) {
        log(title: "Complete", context: context)
    }
    
    private func log(title: String, context: UIViewControllerTransitionCoordinatorContext) {
        guard verbose else { return }
        print("###################################")
        print("# \(title)")
        print("# is interruptible:", context.isInterruptible)
        print("# is interactive:", context.isInteractive)
        print("# is cancelled:", context.isCancelled)
        print("# is animated:", context.isAnimated)
        print("###################################")
    }
}

fileprivate final class OnceToken {
    
    private var handler: (() -> ())?

    init(_ handler: @escaping (() -> ())) {
        self.handler = handler
    }
    
    func execute() {
        handler?()
        handler = nil
    }
    
    func cancel() {
        handler = nil
    }
}
