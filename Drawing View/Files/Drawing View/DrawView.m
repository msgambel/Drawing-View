//  DrawView.m

#import "DrawView.h"
#import <QuartzCore/QuartzCore.h>

@interface DrawView (Private)

- (void)initialize;
- (void)redoButtonPressed;
- (void)undoButtonPressed;
- (void)clearButtonPressed;
- (void)expandToFullScreen;
- (void)eraserButtonPressed;
- (void)setUpThePaletteView;
- (void)shrinkToOriginalSize;
- (void)lineWidthSliderPressed;
- (void)colourButtonPressed:(UIButton *)aButton;

@end

@implementation DrawView

@synthesize drawing = _drawing;

#pragma mark - Getters

- (BOOL)debugModeOn; {
  // Return if debug mode is on or not.
  return _debugModeOn;
}

#pragma mark - Setters

- (void)setDebugModeOn:(BOOL)debugModeOn; {
  // Set debug mode to be the input variable.
  _debugModeOn = debugModeOn;
  
  // Set the DrawingView's debug mode to be the input variable.
  _drawingView.debugModeOn = _debugModeOn;
}

#pragma mark - Init

- (id)initWithFrame:(CGRect)frame; {
  if((self = [super initWithFrame:frame])){
    // Initialize the view.
    [self initialize];
  }
  return self;
}

- (void)awakeFromNib; {
  [super awakeFromNib];
  
  // Initialize the view.
  [self initialize];
}

#pragma mark - Methods

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex; {
  // If the selected button is not the cancel button,
  if(buttonIndex != alertView.cancelButtonIndex){
    // Tell the drawing view to clear the view.
    [_drawingView clear];
  }
}

#pragma mark - DrawingViewDelegate Methods

- (void)updateControls; {
  // Enable the redo button if it can be enabled.
  _redoButton.enabled = _drawingView.canRedo;
  
  // Enable the undo button if it can be enabled.
  _undoButton.enabled = _drawingView.canUndo;
  
  // Enable the clear button if it can be enabled.
  _clearButton.enabled = _drawingView.canClear;
}

@end

#pragma mark - Private Methods

@implementation DrawView (Private)

