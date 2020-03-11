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

protocol WeatherViewModelType {
  // Outputs
  var state: Driver<WeatherViewModelState> { get }

  // Inputs
  var likeButtonTapped: PublishSubject<Void> { get }
  var dislikeButtonTapped: PublishSubject<Void> { get }
}

struct WeatherViewModel: WeatherViewModelType {
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

// MARK: View model without subscriptions

typealias StateMachineViewModelInput = (
  likeButtonTapped: Driver<Void>,
  dislikeButtonTapped: Driver<Void>
)
typealias StateMachineViewModelOutput = Driver<WeatherViewModelState>
typealias StateMachineViewModel = (
  @escaping WeatherViewModel.API,
  @escaping WeatherViewModel.Storage,
  Locale,
  Observable<LocationProvider.State>,
  StateMachineViewModelInput
) -> StateMachineViewModelOutput

func stateMachineViewModel(
  weatherAPI: @escaping WeatherViewModel.API,
  storage: @escaping WeatherViewModel.Storage = { _, _ in },
  locale: Locale = .current,
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

  let like = input.likeButtonTapped.asObservable().withLatestFrom(weather).map { weather -> WeatherViewModelState in
    storage(weather, true)
    return WeatherViewModelState(weather: weather, locale: locale, weatherFeedback: .like)
  }

  let dislike = input.dislikeButtonTapped.asObservable().withLatestFrom(weather).map { weather -> WeatherViewModelState in
    storage(weather, false)
    return WeatherViewModelState(weather: weather, locale: locale, weatherFeedback: .dislike)
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
