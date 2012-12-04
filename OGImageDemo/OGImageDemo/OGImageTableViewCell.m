//
//  OGImageTableViewCell.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImageTableViewCell.h"
#import "OGScaledImage.h"

@implementation OGImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSAssert(YES == [NSThread isMainThread], @"KVO fired on thread other than main...");
    if ([keyPath isEqualToString:@"scaledImage"]) {
        self.imageView.image = self.image.scaledImage;
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.textLabel.text = [[self.image.url path] lastPathComponent];
        self.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", self.image.loadTime];
    } else if ([keyPath isEqualToString:@"error"]) {
        
    }
}

#pragma mark - Properties

- (void)setImage:(OGScaledImage *)image {
    [_image removeObserver:self forKeyPath:@"error"];
    [_image removeObserver:self forKeyPath:@"scaledImage"];
    _image = image;
    self.imageView.image = _image.scaledImage;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.textLabel.text = [[self.image.url path] lastPathComponent];
    self.detailTextLabel.text = NSLocalizedString(@"Loading", @"");
    [_image addObserver:self forKeyPath:@"error" options:NSKeyValueObservingOptionNew context:nil];
    [_image addObserver:self forKeyPath:@"scaledImage" options:NSKeyValueObservingOptionNew context:nil];
    
}

@end
