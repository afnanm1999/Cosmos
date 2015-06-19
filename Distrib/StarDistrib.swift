//
// Star rating control written in Swift for iOS.
//
// https://github.com/exchangegroup/Star
//
// This file was automatically generated by combining multiple Swift source files.
//


// ----------------------------
//
// StarFillMode.swift
//
// ----------------------------

import Foundation

/**

Defines how the star is filled when the rating is not an integer number. For example, if rating is 4.6 and the fill more is Half, the star will appear to be half filled.

*/
public enum StarFillMode: Int {
  /// Show only fully filled stars. For example, fourth star will be empty for 3.2.
  case Full = 0
  
  /// Show fully filled and half-filled stars. For example, fourth star will be half filled for 3.6.
  case Half = 1
  
  /// Fill star according to decimal rating. For example, fourth star will be 20% filled for 3.2. By default the fill rate is not applied linearly but corrected (see correctFillLevelForPreciseMode setting).
  case Precise = 2
}


// ----------------------------
//
// StarRating.swift
//
// ----------------------------

import UIKit


/**

Colection of helper functions for creating star layers.

*/
class StarRating {
  /**
  
  Creates the layers for the stars.
  
  - parameter rating: The decimal number representing the rating. Usually a number between 1 and 5
  - parameter settings: Star view settings.
  - returns: Array of star layers.
  
  */
  class func createStarLayers(rating: Double, settings: StarRatingSettings) -> [CALayer] {

    var ratingRemander = numberOfFilledStars(rating, totalNumberOfStars: settings.numberOfStars)

    var starLayers = [CALayer]()

    for _ in (0..<settings.numberOfStars) {
      let fillLevel = starFillLevel(ratingRemainder: ratingRemander, starFillMode: settings.starFillMode,
        correctFillLevelForPrecise: settings.correctFillLevelForPreciseMode)

      let starLayer = createCompositeStarLayer(fillLevel, settings: settings)
      starLayers.append(starLayer)
      ratingRemander--
    }

    positionStarLayers(starLayers, marginBetweenStars: settings.marginBetweenStars)
    return starLayers
  }

  
  /**
  
  Creates an layer that shows a star that can look empty, fully filled or partially filled.
  Partially filled layer contains two sublayers.
  
  - parameter starFillLevel: Decimal number between 0 and 1 describing the star fill level.
  - parameter settings: Star view settings.
  - returns: Layer that shows the star. The layer is displauyed in the star view.
  
  */
  class func createCompositeStarLayer(starFillLevel: Double, settings: StarRatingSettings) -> CALayer {

    if starFillLevel >= 1 {
      return createStarLayer(true, settings: settings)
    }

    if starFillLevel == 0 {
      return createStarLayer(false, settings: settings)
    }

    return createPartialStar(starFillLevel, settings: settings)
  }

  /**
  
  Creates a partially filled star layer with two sub-layers:
  
  1. The layer for the 'filled star' character on top. The fill level parameter determines the width of this layer.
  2. The layer for the 'empty star' character below.
  
  
  - parameter starFillLevel: Decimal number between 0 and 1 describing the star fill level.
  - parameter settings: Star view settings.

  - returns: Layer that contains the partially filled star.
  
  */
  class func createPartialStar(starFillLevel: Double, settings: StarRatingSettings) -> CALayer {
    let filledStar = createStarLayer(true, settings: settings)
    let emptyStar = createStarLayer(false, settings: settings)

    let parentLayer = CALayer()
    parentLayer.contentsScale = UIScreen.mainScreen().scale
    parentLayer.bounds = CGRect(origin: CGPoint(), size: filledStar.bounds.size)
    parentLayer.anchorPoint = CGPoint()
    parentLayer.addSublayer(emptyStar)
    parentLayer.addSublayer(filledStar)

    // make filled layer width smaller according to the fill level.
    filledStar.bounds.size.width *= CGFloat(starFillLevel)

    return parentLayer
  }

