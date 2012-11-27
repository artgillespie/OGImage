//
//  OGImageCache.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGImageCache.h"
#import "OGImage.h"

static OGImageCache *OGImageCacheShared;

NSString *OGImageCachePath() {
    // generate the cache path: <app>/Library/Application Support/<bundle identifier>/OGImageCache,
    // creating the directories as needed
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if (nil == array || 0 == [array count]) {
        return nil;
    }
    NSString *cachePath = [[array[0] stringByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]] stringByAppendingPathComponent:@"OGImageCache"];
    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    return cachePath;
}

@implementation OGImageCache {
    NSCache *_memoryCache;
    dispatch_queue_t _cacheFileTasksQueue;
}

+ (OGImageCache *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OGImageCacheShared = [[OGImageCache alloc] init];
    });
    return OGImageCacheShared;
}

- (id)init {
    self = [super init];
    if (self) {
        _memoryCache = [[NSCache alloc] init];
        [_memoryCache setName:@"com.origami.OGImageCache"];
        _cacheFileTasksQueue = dispatch_queue_create("com.origami.OGImageCache.filetasks", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_cacheFileTasksQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
    }
    return self;
}

- (void)imageForKey:(NSString *)key block:(OGImageCacheCompletionBlock)block {
    NSParameterAssert(nil != key);
    NSParameterAssert(nil != block);
    UIImage *image = [_memoryCache objectForKey:key];
    if (nil != image) {
        block(image);
        return;
    }
    dispatch_async(_cacheFileTasksQueue, ^{
        // Check to see if the image is cached locally
        NSString *cachePath = [OGImageCachePath() stringByAppendingPathComponent:key];
        UIImage *image = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
            image = [UIImage imageWithContentsOfFile:cachePath];
        }
        // if we have the image in the on-disk cache, store it to the in-memory cache
        if (nil != image) {
            [_memoryCache setObject:image forKey:key];
        }
        // calls the block with the image if it was cached or nil if it wasn't
        dispatch_async(dispatch_get_main_queue(), ^{
            block(image);
        });
    });
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    NSParameterAssert(nil != image);
    NSParameterAssert(nil != key);
    [_memoryCache setObject:image forKey:key];
    dispatch_async(_cacheFileTasksQueue, ^{
        NSString *cachePath = [OGImageCachePath() stringByAppendingPathComponent:key];
        NSData *imgData = UIImagePNGRepresentation(image);
        [imgData writeToFile:cachePath atomically:YES];
    });
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key format:(OGImageFileFormat)format {
    NSParameterAssert(nil != image);
    NSParameterAssert(nil != key);
    [_memoryCache setObject:image forKey:key];
    dispatch_async(_cacheFileTasksQueue, ^{
        NSString *cachePath = [OGImageCachePath() stringByAppendingPathComponent:key];
        NSData *imgData = nil;
        if (OGImageFileFormatJPEG == format) {
            imgData = UIImageJPEGRepresentation(image, 5);
        } else {
            imgData = UIImagePNGRepresentation(image);
        }
        [imgData writeToFile:cachePath atomically:YES];
    });
}

@end
