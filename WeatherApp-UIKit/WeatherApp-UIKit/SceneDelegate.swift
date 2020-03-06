//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import RxSwift
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
        
        let input: StateMachineViewModelInput = (rootVC.likeButton.rx.tap.asObservable(), rootVC.dislikeButton.rx.tap.asObservable())
        rootVC.viewModel = stateMachineViewModel(weatherAPI: WeatherAPI.loadWeatherData,
                                                 storage: { _, _ in print("saved") },
                                                 locale: .current,
                                                 currentLocation: LocationProvider.shared.currentLocation,
                                                 input: input)
        
        window.rootViewController = rootVC
        window.makeKeyAndVisible()
        
        self.window = window
    }
}
