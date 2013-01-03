//
//  OGImageProcessing.h
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

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
- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius completionBlock:(OGImageProcessingBlock)block;

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method completionBlock:(OGImageProcessingBlock)block;

@end
