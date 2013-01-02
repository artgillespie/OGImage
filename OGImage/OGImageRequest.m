//
//  OGImageRequest.m
//  OGImageDemo
//
//  Created by Art Gillespie on 1/2/13.
//  Copyright (c) 2013 Origami Labs. All rights reserved.
//

#import "OGImageRequest.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_INFO;

@implementation OGImageRequest {
    NSDate *_startTime;
    OGImageLoaderCompletionBlock _completionBlock;
    NSOperationQueue *_delegateQueue;
    NSMutableData *_data;
    long _contentLength;
    NSHTTPURLResponse *_httpResponse;
}

- (id)initWithURL:(NSURL *)imageURL completionBlock:(OGImageLoaderCompletionBlock)completionBlock queue:(NSOperationQueue *)queue {
    self = [super init];
    if (nil != self) {
        self.url = imageURL;
        _delegateQueue = queue;
        _completionBlock = completionBlock;
    }
    return self;
}

- (void)retrieveImage {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [conn setDelegateQueue:_delegateQueue];
    _startTime = [[NSDate alloc] init];
    [conn start];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    DDLogInfo(@"didFailWithError:%@", error);
    self.error = error;
    dispatch_async(dispatch_get_main_queue(), ^{
        _completionBlock(nil, self.error, 0.);
    });
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _httpResponse = (NSHTTPURLResponse *)response;
    DDLogInfo(@"didReceiveResponse: %@", _httpResponse);
    _contentLength = [_httpResponse.allHeaderFields[@"Content-Length"] intValue];
    DDLogInfo(@"contentSize: %ld", _contentLength);
    _data = [NSMutableData dataWithCapacity:_contentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
    self.progress = (float)_data.length / (float)_contentLength;
    DDLogInfo(@"progress: %f", self.progress);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    DDLogInfo(@"connectionDidFinishLoading : %ud : %ld", _data.length, _contentLength);
    [self prepareImageAndNotify];
}

- (void)prepareImageAndNotify {
    UIImage *tmpImage = nil;
    NSError *tmpError = nil;
    if (200 == _httpResponse.statusCode) {
        if (nil != _data) {
            tmpImage = [UIImage imageWithData:_data];
            if (nil == tmpImage) {
                // data isn't nil, but we couldn't create an image out of it...
                tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:OGImageLoadingError userInfo:@{NSLocalizedDescriptionKey : @"OGImage: Received data from url, but couldn't create UIImage instance"}];
            }
        }
    } else {
        // if we get here, we have an http status code other than 200
        tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:OGImageLoadingError userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"OGImage: Received http status code: %d", _httpResponse.statusCode]}];
    }
    NSAssert((nil == tmpImage && nil != tmpError) || (nil != tmpImage && nil == tmpError), @"One of tmpImage or tmpError should be non-nil");
    dispatch_async(dispatch_get_main_queue(), ^{
        _completionBlock(tmpImage, tmpError, -[_startTime timeIntervalSinceNow]);
    });
}

@end
