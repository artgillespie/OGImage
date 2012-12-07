//
//  OGScaledImage.m
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGScaledImage.h"
#import "OGImageCache.h"
#import "OGImageProcessing.h"

NSString *OGKeyWithSize(NSString *origKey, CGSize size) {
    return [NSString stringWithFormat:@"%@-%f-%f", origKey, size.width, size.height];
}

@implementation OGScaledImage {
    CGSize _scaledSize;
    NSString *_scaledKey;
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key {
    return [self initWithURL:url size:size key:key placeholderImage:nil];
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    NSParameterAssert(nil != url);
    self = [super init];
    if (nil != self) {
        if (nil == key) {
            self.key = [OGImageCache MD5:[url absoluteString]];
        } else {
            self.key = key;
        }
        self.url = url;
        self.scaledImage = placeholderImage;
        _scaledSize = size;
        _scaledKey = OGKeyWithSize(self.key, _scaledSize);
        [self loadImageFromURL];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image size:(CGSize)size key:(NSString *)key {
    NSParameterAssert(nil != key);
    self = [super init];
    if (nil != self) {
        _scaledSize = size;
        _scaledKey = key;
        self.image = image;
        [self doScaleImage:self.image];
    }
    return self;
}

- (void)loadImageFromURL {
    [[OGImageCache shared] imageForKey:_scaledKey block:^(UIImage *image) {
        if (nil == image) {
            [super loadImageFromURL];
        } else {
            self.scaledImage = image;
        }
    }];
}

- (void)imageDidLoadFromURL:(UIImage *)image {
    [super imageDidLoadFromURL:image];
    [self doScaleImage:image];
}

- (void)doScaleImage:(UIImage *)image {
    [[OGImageProcessing shared] scaleImage:image toSize:_scaledSize method:OGImageProcessingScale_AspectFill completionBlock:^(UIImage *image, NSError *error) {
        if (nil != error) {
            self.error = error;
        } else {
            self.scaledImage = image;
            [[OGImageCache shared] setImage:image forKey:_scaledKey];
        }
    }];
}

@end
