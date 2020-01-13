//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import Foundation

extension WeatherViewModel {
  typealias API = (Coordinates) -> AnyPublisher<Weather, Error>
  typealias Storage = (Weather, _ liked: Bool) -> Void

  enum State: Equatable {
    case loading
    case loaded(
      weatherDescription: String,
      temperature: String,
      icon: String,
      location: String
    )
    case error
  }
}

extension WeatherViewModel.State {
  init(loadedWith weather: Weather, locale: Locale) {
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.numberFormatter.maximumFractionDigits = 1

    let measurement = Measurement(value: weather.temperature, unit: UnitTemperature.celsius)
    let temperature = formatter.string(from: measurement)

    self = .loaded(
      weatherDescription: weather.description,
      temperature: temperature,
      icon: weather.iconCode.asWeatherEmoji,
      location: weather.location
    )
  }
}

class WeatherViewModel: ObservableObject {
  // Outputs
  @Published fileprivate(set) var state: State = .loading

  // Inputs
  let likeButtonTapped: PassthroughSubject<Void, Never> = .init()
  let dislikeButtonTapped: PassthroughSubject<Void, Never> = .init()

  init(
    weatherAPI: @escaping API = WeatherAPI.loadWeatherData,
    storage: @escaping Storage = { print($0, $1) },
    locale: Locale = .current,
    currentLocation: AnyPublisher<LocationProvider.State, Never>
  ) {
    let weather = currentLocation
      .setFailureType(to: Error.self)
      .flatMap { location -> AnyPublisher<Weather, Error> in
        switch location {
        case .loading, .error:
          return Empty(completeImmediately: false).eraseToAnyPublisher()

        case let .location(location):
          return weatherAPI(location)
        }
      }
      .share()

    likeButtonTapped
      .setFailureType(to: Error.self)
      .combineLatest(weather)
      .map { ($0.1, liked: true) }
      .sink(receiveCompletion: { _ in }, receiveValue: { storage($0, $1) })
      .store(in: &cancellables)

    dislikeButtonTapped
      .setFailureType(to: Error.self)
      .combineLatest(weather)
      .map { ($0.1, liked: false) }
      .sink(receiveCompletion: { _ in }, receiveValue: { storage($0, $1) })
      .store(in: &cancellables)

    let loadingAndError = currentLocation
      .map { location -> State in
        switch location {
        case .error: return .error

        case .location, .loading:
          // `.location` also emits `loading` as a plaholder value until the API
          // call has finished
          return .loading
        }
      }

    Publishers
      .Merge(
        loadingAndError,
        weather
          .map { State(loadedWith: $0, locale: locale) }
          .replaceError(with: .error)
      )
      .receive(on: scheduler)
      .removeDuplicates()
      .dropFirst() // The first `.loading` comes from the initial value of `state`
      .assign(to: \.state, on: self)
      .store(in: &cancellables)
  }

  fileprivate var scheduler: DispatchQueue { .main }
  private var cancellables: [AnyCancellable] = []
}

// MARK: - Mocks

#if canImport(XCTest)

  /// A WeatherViewModel subclass used for mocking in tests.
  ///
  /// It doesn't react to inputs and allows setting the output state manually
  /// using the `set(state: State)` method.

  class TestViewModel: WeatherViewModel {
    /// Changes the value of the `state` property.
    func set(state: State) {
      self.state = state
    }

    init() {
      super.init(currentLocation: Empty(completeImmediately: false).eraseToAnyPublisher())
    }

    fileprivate override var scheduler: DispatchQueue { .init(label: "Test scheduler (inactive)") }
  }
#endif
