//
//  SceneDelegate.swift
//  WeatherApp-UIKit
//
//  Created by Vojta on 04/01/2020.
//  Copyright © 2020 Industrial Binaries. All rights reserved.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)

    let rootVC = UIStoryboard(name: "Main", bundle: nil)
      .instantiateInitialViewController() as! ViewController
    rootVC.viewModel = WeatherViewModel(currentLocation: LocationProvider.shared.currentLocation)

    window.rootViewController = rootVC
    window.makeKeyAndVisible()

    self.window = window
  }
}
