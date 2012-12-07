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

/*
 * Returns the aspect fit size when scaling `from` to `to`
 */
CGSize OGAspectFit(CGSize from, CGSize to);

@interface OGImageProcessing : NSObject

+ (OGImageProcessing *)shared;

/**
 * Scale `image` to `size` using aspect fit. Note `size` is specified in points.
 */
- (void)scaleImage:(UIImage *)image toSize:(CGSize)size completionBlock:(OGImageProcessingBlock)block;

- (void)scaleImage:(UIImage *)image toSize:(CGSize)size method:(OGImageProcessingScaleMethod)method completionBlock:(OGImageProcessingBlock)block;

@end
