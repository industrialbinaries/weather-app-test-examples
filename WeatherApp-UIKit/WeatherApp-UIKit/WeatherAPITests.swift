//
//  WeatherApp - UIKit
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

@testable import WeatherApp_UIKit

import CoreLocation
import RxBlocking
import RxSwift
import XCTest

class WeatherAPITests: XCTestCase {
  let endpointURL = URL(string: "https://api.openweathermap.org/data/2.5/weather")!
  let latitude: Double = 123
  let longitude: Double = 321

  override class func setUp() {
    super.setUp()
    URLProtocol.registerClass(TestURLProtocol.self)
  }

  func testURLComposition() throws {
    var request: URLRequest?
    TestURLProtocol.mockResponses[endpointURL] = {
      request = $0
      return (.success(Data([])), 0) // Doesn't matter
    }

    _ = WeatherAPI
      .loadWeatherData(coordinates: .init(latitude: latitude, longitude: longitude))
      .toBlocking()
      .materialize()

    let sentRequest = try XCTUnwrap(request)
    let queryItems = URLComponents(url: sentRequest.url!, resolvingAgainstBaseURL: false)?.queryItems

    XCTAssertEqual(queryItems?["lat"], "\(latitude)")
    XCTAssertEqual(queryItems?["lon"], "\(longitude)")
    XCTAssertNotNil(queryItems?["APPID"])
    XCTAssertNotNil(queryItems?["units"])
  }

  func testSuccess() throws {
    TestURLProtocol.mockResponses[endpointURL] = { _ in (.success(WeatherAPI.sampleResponse), 200) }

    let result = try WeatherAPI
      .loadWeatherData(coordinates: .init(latitude: latitude, longitude: longitude))
      .toBlocking()
      .toArray()

    let expectedResult = Weather(
      description: "Clouds",
      iconCode: "04d",
      temperature: 3.72,
      location: "Nizbor"
    )

    XCTAssertEqual(result, [expectedResult])
  }

  func testServerError() throws {
    struct MockError: Error {}
    TestURLProtocol.mockResponses[endpointURL] = { _ in (.failure(MockError()), 440) }

    let result = WeatherAPI
      .loadWeatherData(coordinates: .init(latitude: latitude, longitude: longitude))
      .toBlocking()
      .materialize()

    switch result {
    case .completed: XCTFail()
    case let .failed(elements, error):
      XCTAssertEqual(elements, [])
      XCTAssert(error is MockError)
    }
  }
}

extension WeatherAPI {
  /// Sample response data loaded from the `WeatherAPISampleResponse.json` file.
  static let sampleResponse: Data = {
    class ThisBundleClass { /* A class from this bundle */ }
    let bundle = Bundle(for: ThisBundleClass.self)
    let url = bundle.url(forResource: "WeatherAPISampleResponse", withExtension: "json")!
    return try! Data(contentsOf: url)
  }()
}

extension Array where Element == URLQueryItem {
  /// Returns the value of the URLQueryItem with the given name. Returns `nil`
  /// if the query item doesn't exist.
  fileprivate subscript(_ name: String) -> String? {
    first(where: { $0.name == name }).flatMap { $0.value }
  }
}
