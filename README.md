OGImage
=======

## Backwards compatibility

Note that 0.0.4 on the master branch breaks backwards compatibility with < 0.0.3. You'll need to
change all your `addObserver:` calls to `addObserver:context:` and `removeObserver:`
to `removeObserver:context:` See [Pull Request 23](https://github.com/origamilabs/OGImage/pull/23) for
more information.

## Introduction

The idea behind `OGImage` is to encapsulate best practices for loading images
over HTTP in a simple, extensible interface.

### OGImageView

If all you need is to load an image and display it in a `UIImageView`, check out
`OGImageView`, a `UIImageView` subclass that adds a single method:

```objc

   [cell.ogImageView setImageURL:someURL placeholder:[UIImage imageNamed:@"placeholder"]];

```

This one call will handle fetching the image at `someURL` (regardless of whether it's a network, file
or even `assets-library:` url), scaling it to the `OGImageView`s `bounds.size` obeying `contentMode` *and*
caching it in memory and on-disk, and swapping out your placeholder image with the new image.

Furthermore, if `setImageURL:placeholder:` is called on an existing `OGImageView` instance (e.g., when
its containing `UITableViewCell` is recycled) `OGImageView` will behave as you'd expect: It loses interest
in the previously requested URL and the current URL is given first priority for fetching/processing.

### Philosophy

* The default use case should be *ridiculously* simple to execute (see <code>[OGImageView](#OGImageView)</code>). In OGImage,
  you can load, cache, and scale an image with the following call:

    ```objc
    static NSString *KVOContext = @"OGImage observation";

    ...

    OGScaledImage *ogImage = [[OGScaledImage alloc] initWithURL:imageURL size:renderSize key:nil];
    /*
     * This is shorthand for calling KVO methods for @"image", @"scaledImage", and @"error"
     */
    [ogImage addObserver:self context:&KVOContext];

    // check to see if the image loaded instantly (e.g., from cache)
    if (nil != ogImage.image) {
        // we already have an image, so do whatever we need with it, otherwise
        // we'll be notified in `observeValueForKeyPath:ofObject:change:context:` whenever the image changes
        [self displayImage:ogImage.image];
        // ooh, we also got all the image's metadata! Sweet!
        NSDictionary *exifData = [ogImage.originalFileProperties valueForKey:kCGImagePropertyExifDictionary];
    }
    ```

* Networking belongs in the Model. Views (and to some degree, Controllers)
  shouldn't know anything about where images come from: That's the model's job.
  OGImage is designed as a model object: Controllers and Views learn about
  changes to it (e.g., when an image has loaded) through KVO.
* Generally, more recently requested images should have higher loading
  priority. For example, if images are being loaded on demand as a user scrolls
  through a table view, the user experience is improved if they don't have to
  wait for all the images they've scrolled past to load before the images that
  are visible are loaded. At the same time, we don't believe in waiting until a
  table view has finished scrolling to start loading images.  OGImage addresses
  these competing requirements by pushing image load requests into a LIFO
  queue.
* Each subsystem should have its own GCD queue.

## Installation

To use OGImage in your projects, simply add the files in the `OGImage`
subdirectory to your target.

You'll need to add `AssetsLibrary.framework` and `ImageIO.framework` to your
target's "Link Binary With Libraries" build phase. If you're using
`OGScaledImage` and/or `OGImageProcessing`, you'll additionally need to add
`Accelerate.framework` and `AssetsLibrary.framework` to your target's "Link
Binary With Libraries" build phase.

## Usage

OGImage has a simple interface; just instantiate with the image's URL and
listen for KVO notifications on the `image` property. You can also specify a
placeholder image to use until loading is complete with
`initWithURL:placeholderImage`

```objc
#import "OGImage.h"

static NSString *KVOContext = @"OGImage observation";

...

OGImage *image = [[OGImage alloc] initWithURL:[NSURL URLWithString:@"http://somedomain.com/someimage.jpg"]];
[image addObserver:self context:&KVOContext];

...

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ((void *)&KVOContext == context) {
        if ([keyPath isEqualToString:@"image"]) {
            // image was loaded!
            ...
        } else if ([keyPath isEqualToString:@"error"]) {
            // error loading image
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

There are also caching (`OGCachedImage`) and caching+scaling (`OGScaledImage`)
subclasses that provide useful functionality and demonstrate how to go about
bending OGImage to your needs via subclassing.

```objc

#import "OGScaledImage.h"

static NSString *KVOContext = @"OGImage observation";

...

/*
 * The image at `imageURL` will be loaded from one of in-memory cache, disk cache or
 * over the network and scaled to `scaledSize`. Note that if the image at `imageURL`
 * has already been scaled to `scaledSize` in the past, OGScaledImage will simply
 * load the scaled image from cache.
 */
OGScaledImage *image = [[OGScaledImage alloc] initWithURL:imageURL size:scaledSize key:nil];

/*
 * Note that here we're interested in the `scaledImage` property, not the full-size `image`
 * property.
 */
[image addObserver:self context:&KVOContext];

...

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ((void *)&KVOContext == context) {
        if ([keyPath isEqualToString:@"scaledImage"]) {
            // image was loaded and scaled!
            ...
        } else if ([keyPath isEqualToString:@"error"]) {
            // error loading image
        }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```

## Demo and Tests

This repo contains a very simple project that demonstrates the use of
`OGScaledImage` with a stock `UITableView`.

To run the demo and tests in the `OGImageDemo project`, you'll need
[CocoaPods](http://cocoapods.org/) If you already have cocoapods on your
system, just run `pod install` from the terminal in the `OGImageDemo`
directory.

Note that you *do not* need cocoapods to use `OGImage` in your projects--there
are no external dependencies for the library itself, only for the tests
(GHUnit) and demo (CocoaLumberjack)

## Key-Value Observing

If you haven't used KVO before or if you're rusty, be sure check out [Key-Value Observing Programming Guide](http://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/KeyValueObserving/KeyValueObserving.html) 
and [Dave Dribin's excellent 'Proper Key-Value Observer Usage'](http://www.dribin.org/dave/blog/archives/2008/09/24/proper_kvo_usage/)

## TODO:

See [issues](https://github.com/origamilabs/OGImage/issues)


