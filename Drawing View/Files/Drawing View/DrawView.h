//  DrawView.h

#import <UIKit/UIKit.h>
#import "DrawingView.h"

@interface DrawView : UIView <UIAlertViewDelegate, DrawingViewDelegate> {
  BOOL             _debugModeOn;
  uint             _originalIndex;
  CGRect           _originalFrame;
  UIView         * _paletteView;
  UIImage        * _drawing;
  UIButton       * _backButton;
  UIButton       * _redoButton;
  UIButton       * _undoButton;
  UIButton       * _clearButton;
  UIButton       * _eraserButton;
  UIButton       * _expandButton;
  UISlider       * _lineWidthSlider;
  UIImageView    * _sliderBackgroundImageView;
  NSMutableArray * _colourButtons;
  DrawingView    * _drawingView;
}

@property (nonatomic, assign)   BOOL      debugModeOn;
@property (nonatomic, readonly) UIImage * drawing;

@end