//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import CoreLocation

struct Weather: Equatable {
  let description: String
  let iconCode: String
  let temperature: Double
  let location: String
}

extension String {
  var asWeatherEmoji: String {
    let code = prefix(while: { $0.isNumber })
    switch code {
    case "01": return "☀️"
    case "02": return "🌤"
    case "03": return "🌥"
    case "04": return "☁️"
    case "09": return "🌧"
    case "10": return "🌦"
    case "11": return "⛈"
    case "13": return "🌨"
    case "50": return "🌫"
    default: return "☀️"
    }
  }
}

enum WeatherAPI {
  static func loadWeatherData(coordinates: CLLocationCoordinate2D) -> AnyPublisher<Weather, Error> {
    let request = createRequest(for: coordinates)
    return URLSession.shared
      .dataTaskPublisher(for: request)
      .map { $0.data }
      .decode(type: WeatherResponseDTO.self, decoder: JSONDecoder())
      .map {
        Weather(
          description: $0.weather[0].main,
          iconCode: $0.weather[0].icon,
          temperature: $0.main.temp,
          location: $0.name
        )
      }
      .eraseToAnyPublisher()
  }

  private static func createRequest(for coordinates: CLLocationCoordinate2D) -> URLRequest {
    let baseURL = URL(string: "https://api.openweathermap.org/data/2.5/weather")!
    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.queryItems = [
      .init(name: "APPID", value: "c24e21ebebee093dc832ddc161134d91"),
      .init(name: "units", value: "metric"),
      .init(name: "lat", value: "\(coordinates.latitude)"),
      .init(name: "lon", value: "\(coordinates.longitude)"),
    ]
    return URLRequest(url: components.url!)
  }
}

private struct WeatherResponseDTO: Codable {
  struct Weather: Codable {
    let main: String
    let icon: String
  }

  let weather: [Weather]

  let name: String

  struct MainDetails: Codable {
    let temp: Double
  }

  let main: MainDetails
}
