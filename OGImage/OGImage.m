//
//  OGImage.m
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImage.h"
#import "OGImageLoader.h"
#import "__OGImage.h"

@implementation OGImage

- (id)initWithURL:(NSURL *)url {
    return [self initWithURL:url placeholderImage:nil];
}

- (id)initWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage {
    NSParameterAssert(nil != url);
    self = [super init];
    if (nil != self) {
        self.image = placeholderImage;
        self.url = url;
        [self loadImageFromURL];
    }
    return self;
}

- (void)addObserver:(NSObject *)observer context:(void *)context {
    [self addObserver:observer forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:context];
    [self addObserver:observer forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:context];
}

- (void)removeObserver:(NSObject *)observer context:(void *)context {
    @try {
        [self removeObserver:observer forKeyPath:@"image" context:context];
    } @catch (NSException *e) {}
    @try {
        [self removeObserver:observer forKeyPath:@"error" context:context];
    } @catch (NSException *e) {}
}

- (void)imageDidLoadFromURL:(__OGImage *)image {
    self.image = image;
}

#pragma mark - OGImageLoaderDelegate

- (void)imageLoader:(OGImageLoader*)loader didLoadImage:(__OGImage *)image forURL:(NSURL *)url {
    NSParameterAssert([self.url isEqual:url]);
    if (nil != image) {
        [self imageDidLoadFromURL:image];
    }
}

- (void)imageLoader:(OGImageLoader*)loader failedForURL:(NSURL *)url error:(NSError *)error {
    NSParameterAssert([self.url isEqual:url]);
    if (nil != error) {
        [self _setError:error];
    }
}

- (NSString *)type {
    return ((__OGImage *)_image).originalFileType;
}

- (NSDictionary *)info {
    return ((__OGImage *)_image).originalFileProperties;
}

- (CGImageAlphaInfo)alphaInfo {
    return ((__OGImage *)_image).originalFileAlphaInfo;
}

#pragma mark - Protected

- (void)loadImageFromURL {
    [[OGImageLoader shared] enqueueImageRequest:_url delegate:self];
}

- (void)_setError:(NSError *)error {
    [self setValue:error forKey:@"error"];
}

@end
