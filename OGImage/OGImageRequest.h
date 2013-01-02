//
//  OGImageRequest.h
//  OGImageDemo
//
//  Created by Art Gillespie on 1/2/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OGImageLoader.h"

@interface OGImageRequest : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (id)initWithURL:(NSURL *)imageURL completionBlock:(OGImageLoaderCompletionBlock)completionBlock queue:(NSOperationQueue *)queue;
- (void)retrieveImage;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, assign) float progress;
@property (nonatomic, strong) NSError *error;

@end
