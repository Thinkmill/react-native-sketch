//
//  RNSketch.m
//  RNSketch
//
//  Created by Jeremy Grancher on 28/04/2016.
//  Copyright © 2016 Jeremy Grancher. All rights reserved.
//

#import "RNSketch.h"
#import "RNSketchManager.h"
#import <React/RCTEventDispatcher.h>
#import <React/RCTView.h>
#import "UIView+React.h"

@implementation RNSketch
{
  // Internal
  UIButton *_clearButton;
  UIBezierPath *_path;
  UIImage *_image;
  CGPoint _points[5];
  uint _counter;
  // Configuration settings
  UIColor *_strokeColor;
}


#pragma mark - UIViewHierarchy methods


- (instancetype)initWithFrame:(CGRect) frame
{
  if ((self = [super initWithFrame:frame])) {
    // Internal setup
    self.multipleTouchEnabled = NO;
  
    // For borderRadius property to work (CALayer's cornerRadius).
    self.layer.masksToBounds = YES;
  
    _path = [UIBezierPath bezierPath];

    [self initClearButton];
  }

  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)aDecoder)

- (void)layoutSubviews
{
  [super layoutSubviews];
  [self drawBitmap];
}

- (void)setClearButtonHidden:(BOOL)hidden
{
  _clearButton.hidden = hidden;
}


#pragma mark - Subviews


- (void)initClearButton
{
  // Clear button
  CGRect frame = CGRectMake(0, 0, 50, 50);
  _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
  _clearButton.frame = frame;
  _clearButton.enabled = false;
  _clearButton.tintColor = [UIColor blackColor];
  _clearButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
  [_clearButton setTitle:@"x" forState:UIControlStateNormal];
  [_clearButton addTarget:self action:@selector(clearDrawing) forControlEvents:UIControlEventTouchUpInside];

  // Clear button background
  UIButton *background = [UIButton buttonWithType:UIButtonTypeCustom];
  background.frame = frame;

  // Add subviews
  [self addSubview:background];
  [self addSubview:_clearButton];
}


#pragma mark - UIResponder methods


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  _counter = 0;
  UITouch *touch = [touches anyObject];
  _points[0] = [touch locationInView:self];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  _counter++;
  UITouch *touch = [touches anyObject];
  _points[_counter] = [touch locationInView:self];

  if (_counter == 4) [self drawCurve];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  // Enabling to clear
  [_clearButton setEnabled:true];

  [self drawBitmap];
  [self setNeedsDisplay];

  [_path removeAllPoints];
  _counter = 0;

  if (_onChange) _onChange(@{ @"imageData": [self drawingToString]});
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  [self touchesEnded:touches withEvent:event];
}


#pragma mark - UIViewRendering methods


- (void)drawRect:(CGRect)rect
{
  [_image drawInRect:rect];
  [_strokeColor setStroke];
  [_path stroke];
}


#pragma mark - Drawing methods


- (void)drawCurve
{
  // Move the endpoint to the middle of the line
  _points[3] = CGPointMake((_points[2].x + _points[4].x) / 2, (_points[2].y + _points[4].y) / 2);

  [_path moveToPoint:_points[0]];
  [_path addCurveToPoint:_points[3] controlPoint1:_points[1] controlPoint2:_points[2]];

  [self setNeedsDisplay];

  // Replace points and get ready to handle the next segment
  _points[0] = _points[3];
  _points[1] = _points[4];
  _counter = 1;
}

- (void)drawBitmap
{
  UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0);

  // Draw with context
  [_image drawAtPoint:CGPointZero];
  [_strokeColor setStroke];
  [_path stroke];
  _image = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
}


#pragma mark - Export drawing


- (NSString *)drawingToString
{
  NSString *imageData = nil;
  
  if ([_imageType isEqualToString:@"jpg"]) {
    imageData = [UIImageJPEGRepresentation(_image, 1) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  } else if ([_imageType isEqualToString:@"png"]) {
    imageData = [UIImagePNGRepresentation(_image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
  } else {
    [NSException raise:@"Invalid image type" format:@"%@ is not a valid image type for exporting the drawing.", _imageType];
  }
  
  return [[self base64Code] stringByAppendingString:imageData];
}

- (NSString *)base64Code {
  return [NSString stringWithFormat:@"data:image/%@;base64,", self.imageType];
}


#pragma mark - Clear drawing


- (void)clearDrawing
{
  // Disabling to clear
  [_clearButton setEnabled:false];

  _image = nil;

  [self drawBitmap];
  [self setNeedsDisplay];

  // Send event
  if (_onReset) _onReset(@{});
  if (_onChange) _onChange(@{});
}

#pragma mark - Setters

- (void)setStrokeColor:(UIColor *)strokeColor
{
  _strokeColor = strokeColor;
}

- (void)setStrokeThickness:(NSInteger)strokeThickness
{
  _path.lineWidth = strokeThickness;
}

- (void)setImageType:(NSString *)imageType
{
  _imageType = imageType;
}

- (NSString *)getImageType {
  return _imageType;
}

@end
