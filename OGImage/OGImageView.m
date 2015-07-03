//
//  OGImageView.m
//  OGImageDemo
//
//  Created by Art Gillespie on 8/23/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "OGImageView.h"
#import "OGScaledImage.h"

static NSString *KVOContext = @"OGImageView observation";

@implementation OGImageView {
    OGScaledImage *_scaledImage;
}

- (void)setImageURL:(NSURL *)url placeholder:(UIImage *)placeholder {
    self.image = placeholder;
    [_scaledImage removeObserver:self context:&KVOContext];
    OGImageProcessingScaleMethod scaleMethod = OGImageProcessingScale_AspectFill;
    if (UIViewContentModeScaleAspectFit == self.contentMode) {
        scaleMethod = OGImageProcessingScale_AspectFit;
    }
    _scaledImage = [[OGScaledImage alloc] initWithURL:url size:self.bounds.size cornerRadius:0.f method:scaleMethod key:nil placeholderImage:nil];
    [_scaledImage addObserver:self context:&KVOContext];
    if (nil != _scaledImage.scaledImage) {
        self.image = _scaledImage.scaledImage;
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (((void *)&KVOContext) == context) {
        if ([@"scaledImage" isEqualToString:keyPath]) {
            self.image = _scaledImage.scaledImage;
        } else if ([@"error" isEqualToString:keyPath]) {
            [self willChangeValueForKey:@"imageError"];
            _imageError = _scaledImage.error;
            [self didChangeValueForKey:@"imageError"];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc {
    [_scaledImage removeObserver:self context:&KVOContext];
}

@end
