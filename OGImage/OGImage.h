//
//  OGImage.h
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGImageLoader.h"

@interface OGImage : NSObject <OGImageLoaderDelegate>

/**
 * Will asynchronously load the image at `url`, updating the `image` property
 * when loading is complete or updating the `error` property if there's a problem.
 */
- (id)initWithURL:(NSURL *)url;

/**
 * Synchronously sets the `image` property with `placeholderImage` and then
 * asynchronously loads the image at `url`, updating the `image` property
 * when loading is complete or updating the `error` property if there's a problem.
 */
- (id)initWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage;

/**
 * Convenience method: This is equivalent to calling
 *    [ogimg addObserver:observer forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
 *    [ogimg addObserver:observer forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
 */
- (void)addObserver:(NSObject *)observer;

/**
 * Convenience method: This is equivalent to calling
 *    [ogimg removeObserver:observer forKeyPath:@"image"];
 *    [ogimg removeObserver:observer forKeyPath:@"error"];
 */
- (void)removeObserver:(NSObject *)observer;

/**
 * Subclasses can override this method to perform caching, processing, etc., but
 * must make sure that KVO notifications are fired once the
 * `image` property is ready for display.
 *
 * This method will always be called on the main queue.
 */
- (void)imageDidLoadFromURL:(__OGImage *)image;

/**
 * Subclasses can override this method to check caches, etc., before initiating
 * loading the image from `url`.
 */
- (void)loadImageFromURL;

/**
 * Observe this property to be notified when the image has finished loading.
 *
 * If `initWithURL:placeholderImage` initializer was used, this will return
 * the placeholder image until the image at `url` has finished loading.
 *
 * If there's an error loading and the `initWithURL:placeholderImage` initializer
 * was used, this will continue to return the placeholder image even after the
 * error occurs.
 */
@property (nonatomic, strong) UIImage *image;

/**
 * Original image type UTI, e.g., public.jpeg, public.png
 */
@property (nonatomic, readonly) NSString *type;

/**
 * Original image metadata dictionary. This is the same dictionary returned by `CGImageSourceCopyProperties`
 * See
 * https://developer.apple.com/library/ios/documentation/GraphicsImaging/Conceptual/ImageIOGuide/imageio_source/ikpg_source.html#//apple_ref/doc/uid/TP40005462-CH218-DontLinkElementID_8
 */
@property (nonatomic, readonly) NSDictionary *info;

/**
 * Original image's alpha info.
 */
@property (nonatomic, readonly) CGImageAlphaInfo alphaInfo;

/**
 * Observe this property to be notified if there was an error loading the image.
 */
@property (nonatomic, strong) NSError *error;

/**
 * Observe this property to be notified of image download progress.
 */
@property (nonatomic, assign) float progress;

/**
 * The image's url (provided to init methods)
 */
@property (nonatomic, strong) NSURL *url;

/**
 * The amount of time it took to load the image from the network.
 */
@property (nonatomic, assign) NSTimeInterval loadTime;

@end
