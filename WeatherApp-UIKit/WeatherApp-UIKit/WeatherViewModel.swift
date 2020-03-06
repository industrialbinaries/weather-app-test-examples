//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import CoreLocation
import RxCocoa
import RxSwift

typealias IconAssetName = String

enum WeatherViewModelState: Equatable {
  case loading
  case loaded(
    weatherDescription: String,
    temperature: String,
    icon: String,
    location: String,
    weatherFeedback: Bool?
  )
  case error
  
  static func == (lhs: WeatherViewModelState, rhs: WeatherViewModelState) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading), (.error, .error):
      return true
    case (let .loaded(lhsDesc, lhsTemp, lhsIcon, lhsLocation, _), let .loaded(rhsDesc, rhsTemp, rhsIcon, rhsLocation, _)):
      return (lhsDesc, lhsTemp, lhsIcon, lhsLocation) == (rhsDesc, rhsTemp, rhsIcon, rhsLocation)
    default:
      return false
    }
  }
}

extension WeatherViewModelState {
  init(weather: Weather, locale: Locale, weatherFeedback: Bool? = nil) {
    let formatter = MeasurementFormatter()
    formatter.locale = locale
    formatter.numberFormatter.maximumFractionDigits = 1
    
    let measurement = Measurement(value: weather.temperature, unit: UnitTemperature.celsius)
    let temperature = formatter.string(from: measurement)
    
    self = .loaded(
      weatherDescription: weather.description,
      temperature: temperature,
      icon: weather.iconCode.asWeatherEmoji,
      location: weather.location,
      weatherFeedback: weatherFeedback
    )
  }
}

typealias API = (CLLocationCoordinate2D) -> Observable<Weather>
typealias Storage = (Weather, _ liked: Bool) -> Void
typealias StateMachineViewModelInput = (
  likeButtonTapped: Observable<Void>,
  dislikeButtonTapped: Observable<Void>
)
typealias StateMachineViewModelOutput = Driver<WeatherViewModelState>
typealias StateMachineViewModel = (
  @escaping API,
  @escaping Storage,
  Locale,
  Observable<LocationProvider.State>,
  StateMachineViewModelInput
  ) -> StateMachineViewModelOutput

func stateMachineViewModel(
  weatherAPI: @escaping API,
  storage: @escaping Storage,
  locale: Locale,
  currentLocation: Observable<LocationProvider.State>,
  input: StateMachineViewModelInput
) -> StateMachineViewModelOutput {
  let currentLocation = currentLocation.share()
  
  let weather: Observable<Weather> = currentLocation
    .flatMap { location -> Observable<Weather> in
      switch location {
      case .loading, .error:
        return Observable.never()
        
      case let .location(location):
        return weatherAPI(location)
      }
  }
  .share()
  
  let loadingAndError: Observable<WeatherViewModelState> = currentLocation
    .map { location in
      switch location {
      case .error: return .error
        
      case .location, .loading:
        return .loading
      }
  }
  
  let like = input.likeButtonTapped.withLatestFrom(weather).map { weather -> WeatherViewModelState in
    storage(weather, true)
    return WeatherViewModelState(weather: weather, locale: locale, weatherFeedback: true)
  }
  
  let dislike = input.dislikeButtonTapped.withLatestFrom(weather).map { weather -> WeatherViewModelState in
    storage(weather, false)
    return WeatherViewModelState(weather: weather, locale: locale, weatherFeedback: true)
  }
  
  let state = Observable.merge(
    loadingAndError,
    like,
    dislike,
    weather.map { WeatherViewModelState(weather: $0, locale: locale) }
  )
    .asDriver(onErrorJustReturn: .error)
  
  return state
}
