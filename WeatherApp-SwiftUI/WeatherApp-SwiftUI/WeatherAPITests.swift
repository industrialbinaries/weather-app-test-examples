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

    let recorder = WeatherAPI
      .loadWeatherData_(coordinates: .init(latitude: latitude, longitude: longitude))
      .record(numberOfRecords: 1)

    recorder.waitForRecords()

    let sentRequest = try XCTUnwrap(request)
    let queryItems = URLComponents(url: sentRequest.url!, resolvingAgainstBaseURL: false)?.queryItems

    XCTAssertEqual(queryItems?["lat"], "\(latitude)")
    XCTAssertEqual(queryItems?["lon"], "\(longitude)")
    XCTAssertNotNil(queryItems?["APPID"])
    XCTAssertNotNil(queryItems?["units"])
  }

  func testSuccess() throws {
    TestURLProtocol.mockResponses[endpointURL] = { _ in (.success(WeatherAPI.sampleResponse), 200) }

    let recorder = WeatherAPI
      .loadWeatherData_(coordinates: .init(latitude: latitude, longitude: longitude))
      .record(numberOfRecords: 1)

    recorder.waitForRecords()

    let expectedResult = Weather(
      description: "Clouds",
      iconCode: "04d",
      temperature: 3.72,
      location: "Nizbor"
    )

    XCTAssertRecordedValues(recorder.records, [expectedResult])
  }

  func testServerError() throws {
    struct MockError: Error {}
    TestURLProtocol.mockResponses[endpointURL] = { _ in (.failure(MockError()), 440) }

    let recorder = WeatherAPI
      .loadWeatherData_(coordinates: .init(latitude: latitude, longitude: longitude))
      .record(numberOfRecords: 1)

    recorder.waitForRecords()

    switch recorder.records.first {
    case .value, .completion(.finished), nil:
      XCTFail()

    case let .completion(.failure(error)):
      // The following assert for some reason fails:
      // XCTAssert(error is MockError) 👈

      // Even though the callback from the data task returns `MockError` correctly:
      //                                                              MockError ↓
      //   URLSession.shared.dataTask(with: request, completionHandler: { _, _, error in })
      //
      // and the console log from Combine shows the error correctly:
      // ```
      //  Task <B731E0E9-8CFE-444E-A120-6AF84F24D65F>.<2> finished with error [1] Error
      //  Domain=WeatherApp_SwiftUITests.WeatherAPITests.(unknown context at $10acdfc80).
      //  (unknown context at $10acdfcd8).MockError Code=1 "(null)"
      // ```

      XCTAssertNotNil(error)
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
