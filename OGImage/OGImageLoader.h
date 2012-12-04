//
//  OGImageLoader.h
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSInteger OGImageLoadingError;

typedef NS_ENUM(NSInteger, OGImageLoaderPriority) {
    OGImageLoaderPriority_Low,
    OGImageLoaderPriority_Default,
    OGImageLoaderPriority_High
};

/**
 * This block is called when an image is loaded or fails to load. If `error` is
 * nil, `image` should be valid.
 */
typedef void(^OGImageLoaderCompletionBlock)(UIImage *image, NSError *error);

@interface OGImageLoader : NSObject

/**
 * `OGImageLoader` is intended to be used as a singleton.
 */
+ (OGImageLoader *)shared;

/**
 * Enqueues a request to load the image at `imageURL`. `completionBlock` will always
 * be called on the main queue.
 */
- (void)enqueueImageRequest:(NSURL *)imageURL completionBlock:(OGImageLoaderCompletionBlock)completionBlock;

/**
 * The maximum number of concurrent network requests that can be in-flight at
 * any one time. (Default: 4)
 */
@property (nonatomic, assign) NSInteger maxConcurrentNetworkRequests;

/**
 * The priority of the image loader request queue. Default: OGImageLoaderPriority_Low
 */
@property (nonatomic, assign) OGImageLoaderPriority priority;

@end
