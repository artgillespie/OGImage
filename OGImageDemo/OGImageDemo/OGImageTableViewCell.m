//
//  OGImageTableViewCell.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImageTableViewCell.h"
#import "OGScaledImage.h"

static NSString *KVOContext = @"OGImageTableViewCell observation";

@implementation OGImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if( (void *)&KVOContext == context ) {
        NSAssert(YES == [NSThread isMainThread], @"KVO fired on thread other than main...");
        if ([keyPath isEqualToString:@"scaledImage"]) {
            self.imageView.image = self.image.scaledImage;
            self.textLabel.text = [[self.image.url path] lastPathComponent];
            self.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", self.image.loadTime];
        } else if ([keyPath isEqualToString:@"error"]) {
            
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Properties

- (void)setImage:(OGScaledImage *)image {
    /*
     * When the cell's image is set, we want to first make sure we're no longer listening
     * for any KVO notifications on the cell's previous image.
     */
    [_image removeObserver:self forKeyPath:@"error" context:&KVOContext];
    [_image removeObserver:self forKeyPath:@"scaledImage" context:&KVOContext];
    _image = image;
    self.imageView.image = _image.scaledImage;
    self.textLabel.text = [[self.image.url path] lastPathComponent];
    self.detailTextLabel.text = NSLocalizedString(@"Loading", @"");
    [_image addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:&KVOContext];
    [_image addObserver:self forKeyPath:@"scaledImage" options:NSKeyValueObservingOptionNew context:&KVOContext];
}

- (void)dealloc {
    [_image removeObserver:self forKeyPath:@"error" context:&KVOContext];
    [_image removeObserver:self forKeyPath:@"scaledImage" context:&KVOContext];
}

@end
