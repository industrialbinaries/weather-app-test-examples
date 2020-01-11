//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_SwiftUI

import CombineTestExtensions
import CoreLocation
import XCTest

class LocationProviderTests_: XCTestCase {
  var sut: LocationProvider!
  private var locationManager: TestLocationManager!

  override func setUp() {
    super.setUp()
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
    let recorder = sut.currentLocation.record(numberOfRecords: 2)

    locationManager.delegate?.locationManager?(locationManager, didChangeAuthorization: .denied)

    let records = recorder.waitAndCollectRecords()

    XCTAssertRecordedValues(records, [
      .loading,
      .error(LocationProvider.LocationServicesNotAllowed()),
    ])
  }

  func testNewLocationIsPropagated() {
    let recorder = sut.currentLocation.record(numberOfRecords: 2)

    let testLocation = Coordinates(latitude: 123, longitude: 456)
    locationManager.delegate?.locationManager?(
      locationManager,
      didUpdateLocations: [CLLocation(latitude: testLocation.latitude, longitude: testLocation.longitude)]
    )

    let records = recorder.waitAndCollectRecords()

    XCTAssertRecordedValues(records, [
      .loading,
      .location(testLocation),
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
