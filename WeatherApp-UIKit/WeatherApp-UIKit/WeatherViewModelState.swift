//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Foundation

enum WeatherFeedback {
  case notGiven, like, dislike
}

enum WeatherViewModelState: Equatable {
  case loading
  case loaded(
    weatherDescription: String,
    temperature: String,
    icon: String,
    location: String,
    weatherFeedback: WeatherFeedback
  )
  case error
}

extension WeatherViewModelState {
  init(weather: Weather, locale: Locale, weatherFeedback: WeatherFeedback = .notGiven) {
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
