//
//  OGImageProcessing.h
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OGImageProcessingBlock)(UIImage *image);

CGSize OGAspectFit(CGSize from, CGSize to);

@interface OGImageProcessing : NSObject

+ (OGImageProcessing *)shared;

/**
 * Scale `image` to `size` using aspect fit. Note `size` is specified in points.
 */
- (void)scaleImage:(UIImage *)image toSize:(CGSize)size completionBlock:(OGImageProcessingBlock)block;

@end
