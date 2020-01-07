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

struct MockViewModel: WeatherViewModelType {
  // Outputs
  var state: Driver<WeatherViewModelState> = .never()

  // Inputs
  var likeButtonTapped: PublishSubject<Void> = .init()
  var dislikeButtonTapped: PublishSubject<Void> = .init()
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
    let vm = MockViewModel(state: .just(.loading))
    sut.viewModel = vm

    sut.view.layer.speed = 0 // to stop the spinner

    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }

  func testLoadedData() {
    let vm = MockViewModel(state: .just(.loaded(
      weatherDescription: "Amazingly sunny",
      temperature: "112 °C",
      icon: "🚀",
      location: "Virtual"
    )))
    sut.viewModel = vm

    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }

  func testLikeDislikeButtonsTap() {
    let vm = MockViewModel()

    sut.viewModel = vm
    sut.loadViewIfNeeded()

    let like = scheduler.createObserver(Void.self)
    let dislike = scheduler.createObserver(Void.self)

    vm.likeButtonTapped.bind(to: like).disposed(by: disposeBag)
    vm.dislikeButtonTapped.bind(to: dislike).disposed(by: disposeBag)

    sut.dislikeButton.sendActions(for: .touchUpInside)
    sut.likeButton.sendActions(for: .touchUpInside)

    XCTAssertEqual(like.events.count, 1)
    XCTAssertEqual(dislike.events.count, 1)
  }

  func testErrorState() {
    let vm = MockViewModel(state: .just(.error))
    sut.viewModel = vm
    assertSnapshot(matching: sut, as: .image(on: .iPhoneX))
  }
}
