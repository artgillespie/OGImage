//
//  OGImageLoader.m
//
//  Created by Art Gillespie on 11/26/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImageLoader.h"
#import "OGImageRequest.h"

#pragma mark - Constants

const NSInteger OGImageLoadingError = -25555;

NSString * const OGImageLoadingErrorDomain = @"OGImageLoadingErrorDomain";

static OGImageLoader * OGImageLoaderInstance;

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
    // A queue solely for file-loading work (e.g., when we get a `file:` or `assets-library:` URL)
    dispatch_queue_t _fileWorkQueue;
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
        _fileWorkQueue = dispatch_queue_create("com.origamilabs.fileWorkQueue", DISPATCH_QUEUE_CONCURRENT);
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
     * `OGImageRequest` instances are pushed onto the LIFO queue (stack) on the
     * serialization queue. It's not important when this happens, so we `dispatch_async`
     * it.
     *
     * Periodically, a timer (see the dispatch_source `_timer` ivar) will call
     * `checkForWork` (also on `_requestsSerializationQueue`) and fire off a network
     * request for the most recently added `OGImageRequest` in `_requests`, assuming
     * the number of in-flight requests is not greater or equal to `self.maxConcurrentNetworkRequests`
     *
     * The idea here is that if a bunch of image load requests come in in a short
     * period of time (as might be the case when, e.g., scrolling a `UITableView`)
     * the most recently requested will always have the highest priority for the next
     * available network request.
     *
     */
    // if this is a file:// or assets-library:// URL, don't bother with a OGImageRequest
    if ([[imageURL scheme] isEqualToString:@"file"]) {
        dispatch_async(_fileWorkQueue, ^{
            UIImage *image = [UIImage imageWithContentsOfFile:[imageURL path]];
            NSError *error = nil;
            if (nil == image) {
                error = [NSError errorWithDomain:OGImageLoadingErrorDomain
                                            code:OGImageLoadingError
                                        userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Couldn't load image from file URL:%@", @""), imageURL]}];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(image, error, 0.);
            });
        });
        return;
    } else if ([[imageURL scheme] isEqualToString:@"assets-library"]) {
        dispatch_async(_fileWorkQueue, ^{

        });
        return;
    }
    dispatch_async(_requestsSerializationQueue, ^{
        // serialize access to the request LIFO 'queue'
        OGImageRequest *info = [[OGImageRequest alloc] initWithURL:imageURL completionBlock:^(UIImage *image, NSError *error, double timeElapsed){
            if (_inFlightRequestCount > 0) {
                _inFlightRequestCount--;
            }
            completionBlock(image, error, timeElapsed);
        } queue:_imageCompletionQueue];
        [_requests addObject:info];
    });
}

#pragma mark - Private

- (void)checkForWork {
    if (self.maxConcurrentNetworkRequests > _inFlightRequestCount && 0 < [_requests count]) {
        OGImageRequest *request = [_requests lastObject];
        [_requests removeLastObject];
        [request retrieveImage];
        _inFlightRequestCount++;
    }
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
