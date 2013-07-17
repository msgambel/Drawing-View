//  DrawingView.m

#import "DrawingView.h"
#import <QuartzCore/QuartzCore.h>

// Marco to determine if the iOS verison is less than a specific version.
#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] \
compare:v options:NSNumericSearch] == NSOrderedAscending)

// Static function to compute the midpoint of two CGPoint's.
static CGPoint midpoint(CGPoint p0, CGPoint p1){
  return (CGPoint){((p0.x + p1.x) / 2.0), ((p0.y + p1.y) / 2.0)};
}

@interface DrawingView (Private)

- (void)initialize;
- (void)setTheBackgroundImage;
- (void)pan:(UIPanGestureRecognizer *)aPan;
- (void)tap:(UITapGestureRecognizer *)aTap;
- (void)addCurrentPathAndFill:(BOOL)shouldFill;

@end

@implementation DrawingView

@synthesize delegate = _delegate;
@synthesize colour = _currentColour;
@synthesize usingEraser = _usingEraser;
@synthesize lineWidth = _currentlineWidth;

#pragma mark - Getters

- (BOOL)canRedo; {
  // If the current path index is less than the number of paths, then we can
  // redo, as there are extra paths that can still be rendered.
  return (_currentPathIndex < [_pathsArray count]);
}

- (BOOL)canUndo; {
  // If the current path index is greater than 0, then we can undo, as there are
  // extra paths that can still be removed.
  return (_currentPathIndex > 0);
}

- (BOOL)canClear; {
  // If the current path index is greater than 0, then we can undo, as there are
  // extra paths that can be cleared.
  return (_currentPathIndex > 0);
}

- (UIColor *)colour; {
  // Return the current colour that the paths are being drawn with.
  return _currentColour;
}

#pragma mark - Setters

