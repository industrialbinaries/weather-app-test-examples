//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_SwiftUI

import Combine
import CombineTestExtensions
import XCTest

// MARK: - Setup

class WeatherViewModelTests: XCTestCase {
  struct MockError: Error {}

  var scheduler: TestScheduler!
  var cancellables: [AnyCancellable]!

  let mockLocations: [Coordinates] = [
    .init(latitude: 1, longitude: 1),
    .init(latitude: 2, longitude: 2),
    .init(latitude: 3, longitude: 3),
  ]

  let locale = Locale(identifier: "cs")

  let mockApi: WeatherViewModel.API = { _ in Empty(completeImmediately: false).eraseToAnyPublisher() }

  override func setUp() {
    super.setUp()
    scheduler = .init()
    cancellables = []
  }
}

// MARK: - Tests

extension WeatherViewModelTests {
  func testLocationCoordinatesArePropagatedCorrectly() {
    let location: AnyPublisher<LocationProvider.State, Never> = TestPublisher(scheduler, [
      (100, .value(.location(mockLocations[0]))),
      (200, .value(.location(mockLocations[1]))),
      (300, .value(.location(mockLocations[2]))),
    ]).eraseToAnyPublisher()

    var recordedLocations: [Coordinates] = []
    let api: WeatherViewModel.API = {
      recordedLocations.append($0)
      return Just<Weather>(.mock).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    let sut = WeatherViewModel(weatherAPI: api, currentLocation: location)

    _ = sut.$state
      .record(scheduler: scheduler, numberOfRecords: 3)
      .waitForRecords()

    XCTAssertEqual(recordedLocations, mockLocations)
  }

  func testErrorIsPropagated() {
    let location: AnyPublisher<LocationProvider.State, Never> = TestPublisher(scheduler, [
      (0, .value(.location(mockLocations[0]))),
      (100, .value(.error(MockError()))),
    ]).eraseToAnyPublisher()

    let sut = WeatherViewModel(weatherAPI: mockApi, locale: locale, currentLocation: location)
    let result = sut.$state
      .record(scheduler: scheduler, numberOfRecords: 2)
      .waitAndCollectTimedRecords()

    XCTAssertEqual(result, [
      (0, .value(.loading)),
      (100, .value(.error)),
    ])
  }

  func testLoadingIsPropagated() {
    let location: AnyPublisher<LocationProvider.State, Never> = TestPublisher(scheduler, [
      (0, .value(.location(mockLocations[0]))),
    ]).eraseToAnyPublisher()

    let api: WeatherViewModel.API = { _ in
      TestPublisher(self.scheduler, [(500, .value(Weather.mock))]).eraseToAnyPublisher()
    }

    let sut = WeatherViewModel(weatherAPI: api, locale: locale, currentLocation: location)
    let result = sut.$state
      .record(scheduler: scheduler, numberOfRecords: 2)
      .waitAndCollectTimedRecords()

    XCTAssertEqual(result, [
      (0, .value(.loading)),
      (500, .value(.loadedMock)),
    ])
  }

  func testSuccess() {
    let location: AnyPublisher<LocationProvider.State, Never> = TestPublisher(scheduler,
                                                                              [
                                                                                (0, .value(.loading)),
                                                                                (100, .value(.location(mockLocations[0]))),
                                                                              ]).eraseToAnyPublisher()

    let api: WeatherViewModel.API = { _ in
      TestPublisher(self.scheduler, [(200, .value(Weather.mock))]).eraseToAnyPublisher()
    }

    let sut = WeatherViewModel(weatherAPI: api, locale: locale, currentLocation: location)
    let result = sut.$state
      .record(scheduler: scheduler, numberOfRecords: 2)
      .waitAndCollectTimedRecords()

    XCTAssertEqual(result, [
      (0, .value(.loading)),
      (200, .value(.loadedMock)),
    ])
  }

  func testLikeDislikeButtonsPress() {
    let location: AnyPublisher<LocationProvider.State, Never> = TestPublisher(scheduler, [
      (100, .value(.location(mockLocations[0]))),
      (200, .value(.location(mockLocations[1]))),
      (300, .value(.location(mockLocations[2]))),
    ]).eraseToAnyPublisher()

    var recordedLocations: [Coordinates] = []
    let api: WeatherViewModel.API = {
      recordedLocations.append($0)
      return Just<Weather>(.mock).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    var likedWeather: Weather?
    var dislikedWeather: Weather?

    let storage: WeatherViewModel.Storage = { _weather, liked in
      if liked { likedWeather = _weather } else { dislikedWeather = _weather }
    }

    let sut = WeatherViewModel(weatherAPI: api, storage: storage, locale: locale, currentLocation: location)

    let likeButtonTap: AnyPublisher<Void, Never> = TestPublisher(scheduler, [
      (100, .value(())),
    ]).eraseToAnyPublisher()

    let dislikeButtonTap: AnyPublisher<Void, Never> = TestPublisher(scheduler, [
      (200, .value(())),
    ]).eraseToAnyPublisher()

    likeButtonTap
      .subscribe(sut.likeButtonTapped)
      .store(in: &cancellables)

    dislikeButtonTap
      .subscribe(sut.dislikeButtonTapped)
      .store(in: &cancellables)

    scheduler.resume()

    XCTAssertEqual(likedWeather, Weather.mock)
    XCTAssertEqual(dislikedWeather, Weather.mock)
  }
}

extension Weather {
  fileprivate static let mock: Weather = .init(
    description: "Mock weather",
    iconCode: "01",
    temperature: 15.123456,
    location: "Mock location"
  )
}

extension WeatherViewModel.State {
  static let loadedMock: WeatherViewModel.State = .loaded(
    weatherDescription: "Mock weather",
    temperature: "15,1\u{00a0}°C",
    icon: "☀️",
    location: "Mock location"
  )
}
