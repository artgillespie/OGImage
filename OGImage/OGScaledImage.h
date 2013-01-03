//
//  OGScaledImage.h
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGCachedImage.h"
#import "OGImageProcessing.h"

@interface OGScaledImage : OGCachedImage

/**
 * Scale the image at `url` to aspect-fit into `size` (specified in points). Note
 * that the full-sized image will be cached at `key` and the scaled image cached
 * using a generated key based on key + size.
 *
 * If `key` is nil, one will be generated from `url`
 */
- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key;
- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

/**
 * Scale the image at `url` using the specified method. (see `OGImageProcessingScaleMethod`
 * for information on scaling methods.)
 */
- (id)initWithURL:(NSURL *)url size:(CGSize)size method:(OGImageProcessingScaleMethod)method key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

/**
 *
 */
- (id)initWithURL:(NSURL *)url size:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

/**
 * Scale the given image to `size` and cache it at `key`
 */
- (id)initWithImage:(UIImage *)image size:(CGSize)size key:(NSString *)key;

/**
 * Scale the given image to `size` using `method` and cache it at `key`
 */
- (id)initWithImage:(UIImage *)image size:(CGSize)size method:(OGImageProcessingScaleMethod)method key:(NSString *)key;

/**
 * Scale the given image to `size` with a rounded rect mask specified by `cornerRadius` using `method` and cache it at `key`
 */
- (id)initWithImage:(UIImage *)image size:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method key:(NSString *)key;

/**
 * The scaled image—The inherited `image` property is set to the full-size image at `url`.
 * Clients should listen for KVO notifications on this property and `image` as
 * appropriate.
 */
@property (nonatomic, strong) UIImage *scaledImage;

@end
