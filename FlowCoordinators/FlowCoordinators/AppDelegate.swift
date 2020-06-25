//
//  AppDelegate.swift
//  FlowCoordinators
//
//  Created by Joachim Kret on 25/06/2020.
//  Copyright © 2020 Joachim Kret. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var rootFlowController: FlowController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let presenter = NavigationPresenter()
        let mainFlowController = NavigationStackFlowController(presenter: presenter)
    
        let flowController = ViewFlowController()
        mainFlowController.set(flowController)
        rootFlowController = mainFlowController
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = presenter.navigationController
        window?.makeKeyAndVisible()
        
        return true
    }
}
