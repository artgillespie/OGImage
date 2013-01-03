//
//  OGScaledImage.m
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGScaledImage.h"
#import "OGImageCache.h"

NSString *OGKeyWithSize(NSString *origKey, CGSize size) {
    return [NSString stringWithFormat:@"%@-%f-%f", origKey, size.width, size.height];
}

@implementation OGScaledImage {
    CGFloat _cornerRadius;
    CGSize _scaledSize;
    NSString *_scaledKey;
    OGImageProcessingScaleMethod _method;
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key {
    return [self initWithURL:url size:size key:key placeholderImage:nil];
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    return [self initWithURL:url size:size method:OGImageProcessingScale_AspectFit key:key placeholderImage:placeholderImage];
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size method:(OGImageProcessingScaleMethod)method key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    return [self initWithURL:url size:size cornerRadius:0.f method:method key:key placeholderImage:placeholderImage];
}

- (id)initWithURL:(NSURL *)url size:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method key:(NSString *)key placeholderImage:(UIImage *)placeholderImage {
    NSParameterAssert(nil != url);
    self = [super init];
    if (nil != self) {
        if (nil == key) {
            self.key = [OGImageCache MD5:[url absoluteString]];
        } else {
            self.key = key;
        }
        _method = method;
        self.url = url;
        self.scaledImage = placeholderImage;
        _scaledSize = size;
        _scaledKey = OGKeyWithSize(self.key, _scaledSize);
        _cornerRadius = cornerRadius;
        [self loadImageFromURL];
    }
    return self;
}

- (id)initWithImage:(UIImage *)image size:(CGSize)size key:(NSString *)key {
    return [self initWithImage:image size:size method:OGImageProcessingScale_AspectFit key:key];
}

- (id)initWithImage:(UIImage *)image size:(CGSize)size method:(OGImageProcessingScaleMethod)method key:(NSString *)key {
    return [self initWithImage:image size:size cornerRadius:0.f method:method key:key];
}

- (id)initWithImage:(UIImage *)image size:(CGSize)size cornerRadius:(CGFloat)cornerRadius method:(OGImageProcessingScaleMethod)method key:(NSString *)key {
    NSParameterAssert(nil != key);
    self = [super init];
    if (nil != self) {
        _method = method;
        _scaledSize = size;
        _scaledKey = key;
        _cornerRadius = cornerRadius;
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
    [[OGImageProcessing shared] scaleImage:image toSize:_scaledSize cornerRadius:_cornerRadius method:_method completionBlock:^(UIImage *image, NSError *error) {
        if (nil != error) {
            self.error = error;
        } else {
            self.scaledImage = image;
            [[OGImageCache shared] setImage:image forKey:_scaledKey];
        }
    }];
}

@end
