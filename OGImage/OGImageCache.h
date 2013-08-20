//
//  OGImageCache.h
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>

@class __OGImage;

typedef void (^OGImageCacheCompletionBlock)(__OGImage *image);

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

- (void)setImage:(__OGImage *)image forKey:(NSString *)key;

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

/**
 * Remove a single cached image from in-memory caches. If `wait` is `YES`
 * this will block the calling thread until the purge is complete.
 */
- (void)purgeMemoryCacheForKey:(NSString *)key andWait:(BOOL)wait;

/**
 * Remove cached images from disk that haven't been accessed since `date`
 * If `wait` is `YES` this will block the calling thread until the purge
 * is complete.
 */
- (void)purgeDiskCacheWithDate:(NSDate *)date wait:(BOOL)wait;


@end
