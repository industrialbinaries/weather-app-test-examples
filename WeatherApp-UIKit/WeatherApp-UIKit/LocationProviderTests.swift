//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_UIKit

import CoreLocation
import RxSwift
import RxTest
import XCTest

class LocationProviderTests: XCTestCase {
  var scheduler: TestScheduler!
  var disposeBag: DisposeBag!

  var sut: LocationProvider!
  private var locationManager: TestLocationManager!

  override func setUp() {
    super.setUp()
    disposeBag = .init()
    scheduler = .init(initialClock: 0)
    locationManager = TestLocationManager()
    sut = LocationProvider(locationManager: locationManager)
  }

  func testRequestWhenInUseAuthorizationIsCalled() {
    XCTAssertTrue(locationManager.requestWhenInUseAuthorizationCalled)
  }

  func testMonitoringStartsWithSuccessfullAthorizationStatus() {
    locationManager.delegate?.locationManager?(locationManager, didChangeAuthorization: .authorizedWhenInUse)
    XCTAssertTrue(locationManager.startMonitoringSignificantLocationChangesCalled)
  }

  func testErrorIsEmmitedWhenAthorizationStatusFailes() {
    let locations = scheduler.createObserver(LocationProvider.State.self)

    sut.currentLocation
      .subscribe(locations)
      .disposed(by: disposeBag)

    locationManager.delegate?.locationManager?(locationManager, didChangeAuthorization: .denied)

    XCTAssertEqual(locations.events, [
      .next(0, .loading),
      .next(0, .error(LocationProvider.LocationServicesNotAllowed())),
    ])
  }

  func testNewLocationIsPropagated() {
    let locations = scheduler.createObserver(LocationProvider.State.self)

    sut.currentLocation
      .subscribe(locations)
      .disposed(by: disposeBag)

    let testLocation = Coordinates(latitude: 123, longitude: 456)
    locationManager.delegate?.locationManager?(
      locationManager,
      didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)]
    )

    XCTAssertEqual(locations.events, [
      .next(0, .loading),
      .next(0, .location(testLocation)),
    ])
  }
}

private class TestLocationManager: CLLocationManager {
  var requestWhenInUseAuthorizationCalled = false
  override func requestWhenInUseAuthorization() {
    requestWhenInUseAuthorizationCalled = true
  }

  var startMonitoringSignificantLocationChangesCalled = false
  override func startMonitoringSignificantLocationChanges() {
    startMonitoringSignificantLocationChangesCalled = true
  }
}