  /**

  Returns a decimal number between 0 and 1 describing the star fill level.
  
  - parameter ratingRemainder: This value is passed from the loop that creates star layers. The value starts with the rating value and decremented by 1 when each star is created. For example, suppose we want to display rating of 3.5. When the first star is created the ratingRemainder parameter will be 3.5. For the second star it will be 2.5. Third: 1.5. Fourth: 0.5. Fifth: -0.5.
  
  - parameter starFillMode: Describe how stars should be filled: full, half or precise.
  
  - parameter correctFillLevelForPrecise: If true and the fill mode is 'precise' the fill level will be corrected for better looks.
  
  - returns: Decimal value between 0 and 1 describing the star fill level. 1 is a fully filled star. 0 is an empty star. 0.5 is a half-star.

  */
  class func starFillLevel(ratingRemainder ratingRemainder: Double, starFillMode: StarFillMode,
    correctFillLevelForPrecise: Bool) -> Double {
      
    var result = ratingRemainder
    
    if result > 1 { result = 1 }
    if result < 0 { result = 0 }
      
    switch starFillMode {
    case .Full:
       result = Double(round(result))
    case .Half:
      result = Double(round(result * 2) / 2)
    case .Precise :
      if correctFillLevelForPrecise {
        result = correctPreciseFillLevel(result)
      }
    }
    
    return result
  }

  /**

  Correct the fill level to achieve more gradual fill of the ★ and ☆ star characters in precise mode. This is done to compensate for the fact that the ★ and ☆ characters do not occupy 100% width of their layer bound rectangle.
  
  Graph: https://www.desmos.com/calculator/zrxqlrypsk
  
  - parameter fillLevel: The initial fill level for correction.
  - returns: The corrected fill level.

  */
  class func correctPreciseFillLevel(fillLevel: Double) -> Double {
  
    var result = fillLevel
    
    if result > 1 { result = 1 }
    if result < 0 { result = 0 }
    
    let correctionRatio: Double = 1 / 5
    
    let multiplier: Double = 1 - 2 * correctionRatio
    
    return multiplier * result + correctionRatio
  }

  private class func createStarLayer(isFilled: Bool, settings: StarRatingSettings) -> CALayer {
    let text = isFilled ? settings.starCharacterFilled : settings.starCharacterEmpty
    let color = isFilled ? settings.starColorFilled : settings.starColorEmpty

    return StarRatingLayerHelper.createTextLayer(text, font:settings.starFont, color: color)
  }

  /**
  
  Returns the number of filled stars for given rating.
  
  - parameter rating: The rating to be displayed.
  - parameter maxNumberOfStars: Total number of stars.
  - returns: Number of filled stars. If rating is biggen than the total number of stars (usually 5) it returns the maximum number of stars.
  
  */
  class func numberOfFilledStars(rating: Double, totalNumberOfStars: Int) -> Double {
    if rating > Double(totalNumberOfStars) { return Double(totalNumberOfStars) }
    if rating < 0 { return 0 }

    return rating
  }

  /**
  
  Positions the star layers one after another with a margin in between.
  
  - parameter layers: The star layers array.
  - parameter marginBetweenStars: Margin between stars.

  */
  class func positionStarLayers(layers: [CALayer], marginBetweenStars: CGFloat) {
    var positionX:CGFloat = 0

    for layer in layers {
      layer.position.x = positionX
      positionX += layer.bounds.width + marginBetweenStars
    }
  }
}


// ----------------------------
//
// StarRatingDefaultSettings.swift
//
// ----------------------------


/**

Defaults setting values.

*/
struct StarRatingDefaultSettings {
  init() {}
  
  /// Raiting value that is shown in the storyboard by default.
  static let rating: Double = 3.5
  
  /// The maximum number of start to be shown.
  static let numberOfStars = 5
  
  /**
  
  Defines how the star should appear to be filled when the rating value is not an integer value.
  
  */
  static let starFillMode = StarFillMode.Half
  
  /// Distance between stars expressed. The value is automatically calculated based on marginBetweenStarsRelativeToFontSize property and the font size.
  static let marginBetweenStars:CGFloat = 0
  
  /**
  
  Distance between stars expressed as a fraction of the font size. For example, if the font size is 12 and the value is 0.25 the distance will be 4.
  
  */
  static let marginBetweenStarsRelativeToFontSize = 0.1
  
  /// The font used to draw the star character
  static let starFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  
  /// Character used to show a filled star
  static let starCharacterFilled = "★"
  
  /// Character used to show an empty star
  static let starCharacterEmpty = "☆"
  
  /// Filled star color
  static let starColorFilled = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Empty star color
  static let starColorEmpty = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Font for the text
  static let textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
  
  /// Color of the text
  static let textColor = UIColor.grayColor()
  
  /// Distance between the text and the star. The value is automatically calculated based on marginBetweenStarsAndTextRelativeToFontSize property and the font size.
  static let marginBetweenStarsAndText: CGFloat = 0
  
  /**
  
  Distance between the text and the star expressed as a fraction of the font size. For example, if the font size is 12 and the value is 0.25 the margin will be 4.
  
  */
  static let marginBetweenStarsAndTextRelativeToFontSize = 0.25
  
