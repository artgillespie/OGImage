//
//  OGScaledImage.h
//  OGImageDemo
//
//  Created by Art Gillespie on 12/4/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGCachedImage.h"

@interface OGScaledImage : OGCachedImage

- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key;
- (id)initWithURL:(NSURL *)url size:(CGSize)size key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

@property (nonatomic, strong) UIImage *scaledImage;

@end
