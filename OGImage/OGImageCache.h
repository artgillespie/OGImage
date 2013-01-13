//
//  OGImageCache.h
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
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

+ (NSString *)MD5:(NSString *)string;

+ (NSString *)filePathForKey:(NSString *)key;

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

/**
 * Remove all cached images from in-memory and on-disk caches. If `wait` is `YES`
 * this will block the calling thread until the purge is complete.
 */
- (void)purgeCache:(BOOL)wait;

/**
 * Remove a single cached image from in-memory and on-disk caches. If `wait` is `YES`
 * this will block the calling thread until the purge is complete.
 */
- (void)purgeCacheForKey:(NSString *)key andWait:(BOOL)wait;

@end
