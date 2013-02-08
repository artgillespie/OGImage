//
//  OGImageProcessing.h
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OGImageProcessing;

@protocol OGImageProcessingDelegate

@required

- (void)imageProcessing:(OGImageProcessing *)processing didProcessImage:(UIImage *)image;
- (void)imageProcessingFailed:(OGImageProcessing *)processing error:(NSError *)error;

@end

typedef void (^OGImageProcessingBlock)(UIImage *image, NSError *error);

extern NSString * const OGImageProcessingErrorDomain;

enum {
    OGImageProcessingError = -65535,
};

typedef NS_ENUM(NSInteger, OGImageProcessingScaleMethod) {
    OGImageProcessingScale_AspectFit,
    OGImageProcessingScale_AspectFill
};

@interface OGImageProcessing : NSObject

+ (OGImageProcessing *)shared;

/**
 * Scale `image` to `size` using aspect fit. Note `size` is specified in points.
 */
- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius delegate:(id<OGImageProcessingDelegate>)delegate;

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method delegate:(id<OGImageProcessingDelegate>)delegate;

@end