  /**
  
  When true the fill level is corrected to appear more gradual for default characters ★ and ☆. Applied only for precise star fill level.
  
  */
  static let correctFillLevelForPreciseMode = true
}


// ----------------------------
//
// StarRatingLayerHelper.swift
//
// ----------------------------

import UIKit

/// Helper class for creating CALayer objects.
class StarRatingLayerHelper {
  /**

  Creates a text layer for the given text string and font.
  
  - parameter text: The text shown in the layer.
  - parameter font: The text font. It is also used to calculate the layer bounds.
  - parameter color: Text color.
  
  - returns: New text layer.
  
  */
  class func createTextLayer(text: String, font: UIFont, color: UIColor) -> CATextLayer {
    let size = NSString(string: text).sizeWithAttributes([NSFontAttributeName: font])
    
    let layer = CATextLayer()
    layer.bounds = CGRect(origin: CGPoint(), size: size)
    layer.anchorPoint = CGPoint()
    
    layer.string = text
    layer.font = CGFontCreateWithFontName(font.fontName)
    layer.fontSize = font.pointSize
    layer.foregroundColor = color.CGColor
    layer.contentsScale = UIScreen.mainScreen().scale
    
    return layer
  }
}


// ----------------------------
//
// StarRatingSettings.swift
//
// ----------------------------

import UIKit

/**

Settings that define the appearance of the star rating views.

*/
public struct StarRatingSettings {
  init() {}
  
  /// Raiting value that is shown in the storyboard by default.
  public var rating: Double = StarRatingDefaultSettings.rating
  
  /// The maximum number of start to be shown.
  public var numberOfStars = StarRatingDefaultSettings.numberOfStars
  
  /**

  Defines how the star should appear to be filled when the rating value is not an integer value.

  */
  public var starFillMode = StarFillMode.Half
  
  /// Distance between stars expressed. The value is automatically calculated based on marginBetweenStarsRelativeToFontSize property and the font size.
  var marginBetweenStars:CGFloat = 0
  
  /**

  Distance between stars expressed as a fraction of the font size. For example, if the font size is 12 and the value is 0.25 the distance will be 4.

  */
  public var marginBetweenStarsRelativeToFontSize = 0.1
  
  /// The font used to draw the star character
  public var starFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  
  /// Character used to show a filled star
  public var starCharacterFilled = "★"
  
  /// Character used to show an empty star
  public var starCharacterEmpty = "☆"
  
  /// Filled star color
  public var starColorFilled = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Empty star color
  public var starColorEmpty = UIColor(red: 1, green: 149/255, blue: 0, alpha: 1)
  
  /// Font for the text
  public var textFont = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
  
  /// Color of the text
  public var textColor = UIColor.grayColor()
  
  /// Distance between the text and the star. The value is automatically calculated based on marginBetweenStarsAndTextRelativeToFontSize property and the font size.
  var marginBetweenStarsAndText: CGFloat = 0
  
  /**

  Distance between the text and the star expressed as a fraction of the font size. For example, if the font size is 12 and the value is 0.25 the margin will be 4.

  */
  public var marginBetweenStarsAndTextRelativeToFontSize = 0.25
  
  /**

  When true the fill level is corrected to appear more gradual for default characters ★ and ☆. Applied only for precise star fill level.

  */
  public var correctFillLevelForPreciseMode = true
}


// ----------------------------
//
// StarRatingSize.swift
//
// ----------------------------

import UIKit

/**

Helper class for calculating size fo star view.

*/
class StarRatingSize {
  /**
  
  Calculates the size of star rating view. It goes through all the layers and makes size the view size is large enough to show all of them.
  
  */
  class func calculateSizeToFitLayers(layers: [CALayer]) -> CGSize {
    var size = CGSize()
    
    for layer in layers {
      if layer.frame.maxX > size.width {
        size.width = layer.frame.maxX
      }
      
      if layer.frame.maxY > size.height {
        size.height = layer.frame.maxY
      }
    }
    
    return size
  }
}


// ----------------------------
//
// StarRatingText.swift
//
// ----------------------------



import UIKit

/**

Positions the text layer to the right of the stars.

*/
class StarRatingText {
  /**
  
  Positions the text layer to the right from the stars. Text is aligned to the center of the star superview vertically.
  
  - parameter layer: The text layer to be positioned.
  - parameter starsSize: The size of the star superview.
  - parameter marginBetweenStarsAndText: The distance between the stars and the text.
  
  */
  class func position(layer: CALayer, starsSize: CGSize, marginBetweenStarsAndText: CGFloat) {
    layer.position.x = starsSize.width + marginBetweenStarsAndText
    let yOffset = (starsSize.height - layer.bounds.height) / 2
    layer.position.y = yOffset
  }
}


