//
//  OGImageProblematicProcessingTests.m
//  OGImageDemo
//
//  Created by Sixten Otto on 3/14/14.
//  Copyright (c) 2014 Sixten Otto. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <GHUnitIOS/GHUnit.h>
#import "OGImageProcessing.h"
#import "OGScaledImage.h"
#import "OGImageCache.h"

extern OSStatus UIImageToVImageBuffer(UIImage *image, vImage_Buffer *buffer, CGImageAlphaInfo alphaInfo);

static NSString *KVOContext = @"OGImageProblematicProcessingTests observation";
static const CGSize TEST_SCALE_SIZE = {100.f, 20.f};

@interface NoOpAssertionHandler : NSAssertionHandler
@end


@interface OGImageProblematicProcessingTests : GHAsyncTestCase
@end

@implementation OGImageProblematicProcessingTests

- (void)setUp {
    // make sure we get the image from the network
    [[OGImageCache shared] purgeCache:YES];
}

- (void)tearDown {
    // clean up the in-memory and disk cache when we're done
    [[OGImageCache shared] purgeCache:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if( (void *)&KVOContext == context ) {
    NSAssert(YES == [NSThread isMainThread], @"Expected `observeValueForKeyPath` to only be called on main thread");
    if( [keyPath isEqualToString:@"scaledImage"] ) {
      OGScaledImage *image = (OGScaledImage *)object;
      GHTestLog(@"Scaled image loaded: %@ : %@", image.image, NSStringFromCGSize(image.scaledImage.size));
      if( nil == image ) {
        [self notify:kGHUnitWaitStatusFailure];
      }
      else {
        [self notify:kGHUnitWaitStatusSuccess];
      }
      return;
    }
  }
  else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)testScalingGif
{
  [self prepare];
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"moldex-logo" withExtension:@"gif"];
  OGScaledImage *image = [[OGScaledImage alloc] initWithURL:url size:TEST_SCALE_SIZE key:nil];
  [image addObserver:self context:&KVOContext];
  [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.];
  [image removeObserver:self context:&KVOContext];
}

- (void)testCachingNil
{
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"moldex-logo" withExtension:@"gif"];
  __OGImage *image = [[__OGImage alloc] initWithDataAtURL:url];
  GHAssertNotNil(image, @"Couldn't decode test image");
  
  // make sure that the test isn't interrupted by assert failure
  NSAssertionHandler *oldHandler = [[[NSThread currentThread] threadDictionary] valueForKey:NSAssertionHandlerKey];
  NSAssertionHandler *tempHandler = [NoOpAssertionHandler new];
  [[[NSThread currentThread] threadDictionary] setValue:tempHandler forKey:NSAssertionHandlerKey];
  
  GHAssertNoThrowSpecific([[OGImageCache shared] setImage:nil forKey:@"foo"], NSException, NSInvalidArgumentException, @"Attempting to insert a nil image should not throw");
  GHAssertNoThrowSpecific([[OGImageCache shared] setImage:image forKey:nil], NSException, NSInvalidArgumentException, @"Attempting to insert with a nil key should not throw");
  
  [[[NSThread currentThread] threadDictionary] setValue:oldHandler forKey:NSAssertionHandlerKey];
}

- (void)testConvertingBadAlpha_Last
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"moldex-logo" ofType:@"gif"];
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
  
  vImage_Buffer vBuffer;
  OSStatus result = UIImageToVImageBuffer(image, &vBuffer, kCGImageAlphaLast);
  GHAssertErr(OGImageProcessingError, result, @"Operation should report failure");
  GHAssertNULL(vBuffer.data, @"Buffer should have NULL data pointer");
}

- (void)testConvertingBadAlpha_First
{
  NSString *path = [[NSBundle mainBundle] pathForResource:@"moldex-logo" ofType:@"gif"];
  UIImage *image = [[UIImage alloc] initWithContentsOfFile:path];
  
  vImage_Buffer vBuffer;
  OSStatus result = UIImageToVImageBuffer(image, &vBuffer, kCGImageAlphaFirst);
  GHAssertErr(OGImageProcessingError, result, @"Operation should report failure");
  GHAssertNULL(vBuffer.data, @"Buffer should have NULL data pointer");
}

@end

@implementation NoOpAssertionHandler

- (void)handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...
{
  NSLog(@"Assertion failure (ignored): %@ for object %@ in %@#%i", NSStringFromSelector(selector), object, fileName, line);
}

- (void)handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(NSString *)format, ...
{
  NSLog(@"Assertion failure (ignored): %@ in %@#%i", functionName, fileName, line);
}

@end