- (void)setColour:(UIColor *)colour; {
  // Set that we are not using the eraser.
  _usingEraser = NO;
  
  // Store the current colour used for the paths.
  _currentColour = colour;
  
  // Reset the eraser line width multiplier to 1.0.
  _eraserLineWidthMultiplier = 1.0f;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame; {
  if((self = [super initWithFrame:frame])){
    // Initialize the view.
    [self initialize];
  }
  // Return the initialized self.
  return self;
}

- (void)awakeFromNib; {
  [super awakeFromNib];
  
  // Initialize the view.
  [self initialize];
}

#pragma mark - Methods

- (void)redo; {
  // If the we can redo,
  if(self.canRedo){
    // Increment the current path index by 1.
    _currentPathIndex++;
    
    // Set that we need to redraw all the paths.
    _redrawAll = YES;
    
    // Reset the background colour to the original background colour.
    self.backgroundColor = [UIColor colorWithCGColor:_originalBackgroundColour.CGColor];
    
    // Redraw the view.
    [self setNeedsDisplay];
    
    // Tell the delegate that it needs to update its controls.
    [_delegate updateControls];
    
    // Store the current view as the new background image.
    [self setTheBackgroundImage];
  }
}

- (void)undo; {
  // If we can undo,
  if(self.canUndo){
    // Decrement the current path index by 1.
    _currentPathIndex--;
    
    // Set that we need to redraw all the paths.
    _redrawAll = YES;
    
    // Reset the background colour to the original background colour.
    self.backgroundColor = [UIColor colorWithCGColor:_originalBackgroundColour.CGColor];
    
    // Redraw the view.
    [self setNeedsDisplay];
    
    // Tell the delegate that it needs to update its controls.
    [_delegate updateControls];
    
    // Store the current view as the new background image.
    [self setTheBackgroundImage];
  }
}

- (void)clear; {
  // Set that we need to redraw all the paths.
  _redrawAll = YES;
  
  // Reset the background colour to the original background colour.
  self.backgroundColor = [UIColor colorWithCGColor:_originalBackgroundColour.CGColor];
  
  // Set the number of paths drawn to 0.
  _currentPathIndex = 0;
  
  // Remove all the paths and their properties from their respective arrays.
  [_pathsArray removeAllObjects];
  [_pathWidthsArray removeAllObjects];
  [_pathColoursArray removeAllObjects];
  [_pathFillColoursArray removeAllObjects];
  
  // Redraw the view.
  [self setNeedsDisplay];
  
  // Tell the delegate that it needs to update its controls.
  [_delegate updateControls];
}

- (void)erase; {
  // Set the current colour to be the original background colour.
  self.colour = _originalBackgroundColour;
  
  // Set that we are now using the eraser.
  _usingEraser = YES;
  
  // Set the eraser line width multiplier to 10.0, as when erasing, you usually
  // want the line width to be larger.
  _eraserLineWidthMultiplier = 10.0f;
}

- (void)setOriginalBackgroundColour:(UIColor *)aColour; {
  // Set the background colour to be the inputted colour.
  self.backgroundColor = aColour;
  
  // Store the original background colour as the inputted colour. We create a
  // new object, as we will be overwriting the background colour as new paths
  // are added, and we need to make sure that we don't affect the original
  // background colour (tricky pointers!).
  _originalBackgroundColour = [UIColor colorWithCGColor:self.backgroundColor.CGColor];
}

- (UIImage *)takeScreenShot; {
  // Start the graphics context for the current size of the drawn image. Setting
  // the scale to 0.0 means that Apple will figure out the screen scale for us!
  UIGraphicsBeginImageContextWithOptions(self.frame.size, YES, 0.0f);
  
  // Grab the current context.
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // Render the current layer into the contect.
  [self.layer renderInContext:context];
  
  // Store the current context as a UIImage.
  UIImage * screenShot = UIGraphicsGetImageFromCurrentImageContext();
  
  // End the graphics context.
  UIGraphicsEndImageContext();
  
  // Return the screen shot.
  return screenShot;
}

#pragma mark - Render

- (void)drawRect:(CGRect)rect; {
  [super drawRect:rect];
  
  // To see the updating of the region that is being redrawn, uncomment these
  // lines below.
//  CGContextRef context = UIGraphicsGetCurrentContext();
//  CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
//  CGContextStrokeRect(context, rect);
  
  // Note: This method is called every time the method "setNeedsDisplay" is
  //       called, which is not always by us (the system calls it a lot too!).
  
  // If we need to redraw all the paths,
  if(_redrawAll){
    // Variable to hold the colour for the current path.
    UIColor * colour = nil;
    
    // Variable to hold the current path to be rendered.
    UIBezierPath * path = nil;
    
    // For all the paths up to the current path to be rendered,
    for(uint index = 0; index < _currentPathIndex; index++){
      // Grab the current path.
      path = [_pathsArray objectAtIndex:index];
      
      // Set the line width of the current path.
      path.lineWidth = [[_pathWidthsArray objectAtIndex:index] floatValue];
      
      // Grab the colour of the current path.
      colour = [_pathColoursArray objectAtIndex:index];
      
      // If the current path needs to be filled,
      if([[_pathFillColoursArray objectAtIndex:index] boolValue]){
        // Set the colour to be the current fill colour.
        [colour setFill];
        
        // Draw and fill the path into the view.
        [path fill];
      }
      // If the current path does NOT need to be filled,
      else{
        // Set the colour to be the current stroke colour.
        [colour setStroke];
        
        // Draw the path into the view.
        [path stroke];
      }
    }
    // Set that we no longer need to redraw all the paths.
    _redrawAll = NO;
  }
  // If we do NOT need to redraw all the paths,
  else{
    // Set the current colour to be the stroke colour.
    [_currentColour setStroke];
    
    // Set the line width of the current path.
    _currentPath.lineWidth = (_currentlineWidth * _eraserLineWidthMultiplier);
    
    // Draw the current path into the view.
    [_currentPath stroke];
    
    // If we are erasing the image, we need to draw in the black bordered white
    // circle so the user knows they are erasing,
    if(_isErasing){
      // Set the fill colour to be white.
      [[UIColor whiteColor] setFill];
      
      // Fill in the eraser circle.
      [_eraserPath fill];
      
      // Set the stroke colour to be black.
      [[UIColor blackColor] setStroke];
      
      // Draw the border of the eraser circle.
      [_eraserPath stroke];
    }
  }
}

@end

#pragma mark - Private Methods

@implementation DrawingView (Private)

- (void)initialize; {
  // For a great video on how to improve rendering performance, watch:
  //
  // https://developer.apple.com/videos/wwdc/2012/?id=506
  
  // Set the original background colour to white by default.
  [self setOriginalBackgroundColour:[UIColor whiteColor]];
  
  // If the system version is at least iOS 6.0,
  if(SYSTEM_VERSION_LESS_THAN(@"6.0") == NO){
    // Tell the layer to draw asynchronously, in order to improve performance!
    self.layer.drawsAsynchronously = YES;
  }
  // Set that we are NOT erasing by default.
  _isErasing = NO;
  
  // Set that we do NOT need to redraw all the paths by default.
  _redrawAll = NO;
  
  // Set that we are NOT using the eraser by default.
  _usingEraser = NO;
  
  // Set the current line width to 3.0 by default.
  _currentlineWidth = 3.0f;
  
  // Set the eraser line width multiplier to 1.0 by default.
  _eraserLineWidthMultiplier = 1.0f;
  
  // Initialize the arrays that hold all the paths and their properties.
  _pathsArray = [[NSMutableArray alloc] init];
  _pathWidthsArray = [[NSMutableArray alloc] init];
  _pathColoursArray = [[NSMutableArray alloc] init];
  _pathFillColoursArray = [[NSMutableArray alloc] init];
  
  // Set the current path to be a new path.
  _currentPath = [UIBezierPath bezierPath];
  
  // Set the paths colour to black by default.
  _currentColour = [UIColor blackColor];
  
  // Initialize the pan gesture recognizer. This is used for the lines drawn.
  UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
  
  // Set the maximum and minimum number of touches of the pan gesture recognizer
  // to 1.
  pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
  
  // Add the pan gesture recognizer to the view.
  [self addGestureRecognizer:pan];
  
  // Initialize the tap gesture recognizer. This is used for the dots drawn.
  UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
  
  // Set the number of taps required to 1.
  tap.numberOfTapsRequired = 1;
  
  // Add the tap gesture recognizer to the view.
  [self addGestureRecognizer:tap];
}

- (void)setTheBackgroundImage; {
  // Redraw the view.
  [self setNeedsDisplay];
  
  // Store the current context as a colour.
  UIColor * background = [[UIColor alloc] initWithPatternImage:[self takeScreenShot]];
  
  // Set the background colour to be the current context.
  self.backgroundColor = background;
  
  // Set the current path to be a new path.
  _currentPath = [UIBezierPath bezierPath];
}

- (void)pan:(UIPanGestureRecognizer *)aPan; {
  // Variable to mark if we should redraw the view or NOT.
  BOOL shouldReDrawView = YES;
  
  // Variable to hold the current point of the users finger.
  CGPoint currentPoint = [aPan locationInView:self];
  
  // Variable to hold the midpoint of the current ppint and previous point.
  CGPoint midPoint = midpoint(_previousPoint, currentPoint);
  
  // The midpoint is used as the control point for the Quadratic Interpolation.
  // For a more detailed explanation, visit:
  //
  // http://developer.apple.com/library/ios/documentation/uikit/reference/UIBezierPath_class/Reference/Reference.html#//apple_ref/occ/instm/UIBezierPath/addQuadCurveToPoint:controlPoint:
  
  // If the user has just begun drawing the current path,
  if(aPan.state == UIGestureRecognizerStateBegan){
    // Set that we are erasing if the user has selected the eraser or NOT.
    _isErasing = _usingEraser;
    
    // Move the current path to the current point of the starting point.
    [_currentPath moveToPoint:currentPoint];
    
    // Set the midpoint to the current point, so we don't ever use the previous
    // point in any computation.
    midPoint = currentPoint;
    
    // Reset the last eraser's draw rect to the zero rect.
    _lastEraserDrawRect = CGRectZero;
  }
  // If the user is still drawing the current path,
  else if(aPan.state == UIGestureRecognizerStateChanged){
    // Add the current point to the current path.
    [_currentPath addQuadCurveToPoint:midPoint controlPoint:_previousPoint];
  }
  // If the user has ended drawing the current path,
  else if(aPan.state == UIGestureRecognizerStateEnded){
    // If the current path is not empty,
    if(_currentPath.empty == NO){
      // Add the current path, and mark that it does NOT need to be filled.
      [self addCurrentPathAndFill:NO];
    }
    // Mark that we are no londer erasing.
    _isErasing = NO;
    
    // Reset the last eraser's draw rect to the zero rect.
    _lastEraserDrawRect = CGRectZero;
    
    // Mark that we do NOT need to redraw the view.
    shouldReDrawView = NO;
    
    // Store the current view as the new background image.
    [self setTheBackgroundImage];
  }
  // If we are erasing,
  if(_isErasing){
    // We need to create an arc that rotated 360 degrees to indicate the eraser.
    // It has a radius of half of the current line width (as the current line
    // width is the diameter of the circle).
    _eraserPath = [UIBezierPath bezierPathWithArcCenter:currentPoint
                                                 radius:((_currentlineWidth * _eraserLineWidthMultiplier) / 2.0f)
                                             startAngle:0
                                               endAngle:(2.0 * M_PI)
                                              clockwise:YES];
  }
  // If we should redraw the view,
  if(shouldReDrawView){
    // If we are erasing,
    if(_isErasing){
      // Redraw the last eraser's draw rect to remove it from the view.
      [self setNeedsDisplayInRect:_lastEraserDrawRect];
      
      // Compute the width and height of the rect holding the eraser circle.
      CGFloat widthAndHeight = (_currentlineWidth * _eraserLineWidthMultiplier) + 2.0f;
      
      // Compute the x origin of the current eraser circle location.
      CGFloat originX = currentPoint.x - (widthAndHeight / 2.0f);
      
      // Compute the x origin of the current eraser circle location.
      CGFloat originY = currentPoint.y - (widthAndHeight / 2.0f);
      
      // Set the last Eraser's draw rect to the current redraw rect.
      _lastEraserDrawRect = CGRectMake(originX, originY, widthAndHeight, widthAndHeight);
    }
    // Compute the minimum x position of the current line being drawn.
    CGFloat minX = fmin(_previousMidPoint.x, midPoint.x) - (_currentlineWidth * _eraserLineWidthMultiplier);
    
    // Compute the minimum y position of the current line being drawn.
    CGFloat minY = fmin(_previousMidPoint.y, midPoint.y) - (_currentlineWidth * _eraserLineWidthMultiplier);
    
    // Compute the maximum x position of the current line being drawn.
    CGFloat maxX = fmax(_previousMidPoint.x, midPoint.x) + (_currentlineWidth * _eraserLineWidthMultiplier);
    
    // Compute the maximum x position of the current line being drawn.
    CGFloat maxY = fmax(_previousMidPoint.y, midPoint.y) + (_currentlineWidth * _eraserLineWidthMultiplier);
    
    // Store the current point as the previous point.
    _previousPoint = currentPoint;
    
    // Store the current midpoint as the previous midpoint.
    _previousMidPoint = midPoint;
    
    // Redraw the view in the smallest rectangle required.
    [self setNeedsDisplayInRect:CGRectMake(minX, minY, (maxX - minX), (maxY - minY))];
  }
  // Store the current point as the previous point.
  _previousPoint = currentPoint;
  
  // Store the current midpoint as the previous midpoint.
  _previousMidPoint = midPoint;
  
  // Tell the delegate that it needs to update its controls.
  [_delegate updateControls];
}

- (void)tap:(UITapGestureRecognizer *)aTap; {
  // Grab the center point of the tap.
  CGPoint tapCentre = [aTap locationInView:self];
  
  // If the current path is not empty,
  if(_currentPath.empty == NO){
    // Add the current path, and mark that it does NOT need to be filled.
    [self addCurrentPathAndFill:NO];
  }
  // Since the current path is formed on a tap, we are adding a dot to the view.
  // Therefore, we need to create an arc that rotated 360 degrees, and has a
  // radius of half of the current line width (as the current line width is the
  // diameter of the circle).
  _currentPath = [UIBezierPath bezierPathWithArcCenter:tapCentre
                                                radius:((_currentlineWidth * _eraserLineWidthMultiplier) / 2.0f)
                                            startAngle:0
                                              endAngle:(2.0 * M_PI)
                                             clockwise:YES];
  
  // Add the current dot path, and mark that it needs to be filled.
  [self addCurrentPathAndFill:YES];
  
  // Compute the width and height of the rect holding the drawn circle.
  CGFloat widthAndHeight = (_currentlineWidth * _eraserLineWidthMultiplier);
  
  // Compute the x origin of the current drawn circle location.
  CGFloat originX = tapCentre.x - (widthAndHeight / 2.0f);
  
  // Compute the y origin of the current drawn circle location.
  CGFloat originY = tapCentre.y - (widthAndHeight / 2.0f);
  
  // Redraw the view in the smallest rectangle required.
  [self setNeedsDisplayInRect:CGRectMake(originX, originY, widthAndHeight, widthAndHeight)];
  
  // Store the current view as the new background image.
  [self setTheBackgroundImage];
  
  // Tell the delegate that it needs to update its controls.
  [_delegate updateControls];
}

- (void)addCurrentPathAndFill:(BOOL)shouldFill; {
  // If the current path index is less that the number of paths stored, the user
  // has used the undo button, and there are paths that need to be removed,
  if(_currentPathIndex < [_pathsArray count]){
    // Removed the paths and their properties that are after the current path
    // index, as they no longer need to be stored.
    _pathsArray = [NSMutableArray arrayWithArray:[_pathsArray subarrayWithRange:NSMakeRange(0, _currentPathIndex)]];
    _pathWidthsArray = [NSMutableArray arrayWithArray:[_pathWidthsArray subarrayWithRange:NSMakeRange(0, _currentPathIndex)]];
    _pathColoursArray = [NSMutableArray arrayWithArray:[_pathColoursArray subarrayWithRange:NSMakeRange(0, _currentPathIndex)]];
    _pathFillColoursArray = [NSMutableArray arrayWithArray:[_pathFillColoursArray subarrayWithRange:NSMakeRange(0, _currentPathIndex)]];
  }
  // Store the current path.
  [_pathsArray addObject:_currentPath];
  
  // Store the width of the current path.
  [_pathWidthsArray addObject:[NSNumber numberWithFloat:(_currentlineWidth * _eraserLineWidthMultiplier)]];
  
  // Store the colour of the current path.
  [_pathColoursArray addObject:[UIColor colorWithCGColor:_currentColour.CGColor]];
  
  // Store if the path needs to be filled or NOT.
  [_pathFillColoursArray addObject:[NSNumber numberWithBool:shouldFill]];
  
  // Increment the current path index by 1.
  _currentPathIndex++;
}

@end