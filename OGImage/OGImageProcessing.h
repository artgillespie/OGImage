//
//  OGImageProcessing.h
//  OGImageDemo
//
//  Created by Art Gillespie on 11/29/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^OGImageProcessingBlock)(UIImage *image);

CGSize OGAspectFit(CGSize from, CGSize to);

@interface OGImageProcessing : NSObject

+ (OGImageProcessing *)shared;

/**
 * Scale `image` to `size` using aspect fit.
 */
- (void)scaleImage:(UIImage *)image toSize:(CGSize)size completionBlock:(OGImageProcessingBlock)block;

@end
