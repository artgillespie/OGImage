//
//  OGCachedImage.m
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGCachedImage.h"
#import "OGImageCache.h"

@implementation OGCachedImage

- (id)initWithURL:(NSURL *)url key:(NSString *)key {
    return [self initWithURL:url key:key placeholderImage:nil];
}

- (id)initWithURL:(NSURL *)url key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    NSParameterAssert(nil != url);
    self = [super init];
    if (nil != self) {
        if (nil == key) {
            _key = [url absoluteString];
        } else {
            _key = key;
        }
        self.url = url;
        self.image = placeholderImage;
        [self loadImageFromURL];
    }
    return self;
}

- (void)loadImageFromURL {
    [[OGImageCache shared] imageForKey:_key block:^(UIImage *image) {
        if (nil == image) {
            [super loadImageFromURL];
        } else {
            [self imageDidLoadFromURL:image];
        }
    }];
}

- (void)imageDidLoadFromURL:(UIImage *)image {
    [[OGImageCache shared] setImage:image forKey:_key];
    [super imageDidLoadFromURL:image];
}

@end
