//
//  RNSketchManager.m
//  RNSketch
//
//  Created by Jeremy Grancher on 28/04/2016.
//  Copyright © 2016 Jeremy Grancher. All rights reserved.
//

#import "RNSketchManager.h"
#import "RNSketch.h"
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

#define ERROR_IMAGE_INVALID @"ERROR_IMAGE_INVALID"
#define ERROR_FILE_CREATION @"ERROR_FILE_CREATION"

@implementation RNSketchManager

RCT_EXPORT_MODULE()

#pragma mark - Events

RCT_EXPORT_VIEW_PROPERTY(onReset, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock);

RCT_CUSTOM_VIEW_PROPERTY(strokeColor, UIColor, RNSketch)
{
  [view setStrokeColor:json ? [RCTConvert UIColor:json] : [UIColor blackColor]];
}
RCT_EXPORT_VIEW_PROPERTY(strokeThickness, NSInteger)
  
#pragma mark - Properties

RCT_EXPORT_VIEW_PROPERTY(fillColor, UIColor);
RCT_EXPORT_VIEW_PROPERTY(strokeColor, UIColor);
RCT_EXPORT_VIEW_PROPERTY(clearButtonHidden, BOOL);
RCT_EXPORT_VIEW_PROPERTY(strokeThickness, NSInteger);
RCT_EXPORT_VIEW_PROPERTY(imageType, NSString);

#pragma mark - Lifecycle

- (instancetype)init
{
  if ((self = [super init])) {
    self.sketchView = nil;
  }
  
  return self;
}

- (UIView *)view
{
  if (!self.sketchView) {
    self.sketchView = [[RNSketch alloc] initWithFrame:CGRectZero];
  }
  
  return self.sketchView;
}


#pragma mark - Exported methods

RCT_EXPORT_METHOD(saveImage:(NSString *)encodedImage
                  ofType:(NSString *)imageType
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  // Strip the Base 64 Code out if it's there.
  NSString *base64Code = [self.sketchView base64Code];
  encodedImage = [encodedImage stringByReplacingOccurrencesOfString:base64Code
                                                         withString:@""
                                                            options:NULL
                                                              range:NSMakeRange(0, [base64Code length])];
  
  // Create image data with base64 source
  NSData *imageData = [[NSData alloc] initWithBase64EncodedString:encodedImage options:NSDataBase64DecodingIgnoreUnknownCharacters];
  if (!imageData) {
    return reject(ERROR_IMAGE_INVALID, @"You need to provide a valid base64 encoded image.", nil);
  }

  // Create full path of image
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths firstObject];
  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSString *fullPath = [[documentsDirectory stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]] stringByAppendingPathExtension:imageType];

  // Save image and return the path
  BOOL fileCreated = [fileManager createFileAtPath:fullPath contents:imageData attributes:nil];
  if (!fileCreated) {
    return reject(ERROR_FILE_CREATION, @"An error occured. Impossible to save the file.", nil);
  }
  resolve(@{@"path": fullPath});
}

RCT_EXPORT_METHOD(clear)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.sketchView clearDrawing];
  });
}

@end
