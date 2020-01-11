//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import CoreLocation

typealias Coordinates = CLLocationCoordinate2D

extension Coordinates: Equatable {
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
  }
}

extension LocationProvider {
  enum State {
    case loading
    case location(Coordinates)
    case error(Error)
  }

  struct LocationServicesNotAllowed: Error {
    let localizedDescription = "User didn't allow location services."
  }
}

extension LocationProvider.State: Equatable {
  static func == (lhs: LocationProvider.State, rhs: LocationProvider.State) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading): return true
    case let (.location(l), .location(r)): return l == r
    case let (.error(l), .error(r)):
      return l.localizedDescription == r.localizedDescription
    default: return false
    }
  }
}

class LocationProvider: NSObject {
  /// The shared location provider for this app
  static let shared = LocationProvider()

  var currentLocation: AnyPublisher<State, Never> { _currentLocation.eraseToAnyPublisher() }

  init(locationManager: CLLocationManager = .init()) {
    self.locationManager = locationManager

    super.init()

    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
  }

  private let _currentLocation: CurrentValueSubject<State, Never> = .init(.loading)
  private let locationManager: CLLocationManager
}

extension LocationProvider: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    _currentLocation.send(.error(error))
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedAlways, .authorizedWhenInUse:
      manager.startMonitoringSignificantLocationChanges()
    case .notDetermined:
      break // User is presented with the system alert
    default:
      _currentLocation.send(.error(LocationServicesNotAllowed()))
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let location = locations.first else { return }
    _currentLocation.send(.location(location.coordinate))
  }
}
