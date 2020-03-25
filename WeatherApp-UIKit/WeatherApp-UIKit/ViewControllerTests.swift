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
import SnapshotTesting
import UIKit
import XCTest

let mockStateMachineViewModel_loading: StateMachineViewModel = { _, _, _, _, _ in .just(.loading) }
let mockStateMachineViewModel_error: StateMachineViewModel = { _, _, _, _, _ in .just(.error) }
let mockStateMachineViewModel_loaded: StateMachineViewModel = { _, _, _, _, _ in
  .just(.loaded(
    weatherDescription: "Amazingly sunny",
    temperature: "112 °C",
    icon: "🚀",
    location: "Virtual",
    weatherFeedback: .notGiven
  ))
}

class ViewControllerTests: XCTestCase {
  var sut: ViewController!

  var scheduler: TestScheduler!

  var disposeBag: DisposeBag!

  override func setUp() {
    super.setUp()

    scheduler = .init(initialClock: 0)
    disposeBag = .init()

    sut = UIStoryboard(name: "Main", bundle: nil)
      .instantiateViewController(identifier: "ViewController") as ViewController

    XCTAssertEqual(UIScreen.main.scale, 2, "Snapshots are valid only for @2 scale")
  }

  func testLoadingData() {
    sut.viewModel = mockStateMachineViewModel_loading
    sut.view.layer.speed = 0 // to stop the spinner

    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }

  func testLoadedData() {
    sut.viewModel = mockStateMachineViewModel_loaded

    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }

  func testLikeDislikeButtonsTap() {
    var feedbackResult: WeatherFeedback = .notGiven
    let viewModel: StateMachineViewModel = { _, _, _, _, input in
      Driver.merge([
        input.likeButtonTapped.map { true },
        input.dislikeButtonTapped.map { false },
      ])
        .scan(.notGiven) { (previousValue, like) -> WeatherFeedback in
          like ? .like : .dislike
        }
        .do(onNext: { userFeedback in
          feedbackResult = userFeedback
      })
        .map { _ -> WeatherViewModelState in
          .loading
        }
        .asDriver(onErrorJustReturn: .loading)
    }
    XCTAssertEqual(.notGiven, feedbackResult)
    sut.viewModel = viewModel
    sut.loadViewIfNeeded()

    sut.dislikeButton.sendActions(for: .touchUpInside)
    XCTAssertEqual(.dislike, feedbackResult)

    sut.likeButton.sendActions(for: .touchUpInside)
    XCTAssertEqual(.like, feedbackResult)
  }

  func testErrorState() {
    sut.viewModel = mockStateMachineViewModel_error
    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }
}
