//
//  OGImageLoader.m
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
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
    // The queue on which our `NSURLConnection` completion block is executed.
    NSOperationQueue *_imageCompletionQueue;
    // A LIFO queue of _OGImageLoaderInfo instances
    NSMutableArray *_requests;
    // Serializes access to the the request queue
    dispatch_queue_t _requestsSerializationQueue;

    NSInteger _inFlightRequestCount;
    // We use this timer to periodically check _requestSerializationQueue for requests to fire off
    dispatch_source_t _timer;
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
        _requestsSerializationQueue = dispatch_queue_create("com.origamilabs.requestSerializationQueue", DISPATCH_QUEUE_SERIAL);
        self.priority = OGImageLoaderPriority_Low;
        _imageCompletionQueue = [[NSOperationQueue alloc] init];
        // make our network completion calls serial so there's no thrashing.
        _imageCompletionQueue.maxConcurrentOperationCount = 1;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _requestsSerializationQueue);
        dispatch_source_set_event_handler(_timer, ^{
            [self checkForWork];
        });
        // 33ms timer w/10 ms leeway
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 33000000, 10000000);
        dispatch_resume(_timer);
    }
    return self;
}

- (void)dealloc {
    dispatch_suspend(_timer);
}

- (void)enqueueImageRequest:(NSURL *)imageURL completionBlock:(OGImageLoaderCompletionBlock)completionBlock {
    /**
     *
     * What we basically have here is a LIFO queue (or stack, if you prefer) in `_requests` access to which
     * is serialized by the serial dispatch queue `_requestsSerializationQueue`.
     * (The overloaded use of the term "queue" here is a possible source of confusion.
     * The former is a data structure, the latter is a GCD queue, used here in
     * place of a lock or mutex.)
     *
     * `_OGImageLoaderInfo` instances are pushed onto the LIFO queue (stack) on the
     * serialization stack. It's not important when this happens, so we `dispatch_async`
     * it.
     *
     * Periodically, a timer (see the dispatch_source `_timer` ivar) will call
     * `checkForWork` (also on `_requestsSerializationQueue`) and fire off a network
     * request for the most recently added `_OGImageLoaderInfo` in `_requests`, assuming
     * the number of in-flight requests is not greater or equal to `self.maxConcurrentNetworkRequests`
     *
     * The idea here is that if a bunch of image load requests come in in a short
     * period of time (as might be the case when, e.g., scrolling a `UITableView`)
     * the most recently requested will always have the highest priority for the next
     * available network request.
     *
     */
    dispatch_async(_requestsSerializationQueue, ^{
        // serialize access to the request LIFO 'queue'
        _OGImageLoaderInfo *info = [_OGImageLoaderInfo infoWithURL:imageURL block:completionBlock];
        [_requests addObject:info];
    });
}

#pragma mark - Private

- (void)checkForWork {
    if (self.maxConcurrentNetworkRequests > _inFlightRequestCount && 0 < [_requests count]) {
        _OGImageLoaderInfo *info = [_requests lastObject];
        [_requests removeLastObject];
        [self performRequestWithInfo:info];
    }
}

- (void)performRequestWithInfo:(_OGImageLoaderInfo *)info {

    // TODO: [alg] Should we have separate handling for file URLs?

    NSURLRequest *request = [NSURLRequest requestWithURL:info.url];
    NSDate *startTime = [NSDate date];
    [NSURLConnection sendAsynchronousRequest:request queue:_imageCompletionQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSTimeInterval elapsed = fabs([startTime timeIntervalSinceNow]);
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
            info.block(tmpImage, tmpError, elapsed);
        });
        _inFlightRequestCount--;
    }];
    _inFlightRequestCount++;
}

#pragma mark - Properties

- (void)setPriority:(OGImageLoaderPriority)priority {
    _priority = priority;
    dispatch_queue_priority_t newPriority = DISPATCH_QUEUE_PRIORITY_LOW;
    if (OGImageLoaderPriority_High == _priority) {
        newPriority = DISPATCH_QUEUE_PRIORITY_HIGH;
    } else if (OGImageLoaderPriority_Default) {
        newPriority = DISPATCH_QUEUE_PRIORITY_DEFAULT;
    }
    dispatch_set_target_queue(_requestsSerializationQueue, dispatch_get_global_queue(newPriority, 0));
}

@end
