//
//  OGCachedImage.h
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImage.h"

@interface OGCachedImage : OGImage

- (id)initWithURL:(NSURL *)url key:(NSString *)key;
- (id)initWithURL:(NSURL *)url key:(NSString *)key placeholderImage:(UIImage *)placeholderImage;

@property (nonatomic, strong) NSString *key;

@end
