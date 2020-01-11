//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let window = UIWindow(windowScene: windowScene)

    let viewModel = WeatherViewModel(currentLocation: LocationProvider.shared.currentLocation)

    let rootVC = UIHostingController(rootView: WeatherView(viewModel: viewModel))
    window.rootViewController = rootVC
    window.makeKeyAndVisible()

    self.window = window
  }
}