- (void)initialize; {
  // Grab the original frame of the view.
  _originalFrame = self.frame;
  
  // Allocate the drawing view to have the same width and height as the original
  // frame. We need to set the origin as (0.0, 0.0) for the drawing view, as it
  // is a subview of self. The original frame will have an origin with respect
  // to the super's view, and will cause positioning errors if we use it for the
  // drawing view.
  _drawingView = [[DrawingView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
  
  // Set the drawing view's delegate to self.
  _drawingView.delegate = self;
  
  // Set the drawing view's original background colour to this view's background
  // colour.
  [_drawingView setOriginalBackgroundColour:self.backgroundColor];
  
  // Add the drawing view as a subview.
  [self addSubview:_drawingView];
  
  // Allocate the button that will be used to expand the view to full screen. We
  // need to set the origin as (0.0, 0.0) for the expand button, as it is a
  // subview of self. The original frame will have an origin with respect to the
  // super's view, and will cause positioning errors if we use it for the
  // expand button.
  _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  // Set the frame to have the same width and height as the original frame.
  [_expandButton setFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
  
  // Add the target action of the button to expand the view to full screen.
  [_expandButton addTarget:self action:@selector(expandToFullScreen) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the drawing view as a subview/
  [self addSubview:_expandButton];
  
  // Set up the palette view, which holds all the controls that effect the
  // drawing view.
  [self setUpThePaletteView];
}

- (void)redoButtonPressed; {
  // Tell the drawing view to redo.
  [_drawingView redo];
}

- (void)undoButtonPressed; {
  // Tell the drawing view to undo.
  [_drawingView undo];
}

- (void)clearButtonPressed; {
  // Put up an alert view to verify with the user that they actually want to
  // clear the drawing.
  UIAlertView * clearAlertView = [[UIAlertView alloc] initWithTitle:@"Clear" message:@"Are you sure you want to clear?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes", nil];
  
  // Show the alert view.
  [clearAlertView show];
}

- (void)expandToFullScreen; {
  // Store the original index of the self in its super view. This will allow us
  // to return it to the proper index when it is dismissed.
  _originalIndex = [self.superview.subviews indexOfObject:self];
  
  // Tell the self's super view to bring self to the front.
  [self.superview bringSubviewToFront:self];
  
  // Now, we animate the view so it expands to take up the whole screen.
  [UIView animateWithDuration:1.0f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^(void){
                     // Set self's new frame to be the super views frame.
                     CGRect newFrame = self.superview.frame;
                     
                     // Reset the origin of the new frame to (0,0).
                     newFrame.origin.x = 0.0f;
                     newFrame.origin.y = 0.0f;
                     
                     // Set self's frame to its new frame.
                     self.frame = newFrame;
                     
                     // Set the drawing views new frame to be the super views
                     // frame.
                     CGRect newDrawingFrame = self.superview.frame;
                     
                     // Reset the origin of the new frame to (0,0).
                     newDrawingFrame.origin.x = 0.0f;
                     newDrawingFrame.origin.y = 0.0f;
                     
                     // Offset the new drawing views height by the palette views
                     // hieght so that they are not over-lapping.
                     newDrawingFrame.size.height -= _paletteView.frame.size.height;
                     
                     // Set the drawing views frame to its new frame.
                     _drawingView.frame = newDrawingFrame;
                   }
                   completion:^(BOOL finished){
                     // Remove the expand button from the view, as it is no
                     // longer needed.
                     [_expandButton removeFromSuperview];
                     
                     // Move the palette views center to be underneath the view.
                     _paletteView.center = CGPointMake(self.center.x, self.frame.size.height + (_paletteView.frame.size.height / 2.0f));
                     
                     // Add the palette view as a subview to self.
                     [self addSubview:_paletteView];
                     
                     // Animate the palette view up, so it looks like it is
                     // moving in from the bottom.
                     [UIView animateWithDuration:0.25f
                                           delay:0.0f
                                         options:UIViewAnimationOptionCurveEaseInOut
                                      animations:^(void){
                                        // Move the palette views centre to be
                                        // at the bottom of self.
                                        _paletteView.center = CGPointMake(self.center.x, self.frame.size.height - (_paletteView.frame.size.height / 2.0f));
                                      }
                                      completion:nil];
                   }];
}

- (void)eraserButtonPressed; {
  // For all the buttons with the different colours,
  for(UIButton * colourButton in _colourButtons){
    // Set the border color to black.
    colourButton.layer.borderColor = [UIColor blackColor].CGColor;
    
    // Set the border width to 2.0.
    colourButton.layer.borderWidth = 2.0f;
    
    // Set the shadow colour to clear.
    colourButton.layer.shadowColor = [UIColor clearColor].CGColor;
    
    // Set the shadow width to 0.0.
    colourButton.layer.shadowRadius = 0.0f;
  }
  // Set the eraser button to be in the selected state.
  _eraserButton.selected = YES;
  
  // Tell the draw view to start erasing.
  [_drawingView erase];
}

- (void)setUpThePaletteView; {
  // Allocate the palette view, which will hold all of the control buttons.
  _paletteView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.superview.frame.size.width, 100.0f)];
  
  // Allocate a gradient layer to make the palette view look nice!
  CAGradientLayer * gradient = [CAGradientLayer layer];
  
  // Set the gradients frame to the bounds of the palette view.
  gradient.frame = _paletteView.bounds;
  
  // Set the start and end colours of the gradient layer.
  gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:144.0f/255.0f green:60.0f/255.0f blue:0.0f alpha:1.0f] CGColor], (id)[[UIColor colorWithRed:72.0f/255.0f green:31.0f/255.0f blue:0.0f alpha:1.0f] CGColor], nil];
  
  // Add the gradient layer to the palette view.
  [_paletteView.layer insertSublayer:gradient atIndex:0];
  
  // Allocate the back button.
  _backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // Set the frame of the back button.
    [_backButton setFrame:CGRectMake(5.0f, 55.0f, 40.0f, 40.0f)];
  }
  // If the current device is an iPad,
  else{
    // Set the frame of the back button.
    [_backButton setFrame:CGRectMake(5.0f, 30.0f, 40.0f, 40.0f)];
  }
  // Set the image of the back button.
  [_backButton setImage:[UIImage imageNamed:@"backButton.png"] forState:UIControlStateNormal];
  
  // Add the target action of the button to shrink the view to its original size.
  [_backButton addTarget:self action:@selector(shrinkToOriginalSize) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the back button to the palette view.
  [_paletteView addSubview:_backButton];
  
  // Allocate the eraser button.
  _eraserButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  // Set the frame of the eraser button to the be at the right of the palette
  // view.
  [_eraserButton setFrame:CGRectMake((self.superview.frame.size.width - 55.0f), 45.0f, 50.0f, 50.0f)];
  
  // Add the selected image of the eraser button to make it look like the eraser.
  [_eraserButton setImage:[UIImage imageNamed:@"eraserButtonSelected.png"] forState:UIControlStateSelected];
  
  // Add the unselected image of the eraser button to make it look like the eraser.
  [_eraserButton setImage:[UIImage imageNamed:@"eraserButtonUnselected.png"] forState:UIControlStateNormal];
  
  // Add the target action of the eraser button to activate the eraser.
  [_eraserButton addTarget:self action:@selector(eraserButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the eraser button to the palette view.
  [_paletteView addSubview:_eraserButton];
  
  // Set the eraser button to be unselected by default.
  _eraserButton.selected = NO;
  
  // Allocate the undo button.
  _undoButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // Set the frame of the undo button to the be at the left of the palette view.
    [_undoButton setFrame:CGRectMake(50.0f, 10.0f, 40.0f, 40.0f)];
  }
  // If the current device is an iPad,
  else{
    // Set the frame of the undo button to the be at the left of the palette view.
    [_undoButton setFrame:CGRectMake(125.0f, 30.0f, 40.0f, 40.0f)];
  }
  // Add the image of the undo button.
  [_undoButton setImage:[UIImage imageNamed:@"undoButtonEnabled.png"] forState:UIControlStateNormal];
  
  // Add the disabled image of the undo button.
  [_undoButton setImage:[UIImage imageNamed:@"undoButtonDisabled.png"] forState:UIControlStateDisabled];
  
  // Add the target action of the undo button to undo the last stroke.
  [_undoButton addTarget:self action:@selector(undoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the undo button to the palette view.
  [_paletteView addSubview:_undoButton];
  
  // Allocate the redo button.
  _redoButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // Set the frame of the redo button to the be at the left of the palette view.
    [_redoButton setFrame:CGRectMake(95.0f, 10.0f, 40.0f, 40.0f)];
  }
  // If the current device is an iPad,
  else{
    // Set the frame of the redo button to the be at the left of the palette view.
    [_redoButton setFrame:CGRectMake(170.0f, 30.0f, 40.0f, 40.0f)];
  }
  // Add the image of the redo button.
  [_redoButton setImage:[UIImage imageNamed:@"redoButtonEnabled.png"] forState:UIControlStateNormal];
  
  // Add the disabled image of the redo button.
  [_redoButton setImage:[UIImage imageNamed:@"redoButtonDisabled.png"] forState:UIControlStateDisabled];
  
  // Add the target action of the redo button to redo the last stroke.
  [_redoButton addTarget:self action:@selector(redoButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the redo button to the palette view.
  [_paletteView addSubview:_redoButton];
  
  // Allocate the clear button.
  _clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // Set the frame of the clear button to the be at the left of the palette view.
    [_clearButton setFrame:CGRectMake(5.0f, 10.0f, 40.0f, 40.0f)];
  }
  // If the current device is an iPad,
  else{
    // Set the frame of the clear button to the be at the left of the palette view.
    [_clearButton setFrame:CGRectMake(80.0f, 30.0f, 40.0f, 40.0f)];
  }
  // Add the image of the clear button.
  [_clearButton setImage:[UIImage imageNamed:@"clearButtonEnabled.png"] forState:UIControlStateNormal];
  
  // Add the disabled image of the clear button.
  [_clearButton setImage:[UIImage imageNamed:@"clearButtonDisabled.png"] forState:UIControlStateDisabled];
  
  // Add the target action of the clear button to clear the drawn image.
  [_clearButton addTarget:self action:@selector(clearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
  
  // Add the clear button to the palette view.
  [_paletteView addSubview:_clearButton];
  
  // Allocate the slider's background image view.
  _sliderBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sliderBackground.png"]];
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // Set the centre point of the slider's background image view.
    _sliderBackgroundImageView.center = CGPointMake(110.0f, 72.0f);
  }
  // If the current device is an iPad,
  else{
    // Set the centre point of the slider's background image view.
    _sliderBackgroundImageView.center = CGPointMake(330.0f, 50.0f);
  }
  // Add the slider's background image view to the palette view.
  [_paletteView addSubview:_sliderBackgroundImageView];
  
  // Allocate the line width slider with the same frame as its background image.
  _lineWidthSlider = [[UISlider alloc] initWithFrame:_sliderBackgroundImageView.frame];
  
  // Offset the centre point of the line width slider by (2,2). It just looks
  // better when you do this!
  _lineWidthSlider.center = CGPointMake(_lineWidthSlider.center.x + 2.0f, _lineWidthSlider.center.y - 2.0f);
  
  // Set the knob image for the line width slider.
  [_lineWidthSlider setThumbImage:[UIImage imageNamed:@"sliderKnob.png"] forState:UIControlStateNormal];
  [_lineWidthSlider setThumbImage:[UIImage imageNamed:@"sliderKnob.png"] forState:UIControlStateHighlighted];
  
  // Remove the track image for the line width slider, as we are using a custom
  // background image.
  [_lineWidthSlider setMinimumTrackImage:[[UIImage alloc] init] forState:UIControlStateNormal];
  [_lineWidthSlider setMaximumTrackImage:[[UIImage alloc] init] forState:UIControlStateNormal];
  
  // Set the maximum and minimum values for the line width slider.
  _lineWidthSlider.maximumValue = 7.0f;
  _lineWidthSlider.minimumValue = 3.0f;
  
  // Add the target of the line width slider to change the line width of the
  // drawing view.
  [_lineWidthSlider addTarget:self action:@selector(lineWidthSliderPressed) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
  
  // Add the line width slider to the palette view.
  [_paletteView addSubview:_lineWidthSlider];
  
  // Set the line width of the drawing view to be the default starting value.
  [self lineWidthSliderPressed];
  
  // Update the controls to be set to the correct state.
  [self updateControls];
  
  // Variable array to hold the default colours for the buttons. The colours in
  // order are:
  //
  // Black, Red, Dark Green, Blue, Orange, Purple, Grey, Brown, Light Green, Light Blue, Yellow.
  NSArray * colours = [NSArray arrayWithObjects:[UIColor blackColor], [UIColor redColor], [UIColor colorWithRed:70.0f/255.0f green:120.0f/255.0f blue:0.0f alpha:1.0f], [UIColor blueColor], [UIColor colorWithRed:251.0f/255.0f green:108.0f/255.0f blue:1.0f/255.0f alpha:1.0f], [UIColor colorWithRed:102.0f/255.0f green:51.0f/255.0f blue:153.0f/255.0f alpha:1.0f], [UIColor colorWithRed:123.0f/255.0f green:123.0f/255.0f blue:123.0f/255.0f alpha:1.0f], [UIColor colorWithRed:173.0f/255.0f green:101.0f/255.0f blue:64.0f/255.0f alpha:1.0f], [UIColor colorWithRed:120.0f/255.0f green:1.0f blue:3.0f/255.0f alpha:1.0f], [UIColor colorWithRed:70.0f/255.0f green:211.0f/255.0f blue:1.0f alpha:1.0f], [UIColor colorWithRed:1.0f green:1.0f blue:0.0f alpha:1.0f], nil];
  
  // Variable to hold the number of colour buttons used in the palette.
  uint numberOfColours = [colours count];
  
  // Variable to hold the x origin of the current colour button.
  float buttonOriginX = 450.0f;
  
  // Variable to hold the y origin of the current colour button.
  float buttonOriginY = 12.0f;
  
  // Variable to hold the colour for each colour button.
  UIColor * colour = nil;
  
  // Variable to hold the colour buttons for each colour.
  UIButton * colourButton = nil;
  
  // If the current device is NOT an iPad,
  if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
    // We will only give 5 colours as an option for drawing.
    numberOfColours = 5;
    
    // Also, the starting origin must also change, as the width is smaller than
    // the iPad.
    buttonOriginX = 150.0f;
  }
  // Allocate the array that holds all the colour buttons.
  _colourButtons = [[NSMutableArray alloc] initWithCapacity:numberOfColours];
  
  // For all the colour buttons we want to render,
  for(int colourIndex = 0; colourIndex < numberOfColours; colourIndex++){
    // If the current index is half-way through the number of colour buttons,
    if(colourIndex == ((numberOfColours + 1) / 2)){
      // If the current device is NOT an iPad,
      if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
        // Reset the colour buttons x origin. It is slightly larger from the
        // initial starting origin to make the second row of colour buttons
        // offset from the first row.
        buttonOriginX = 175.0f;
      }
      // If the current device is an iPad,
      else{
        // Reset the colour button's x origin. It is slightly larger from the
        // initial starting origin to make the second row of colour buttons
        // offset from the first row.
        buttonOriginX = 475.0f;
      }
      // Reset the Y origin to make the second row of colour buttons underneath
      // the first row of colour buttons.
      buttonOriginY = 52.0f;
    }
    // Grab the current colour.
    colour = [colours objectAtIndex:colourIndex];
    
    // Allcate a new button for the current colour.
    colourButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    // Set the frame of the colour button.
    [colourButton setFrame:CGRectMake(buttonOriginX, buttonOriginY, 40.0f, 40.0f)];
    
    // Set the background colour of the colour button.
    [colourButton setBackgroundColor:colour];
    
    // Set the corner radius of the colour button to be half its width. This
    // will make it look like the colour button is a circle.
    colourButton.layer.cornerRadius = (colourButton.frame.size.width / 2.0f);
    
    // Add the target action of the colour button to change the colour that is
    // being drawn.
    [colourButton addTarget:self action:@selector(colourButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add the colour button as a subview of the palette view.
    [_paletteView addSubview:colourButton];
    
    // Add the colour button to the array of colour buttons.
    [_colourButtons addObject:colourButton];
    
    // Increment the colour buttons x origin to put the next colour button to
    // the right of the current one.
    buttonOriginX += 47.0f;
  }
  // Set the default colour button pressed to be the black colour button.
  [self colourButtonPressed:[_colourButtons objectAtIndex:0]];
}

- (void)shrinkToOriginalSize; {
  // Take a screenShot of the drawing for use later.
  _drawing = [_drawingView takeScreenShot];
  
  // In order to shrink the view to the original size, we reverse the animation
  // of the expansion. First, move the palette view.
  [UIView animateWithDuration:0.25f
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseInOut
                   animations:^(void){
                     // Move the palette view's centre beneath self, so it looks
                     // like it's moving beneath the self, off screen.
                     _paletteView.center = CGPointMake(self.center.x, self.frame.size.height + (_paletteView.frame.size.height / 2.0f));
                   }
                   completion:^(BOOL finished){
                     // Remove the palette view, as it is no londer needed.
                     [_paletteView removeFromSuperview];
                     
                     // Shrink the whole view down to its original size.
                     [UIView animateWithDuration:1.0f
                                           delay:0.0f
                                         options:UIViewAnimationOptionCurveEaseInOut
                                      animations:^(void){
                                        // Set the frame to be the original frame.
                                        self.frame = _originalFrame;
                                        
                                        // Set the drawing views frame to be the
                                        // original frame. Again, the origin
                                        // needs to be reset to (0,0).
                                        _drawingView.frame = CGRectMake(0.0f, 0.0f, _originalFrame.size.width, _originalFrame.size.height);
                                      }
                                      completion:^(BOOL finished){
                                        // Re-add the expand button as a subview
                                        // so that the view will expand the next
                                        // it is touched.
                                        [self addSubview:_expandButton];
                                        
                                        // Reinsert the view into it's original
                                        // position.
                                        [self.superview insertSubview:self atIndex:_originalIndex];
                                      }];
                   }];
}

- (void)lineWidthSliderPressed; {
  // Set the drawing view's line width to be the line width the slider is set to.
  _drawingView.lineWidth = _lineWidthSlider.value;
}

- (void)colourButtonPressed:(UIButton *)aButton; {
  // For all the buttons with the different colours,
  for(UIButton * colourButton in _colourButtons){
    // Set the border color to black.
    colourButton.layer.borderColor = [UIColor blackColor].CGColor;
    
    // Set the border width to 2.0.
    colourButton.layer.borderWidth = 2.0f;
    
    // Set the shadow colour to clear.
    colourButton.layer.shadowColor = [UIColor clearColor].CGColor;
    
    // Set the shadow width to 0.0.
    colourButton.layer.shadowRadius = 0.0f;
  }
  // Set the selected button's border colour to white.
  aButton.layer.borderColor = [UIColor whiteColor].CGColor;
  
  // Set the selected button's shadow colour to black.
  aButton.layer.shadowColor = [UIColor blackColor].CGColor;
  
  // Set the selected button's shadow width to 0.0.
  aButton.layer.shadowRadius = 2.0f;
  
  // Set the eraser button to be in the unselected state.
  _eraserButton.selected = NO;
  
  // Set the drawing view's paint colour to be the selected button's colour.
  _drawingView.colour = aButton.backgroundColor;
}

@end