// ----------------------------
//
// StarRatingView.swift
//
// ----------------------------

import UIKit

/*

A star rating view that can be used to show customer rating for the products. An optional text can be supplied that is shown to the right from the stars.

Example:

   ratingView.show(rating: 4, text: "(132)")

Displays: ★★★★☆ (132)

*/
@IBDesignable public class StarRatingView: UIView {
  // MARK: Inspectable properties for storyboard
  
  @IBInspectable var rating: Double = StarRatingDefaultSettings.rating {
    didSet { settings.rating = rating }
  }
  
  @IBInspectable var numberOfStars: Int = StarRatingDefaultSettings.numberOfStars {
    didSet { settings.numberOfStars = numberOfStars }
  }
  
  @IBInspectable var starCharacterFilled: String = StarRatingDefaultSettings.starCharacterFilled {
    didSet { settings.starCharacterFilled = starCharacterFilled }
  }
  
  @IBInspectable var starCharacterEmpty: String = StarRatingDefaultSettings.starCharacterEmpty {
    didSet { settings.starCharacterEmpty = starCharacterEmpty }
  }
  
  @IBInspectable var starColorFilled: UIColor = StarRatingDefaultSettings.starColorFilled {
    didSet { settings.starColorFilled = starColorFilled }
  }
  
  @IBInspectable var starColorEmpty: UIColor = StarRatingDefaultSettings.starColorEmpty {
    didSet { settings.starColorEmpty = starColorEmpty }
  }
  
  @IBInspectable var starFillMode: Int = StarRatingDefaultSettings.starFillMode.rawValue {
    didSet {
      settings.starFillMode = StarFillMode(rawValue: starFillMode) ??
        StarRatingDefaultSettings.starFillMode
    }
  }
  
  public override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    
    show(rating: settings.rating)
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    show()
  }
  
  /// Star rating settings.
  public var settings = StarRatingSettings()
  
  /// Stores the size of the view. It is used as intrinsic content size.
  private var size = CGSize()

  /**
  
  Creates sub-layers in the view that show the stars and the optional text.
  
  Example:
  
      ratingView.show(rating: 4.3, text: "(132)")
  
  - parameter rating: Number of stars to be shown, usually between 1 and 5. If the value is decimal the stars will be shown according to the Fill Mode setting.
  - parameter text: An optional text string that will be shown to the right from the stars.
  
  */
  public func show(rating rating: Double? = nil, text: String? = nil) {
    
    let ratingToShow = rating ?? settings.rating
    
    calculateMargins()
    
    // Create star layers
    // ------------
    
    var layers = StarRating.createStarLayers(ratingToShow, settings: settings)
    layer.sublayers = layers
    
    // Create text layer
    // ------------

    if let text = text {
      let textLayer = createTextLayer(text, layers: layers)
      layers.append(textLayer)
    }
    
    // Update size
    // ------------

    updateSize(layers)
  }
  
  
  
  /**
  
  Creates the text layer for the given text string.
  
  - parameter text: Text string for the text layer.
  - parameter layers: Arrays of layers containing the stars.
  
  - returns: The newly created text layer.
  
  */
  private func createTextLayer(text: String, layers: [CALayer]) -> CALayer {
    let textLayer = StarRatingLayerHelper.createTextLayer(text,
      font: settings.textFont, color: settings.textColor)
    
    let starsSize = StarRatingSize.calculateSizeToFitLayers(layers)
    
    StarRatingText.position(textLayer, starsSize: starsSize,
      marginBetweenStarsAndText: settings.marginBetweenStarsAndText)
    
    layer.addSublayer(textLayer)
    
    return textLayer
  }
  
  /**

  Updates the size to fit all the layers containing stars and text.
  
  - parameter layers: Array of layers containing stars and the text.

  */
  private func updateSize(layers: [CALayer]) {
    size = StarRatingSize.calculateSizeToFitLayers(layers)
    invalidateIntrinsicContentSize()
  }
  
  /// Calculate margins based on the font size.
  private func calculateMargins() {
    settings.marginBetweenStars = settings.starFont.pointSize *
      CGFloat(settings.marginBetweenStarsRelativeToFontSize)
    
    settings.marginBetweenStarsAndText = settings.textFont.pointSize *
      CGFloat(settings.marginBetweenStarsAndTextRelativeToFontSize)
  }
  
  /// Returns the content size to fit all the star and text layers.
  override public func intrinsicContentSize() -> CGSize {
    return size
  }
}


