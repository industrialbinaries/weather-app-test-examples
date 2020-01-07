//
//  ViewController.swift
//  WeatherApp-UIKit
//
//  Created by Vojta on 04/01/2020.
//  Copyright © 2020 Industrial Binaries. All rights reserved.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

  // MARK: Dependencies

  var viewModel: WeatherViewModelType!

  // MARK: Outlets

  @IBOutlet weak var iconLabel: UILabel!
  @IBOutlet weak var weatherDescriptionLabel: UILabel!
  @IBOutlet weak var temperatureLabel: UILabel!
  @IBOutlet weak var locationLabel: UILabel!

  @IBOutlet weak var dislikeButton: UIButton!
  @IBOutlet weak var likeButton: UIButton!

  @IBOutlet weak var contentView: UIStackView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet weak var errorLabel: UILabel!

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel.state
      .drive(onNext: { [unowned self] (state) in
        switch state {
        case .loading: self.loading()

        case let .loaded(data):
          self.loaded(
            weatherDescription: data.weatherDescription,
            temperature: data.temperature,
            icon: data.icon,
            location: data.location
          )

        case .error: self.error()
        }
      })
      .disposed(by: disposeBag)

    likeButton.rx.tap
      .bind(to: viewModel.likeButtonTapped)
      .disposed(by: disposeBag)

    dislikeButton.rx.tap
      .bind(to: viewModel.dislikeButtonTapped)
      .disposed(by: disposeBag)
  }

  private let disposeBag = DisposeBag()
}

extension ViewController {
  private func loaded(weatherDescription: String, temperature: String, icon: String, location: String) {
    update(visibility: .content)

    iconLabel.text = icon
    weatherDescriptionLabel.text = weatherDescription
    temperatureLabel.text = temperature
    locationLabel.text = location
  }

  private func loading() {
    update(visibility: .loadingIndicator)
  }

  private func error(message: String? = nil) {
    errorLabel.text = message ?? "🤷‍♂️\nSorry, something went wrong."
    update(visibility: .error)
  }

  private enum Visibility {
    case content, loadingIndicator, error
  }

  private func update(visibility: Visibility) {
    contentView.isHidden = visibility != .content
    activityIndicator.isHidden = visibility != .loadingIndicator
    errorLabel.isHidden = visibility != .error
  }
}
