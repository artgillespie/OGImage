//
//  OGScaledImage.h
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGCachedImage.h"

@interface OGScaledImage : OGCachedImage

/**
 * Scale the image at `url` to aspect-fit into `size` (specified in points)
 *
 * If `key` is nil, one will be generated from `url`
 */
- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key;
- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

/**
 * The scaled image—The inherited `image` property is set to the full-size image at `url`.
 * Clients should listen for KVO notifications on this property and `image` as
 * appropriate.
 */
@property (nonatomic, strong) UIImage *scaledImage;

@end
