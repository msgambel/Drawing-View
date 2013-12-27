//  DrawingView.h

#import <UIKit/UIKit.h>

@protocol DrawingViewDelegate <NSObject>

- (void)updateControls;

@end

@interface DrawingView : UIView {
  id <DrawingViewDelegate> __weak _delegate;
  
  BOOL             _isErasing;
  BOOL             _redrawAll;
  BOOL             _debugModeOn;
  BOOL             _usingEraser;
  uint             _currentPathIndex;
  float            _currentLineWidth;
  float            _eraserLineWidthMultiplier;
  CGRect           _lastEraserDrawRect;
  CGPoint          _previousPoint;
  CGPoint          _previousMidPoint;
  UIColor        * _currentColour;
  UIColor        * _originalBackgroundColour;
  UIBezierPath   * _currentPath;
  UIBezierPath   * _eraserPath;
  NSMutableArray * _pathsArray;
  NSMutableArray * _pathWidthsArray;
  NSMutableArray * _pathColoursArray;
  NSMutableArray * _pathFillColoursArray;
}

@property (nonatomic, weak) id <DrawingViewDelegate> delegate;

@property (nonatomic, readonly) BOOL      canRedo;
@property (nonatomic, readonly) BOOL      canUndo;
@property (nonatomic, readonly) BOOL      canClear;
@property (nonatomic, assign)   BOOL      debugModeOn;
@property (nonatomic, readonly) BOOL      usingEraser;
@property (nonatomic, assign)   float     lineWidth;
@property (nonatomic, strong)   UIColor * colour;

- (void)redo;
- (void)undo;
- (void)clear;
- (void)erase;
- (void)setOriginalBackgroundColour:(UIColor *)aColour;
- (UIImage *)takeScreenShot;

@end