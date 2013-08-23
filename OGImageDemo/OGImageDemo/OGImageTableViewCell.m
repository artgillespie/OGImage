//
//  OGImageTableViewCell.m
//  OGImageDemo
//
//  Created by Art Gillespie on 11/27/12.
//  Copyright (c) 2012 Origami Labs, Inc.. All rights reserved.
//

#import "OGImageTableViewCell.h"

@implementation OGImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        OGImageView *tmp = [[OGImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.bounds.size.height, self.bounds.size.height)];
        tmp.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self.contentView addSubview:tmp];
        _ogImageView = tmp;
        _ogImageView.clipsToBounds = YES;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // move the textLabel over to accomodate the ogImageView
    CGRect f = self.textLabel.frame;
    f.origin.x = self.ogImageView.bounds.size.width + 5.f;
    if (self.bounds.size.width - 10.f < f.origin.x + f.size.width) {
        f.size.width = self.bounds.size.width - 10.f - f.origin.x;
    }
    self.textLabel.frame = f;
}

@end
