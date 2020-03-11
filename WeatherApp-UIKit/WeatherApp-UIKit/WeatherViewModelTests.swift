//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_UIKit

import RxCocoa
import RxSwift
import RxTest
import XCTest

class WeatherViewModelTests: XCTestCase {
  // MARK: - Setup

  struct MockError: Error {}

  var scheduler: TestScheduler!
  var disposeBag: DisposeBag!

  let mockLocations: [Coordinates] = [
    .init(latitude: 1, longitude: 1),
    .init(latitude: 2, longitude: 2),
    .init(latitude: 3, longitude: 3),
  ]

  let locale = Locale(identifier: "cs")

  let mockApi: WeatherViewModel.API = { _ in .never() }

  let emptyInput: StateMachineViewModelInput = (Driver.never(), Driver.never())

  override func setUp() {
    super.setUp()
    scheduler = .init(initialClock: 0)
    disposeBag = .init()
  }

  func testLocationCoordinatesArePropagatedCorrectly() {
    let location = locationObservable(with: [
      .init(time: 100, value: .next(.location(mockLocations[0]))),
      .init(time: 200, value: .next(.location(mockLocations[1]))),
      .init(time: 300, value: .next(.location(mockLocations[2]))),
    ])

    var recordedLocations: [Coordinates] = []
    let api: WeatherViewModel.API = {
      recordedLocations.append($0)
      return .just(.mock)
    }

    let sut = stateMachineViewModel(weatherAPI: api, currentLocation: location, input: emptyInput)
    let result = scheduler.createObserver(WeatherViewModelState.self)
    sut.drive(result).disposed(by: disposeBag)

    scheduler.start()

    XCTAssertEqual(recordedLocations, mockLocations)
  }

  func testErrorIsPropagated() {
    let location = locationObservable(with: [
      .init(time: 0, value: .next(.loading)),
      .init(time: 100, value: .next(.error(MockError()))),
    ])

    let sut = stateMachineViewModel(weatherAPI: mockApi, locale: locale, currentLocation: location, input: emptyInput)
    let result = runAndObserve(sut)

    XCTAssertEqual(result.events, [
      .init(time: 0, value: .next(.loading)),
      .init(time: 100, value: .next(.error)),
    ])
  }

  func testLoadingIsPropagated() {
    let location = locationObservable(with: [
      .init(time: 0, value: .next(.location(mockLocations[0]))),
    ])

    let api: WeatherViewModel.API = { _ in
      self.scheduler
        .createColdObservable([.next(500, Weather.mock), .completed(500)])
        .asObservable()
    }

    let sut = stateMachineViewModel(weatherAPI: api, locale: locale, currentLocation: location, input: emptyInput)
    let result = runAndObserve(sut)

    XCTAssertEqual(result.events,
                   [
                     .init(time: 0, value: .next(.loading)),
                     .init(time: 500, value: .next(.loadedMock)),
                   ])
  }

  func testSuccess() {
    let location = locationObservable(with: [
      .init(time: 0, value: .next(.loading)),
      .init(time: 100, value: .next(.location(mockLocations[0]))),
    ])

    let api: WeatherViewModel.API = { _ in
      self.scheduler
        .createColdObservable([.init(time: 100, value: .next(Weather.mock))])
        .asObservable()
    }

    let sut = stateMachineViewModel(weatherAPI: api, locale: locale, currentLocation: location, input: emptyInput)
    let result = runAndObserve(sut)

    XCTAssertEqual(result.events, [
      .init(time: 0, value: .next(.loading)),
      .init(time: 100, value: .next(.loading)),
      .init(time: 200, value: .next(.loadedMock)),
    ])
  }

  func testLikeDislikeButtonsPress() {
    let location = locationObservable(with: [
      .init(time: 0, value: .next(.location(mockLocations[0]))),
    ])

    let api: WeatherViewModel.API = { _ in .just(.mock) }

    var likedWeather: Weather?
    var dislikedWeather: Weather?

    let storage: WeatherViewModel.Storage = { _weather, liked in
      if liked {
        likedWeather = _weather
      } else {
        dislikedWeather = _weather
      }
    }

    let likeButtonTap = scheduler
      .createColdObservable([.next(100, ())])
      .asDriver(onErrorJustReturn: ())

    let dislikeButtonTap = scheduler
      .createColdObservable([.next(200, ())])
      .asDriver(onErrorJustReturn: ())

    _ = stateMachineViewModel(weatherAPI: api, storage: storage, locale: locale, currentLocation: location, input: (likeButtonTap, dislikeButtonTap)).drive()

    scheduler.start()
    XCTAssertEqual(likedWeather, Weather.mock)
    XCTAssertEqual(dislikedWeather, Weather.mock)
  }
}

extension WeatherViewModelTests {
  func locationObservable(
    with events: [Recorded<Event<LocationProvider.State>>]
  ) -> Observable<LocationProvider.State> {
    return scheduler
      .createColdObservable(events)
      .asObservable()
  }

  func runAndObserve<T>(_ sut: Driver<T>) -> TestableObserver<T> {
    defer { scheduler.start() }
    let result = scheduler.createObserver(T.self)
    sut.drive(result).disposed(by: disposeBag)
    return result
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

extension WeatherViewModelState {
  static let loadedMock: WeatherViewModelState = .loaded(
    weatherDescription: "Mock weather",
    temperature: "15,1\u{00a0}°C",
    icon: "☀️",
    location: "Mock location",
    weatherFeedback: .notGiven
  )
}
