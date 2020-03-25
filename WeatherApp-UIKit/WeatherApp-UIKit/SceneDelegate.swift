//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
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
    rootVC.viewModel = stateMachineViewModel

    window.rootViewController = rootVC
    window.makeKeyAndVisible()

    self.window = window
  }
}
