//
//  WeatherApp - SwiftUI
//
//  Copyright (c) 2020 Industrial Binaries
//  MIT license, see LICENSE file for details
//

import Combine
import SwiftUI

extension WeatherView {
  struct UIIdentifiers {
    static let likeButton = "WeatherView.LikeButton"
    static let dislikeButton = "WeatherView.DisikeButton"
  }
}

struct WeatherView: View {
  @ObservedObject var viewModel: WeatherViewModel

  var body: some View {
    ClosureView(viewModel.state) { state in
      switch state {
      case .loading:
        return AnyView(LadingPlaceholderView())

      case .error:
        return AnyView(ErrorMessageView())

      case let .loaded(weatherDescription, temperature, icon, location):
        return AnyView(WeatherContentView(
          weatherDescription: weatherDescription,
          temperature: temperature,
          icon: icon,
          location: location,
          buttonTapped: { liked in
            if liked {
              self.viewModel.likeButtonTapped.send(())
            } else {
              self.viewModel.dislikeButtonTapped.send(())
            }
          }
        ))
      }
    }
  }
}

private struct LadingPlaceholderView: View {
  var body: some View {
    ActivityIndicator(isAnimating: .constant(true), style: .large)
  }
}

private struct ErrorMessageView: View {
  var body: some View {
    Text("🤷‍♂️\nSorry, something went wrong.")
      .font(.callout)
      .multilineTextAlignment(.center)
  }
}

private struct WeatherContentView: View {
  let weatherDescription: String
  let temperature: String
  let icon: String
  let location: String

  let buttonTapped: (_ liked: Bool) -> Void

  var body: some View {
    VStack(spacing: 58) {
      Text(icon).font(.system(size: 123))

      VStack(spacing: 11) {
        Text(weatherDescription).font(.headline)
        Text(temperature).font(.largeTitle)
        Text(location).font(.callout)
      }

      HStack(spacing: 8) {
        Button(action: { self.buttonTapped(false) }) {
          Spacer()
          Text("👎")
            .padding()
            .font(.system(size: 49))
          Spacer()
        }
        .background(Color.black.opacity(0.1))
        .accessibility(identifier: WeatherView.UIIdentifiers.dislikeButton)

        Button(action: { self.buttonTapped(true) }) {
          Spacer()
          Text("♥️")
            .padding()
            .font(.system(size: 49))
          Spacer()
        }
        .background(Color.black.opacity(0.1))
        .accessibility(identifier: WeatherView.UIIdentifiers.likeButton)
      }
    }
  }
}

private struct ActivityIndicator: UIViewRepresentable {
  @Binding var isAnimating: Bool
  let style: UIActivityIndicatorView.Style

  func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
    return UIActivityIndicatorView(style: style)
  }

  func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
    isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
  }
}

// Credit: https://github.com/simonmitchell/ClosureView
private struct ClosureView<T>: View {
  typealias ViewCreator = (T) -> AnyView

  var value: T

  var constructor: ViewCreator

  var body: some View {
    constructor(value)
  }

  init(_ value: T, constructor: @escaping ViewCreator) {
    self.constructor = constructor
    self.value = value
  }
}
