//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import RxSwift
import UIKit

class ViewController: UIViewController {
  // MARK: Dependencies

  var viewModel: WeatherViewModelType!

  // MARK: Outlets

  @IBOutlet var iconLabel: UILabel!
  @IBOutlet var weatherDescriptionLabel: UILabel!
  @IBOutlet var temperatureLabel: UILabel!
  @IBOutlet var locationLabel: UILabel!

  @IBOutlet var dislikeButton: UIButton!
  @IBOutlet var likeButton: UIButton!

  @IBOutlet var contentView: UIStackView!
  @IBOutlet var activityIndicator: UIActivityIndicatorView!
  @IBOutlet var errorLabel: UILabel!

  // MARK: Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    viewModel.state
      .drive(onNext: { [unowned self] state in
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
