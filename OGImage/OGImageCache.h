//
//  OGImageCache.h
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OGImage;

typedef void (^OGImageCacheCompletionBlock)(UIImage *image);

typedef NS_ENUM(NSInteger, OGImageFileFormat) {
    OGImageFileFormatJPEG,
    OGImageFileFormatPNG
};

@interface OGImageCache : NSObject

+ (OGImageCache *)shared;

/**
 * Check in-memory and on-disk caches for image corresponding to `key`. `block`
 * called on main queue when check is complete. If `image` parameter is `nil`,
 * no image corresponding to `key` was found.
 */
- (void)imageForKey:(NSString *)key block:(OGImageCacheCompletionBlock)block;

/**
 * Store `image` in-memory and on disk. Image will be serialized as PNG.
 */
- (void)setImage:(UIImage *)image forKey:(NSString *)key;

/**
 * Store `image` in-memory and on disk. Image will be serialized as `format`.
 */
- (void)setImage:(UIImage *)image forKey:(NSString *)key format:(OGImageFileFormat)format;

@end
