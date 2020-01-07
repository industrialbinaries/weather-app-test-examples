//
//  WeatherViewModel.swift
//  WeatherApp-UIKit
//
//  Created by Vojta on 04/01/2020.
//  Copyright © 2020 Industrial Binaries. All rights reserved.
//

import RxSwift
import RxCocoa
import CoreLocation

typealias IconAssetName = String

enum WeatherViewModelState: Equatable {
  case loading
  case loaded(
    weatherDescription: String,
    temperature: String,
    icon: String,
    location: String
  )
  case error
}

extension WeatherViewModelState {
  init(weather: Weather, locale: Locale) {
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

protocol WeatherViewModelType {
  // Outputs
  var state: Driver<WeatherViewModelState> { get }

  // Inputs
  var likeButtonTapped: PublishSubject<Void> { get }
  var dislikeButtonTapped: PublishSubject<Void> { get }
}

struct  WeatherViewModel: WeatherViewModelType {

  typealias API = (CLLocationCoordinate2D) -> Observable<Weather>
  typealias Storage = (Weather, _ liked: Bool) -> Void

  // Outputs
  let state: Driver<WeatherViewModelState>

  // Inputs
  let likeButtonTapped: PublishSubject<Void> = .init()
  let dislikeButtonTapped: PublishSubject<Void> = .init()

  init(
    weatherAPI: @escaping API = WeatherAPI.loadWeatherData,
    storage: @escaping Storage = { _, _ in },
    locale: Locale = .current,
    currentLocation: Observable<LocationProvider.State>
  ) {
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

    likeButtonTapped
      .withLatestFrom(weather)
      .map { ($0, liked: true) }
      .subscribe(onNext: storage)
      .disposed(by: disposeBag)

    dislikeButtonTapped
      .withLatestFrom(weather)
      .map { ($0, liked: false) }
      .subscribe(onNext: storage)
      .disposed(by: disposeBag)

    let loadingAndError: Observable<WeatherViewModelState> = currentLocation
      .map { location in
        switch location {
        case .error: return .error

        case .location, .loading:
          // `.location` also emits `loading` as a plaholder value until the API
          // call has finished
          return .loading
      }
    }

    state = Observable.merge(
      loadingAndError,
      weather.map { WeatherViewModelState(weather: $0, locale: locale) }
    ).asDriver(onErrorJustReturn: .error)
  }

  private let disposeBag = DisposeBag()
}
