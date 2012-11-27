//
//  OGImageLoader.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs. All rights reserved.
//

#import "OGImageLoader.h"

#pragma mark - Constants

const NSInteger OGImageLoadingError = -25555;

static OGImageLoader * OGImageLoaderInstance;

#pragma mark -

@interface _OGImageLoaderInfo : NSObject

+ (_OGImageLoaderInfo *)infoWithURL:(NSURL *)url block:(OGImageLoaderCompletionBlock)block;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, copy) OGImageLoaderCompletionBlock block;

@end

@implementation _OGImageLoaderInfo

+ (_OGImageLoaderInfo *)infoWithURL:(NSURL *)url block:(OGImageLoaderCompletionBlock)block {
    _OGImageLoaderInfo *info = [[_OGImageLoaderInfo alloc] init];
    info.url = url;
    info.block = block;
    return info;
}

@end

#pragma mark -

@implementation OGImageLoader {
    // Blocks on this queue check to see if it's time to fire off another request
    dispatch_queue_t _requestWorkerQueue;
    // The queue on which our `NSURLConnection` completion block is executed.
    NSOperationQueue *_imageCompletionQueue;
    // A LIFO queue of _OGImageLoaderInfo instances
    NSMutableArray *_requests;
    // Serializes access to the the request queue
    dispatch_queue_t _requestsSerializationQueue;

    NSInteger _inFlightRequestCount;
}

+ (OGImageLoader *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        OGImageLoaderInstance = [[OGImageLoader alloc] init];
    });
    return OGImageLoaderInstance;
}

- (id)init {
    self = [super init];
    if (nil != self) {
        self.maxConcurrentNetworkRequests = 4;
        _requests = [NSMutableArray arrayWithCapacity:128];
        _requestsSerializationQueue = dispatch_queue_create("com.origami.requestSerializationQueue", DISPATCH_QUEUE_SERIAL);
        _requestWorkerQueue = dispatch_queue_create("com.origami.requestWorkerQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_requestWorkerQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        _imageCompletionQueue = [[NSOperationQueue alloc] init];
        // make our network completion calls serial so there's no thrashing.
        _imageCompletionQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)enqueueImageRequest:(NSURL *)imageURL completionBlock:(OGImageLoaderCompletionBlock)completionBlock {
    /**
     * This could get confusing, so let me record my thinking here for posterity:
     *
     * What we basically have here is a LIFO queue (or stack, if you prefer) in `_requests` access to which
     * is serialized by the serial dispatch queue `_requestsSerializationQueue`.
     * (The overloaded use of the term "queue" here is a possible source of confusion.
     * The former is a data structure, the latter is a GCD queue, used here in
     * place of a lock or mutex.)
     *
     * `_OGImageLoaderInfo` instances are pushed onto the LIFO queue (stack) on the
     * serialization stack. It's not important when this happens, so we `dispatch_async`
     * it. When the request is enqueued, we also enqueue a block operation onto
     * the network queue that will act as the LIFO queue's consumer. Whenever the
     * network queue (which is concurrent) can, it will grab the last queued object
     * off the LIFO queue (which may or may not correspond to the object that was
     * queued when the block operation was created)
     *
     * The idea here is that if a bunch of image load requests come in in a short
     * period of time (as might be the case when, e.g., scrolling a `UITableView`,
     * the most recently requested will always have the highest priority for the next
     * available network request.
     *
     * This is essentially a poor-man's quick-and-dirty producer/consumer implementation.
     */
    dispatch_async(_requestsSerializationQueue, ^{
        // serialize access to the request LIFO 'queue'
        _OGImageLoaderInfo *info = [_OGImageLoaderInfo infoWithURL:imageURL block:completionBlock];
        [_requests addObject:info];
        [self checkForWork];
    });
}

#pragma mark - Private

- (void)checkForWork {
    dispatch_async(_requestsSerializationQueue, ^{
        while(self.maxConcurrentNetworkRequests >= _inFlightRequestCount && 0 < [_requests count]) {
            _OGImageLoaderInfo *info = [_requests lastObject];
            [_requests removeLastObject];
            [self performRequestWithInfo:info];
        }
    });
}

- (void)performRequestWithInfo:(_OGImageLoaderInfo *)info {
    // TODO: [alg] We need to have separate handling for file URLs

    // TODO: we might want to tweak the cache policy here?
    NSURLRequest *request = [NSURLRequest requestWithURL:info.url];
    [NSURLConnection sendAsynchronousRequest:request queue:_imageCompletionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSError *tmpError = nil;
        UIImage *tmpImage = nil;
        if (nil != error) {
            tmpError = error;
        } else if (YES == [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (200 == httpResponse.statusCode) {
                if (nil != data) {
                    tmpImage = [UIImage imageWithData:data];
                    if (nil == tmpImage) {
                        // data isn't nil, but we couldn't create an image out of it...
                        tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:OGImageLoadingError userInfo:@{NSLocalizedDescriptionKey : @"OGImage: Received data from url, but couldn't create UIImage instance"}];
                    }
                }
            } else {
                // if we get here, we have an http status code other than 200
                tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:OGImageLoadingError userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"OGImage: Received http status code: %d", httpResponse.statusCode]}];
            }
        } else if (nil == data) {
            // in this case, it wasn't an HTTP request and we don't have any data (but there was no error)
            tmpError = [NSError errorWithDomain:NSCocoaErrorDomain code:OGImageLoadingError userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"OGImage: no image data received."]}];
        }
        NSAssert((nil == tmpImage && nil != tmpError) || (nil != tmpImage && nil == tmpError), @"One of tmpImage or tmpError should be non-nil");
        dispatch_async(dispatch_get_main_queue(), ^{
            info.block(tmpImage, tmpError);
        });
        _inFlightRequestCount--;
        [self checkForWork];
    }];
    _inFlightRequestCount++;
}

@end
