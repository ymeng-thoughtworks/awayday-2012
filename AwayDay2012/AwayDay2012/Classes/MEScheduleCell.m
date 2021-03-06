//
//  MEScheduleCell.m
//  AwayDay2012
//
//  Created by Meng Yu on 6/29/12.
//  Copyright (c) 2012 ThoughtWorks. All rights reserved.
//

#import "MEScheduleCell.h"
#import "MEColor.h"
#import "MEFont.h"
#import "METimeFormat.h"
#import "UILabelExtension.h"

#define X_IN_EDITING_MODE         10
#define X_IN_INITIALIZATION_MODE  0
#define IMAGE_SELECTED            @"selected.png"
#define IMAGE_NOT_SELECTED        @"not-selected.png"
#define COLOR_FOR_TITLE           UIColorFromRGB(0x000000)
#define COLOR_FOR_TIME_INTERVAL   UIColorFromRGB(0x787878)
#define COLOR_FOR_LECTURER        UIColorFromRGB(0x787878)

@interface MEScheduleCell ()

- (void)exchangeIndicatorShown:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end

@implementation MEScheduleCell

@synthesize titleLabel, lecturerLabel, timeIntervalLabel, selectionIndicator, favoriteIndicator;
@synthesize title, lecturer, from, to;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self->originalAccessoryType = self.accessoryType;
    }
    return self;
}

- (void)setTitle:(NSString *)_title {
    if (self->title == _title) {
        return;
    }
    
    [self->title release];
    self->title = [_title retain];
    
    titleLabel.text = self->title;
}

- (void)setLecturer:(NSString *)_lecturer {
    if (self->lecturer == _lecturer) {
        return;
    }
    
    [self->lecturer release];
    self->lecturer = [_lecturer retain];
    
    lecturerLabel.text = self->lecturer ? [NSString stringWithFormat:@"by %@", self->lecturer] : @"";
    lecturerLabel.hidden = self->lecturer ? NO : YES;
}

- (void)setFrom:(CGFloat)_from {
    self->from = _from;
    
    timeIntervalLabel.text = TimeIntervalString(self->from, self->to);
}

- (void)setTo:(CGFloat)_to {
    self->to = _to;
    
    timeIntervalLabel.text = TimeIntervalString(self->from, self->to);
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    BOOL isEditing = ((UITableView *)self.superview).isEditing;
    
    [titleLabel withColor:COLOR_FOR_TITLE font:MEFONT_CENTURY_GOTHIC size:14];
    [timeIntervalLabel withColor:COLOR_FOR_TIME_INTERVAL font:MEFONT_CENTURY_GOTHIC size:11];
    [lecturerLabel withColor:COLOR_FOR_LECTURER font:MEFONT_CENTURY_GOTHIC size:11];

    [UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(exchangeIndicatorShown:finished:context:)];
    
	[super layoutSubviews];
    
    CGRect contentFrame = self.contentView.frame;
    
	if (isEditing) {
		contentFrame.origin.x = X_IN_EDITING_MODE;
		self.contentView.frame = contentFrame;
        self.accessoryType = UITableViewCellAccessoryNone;
        favoriteIndicator.hidden = YES;
	} else {
		contentFrame.origin.x = X_IN_INITIALIZATION_MODE;
		self.contentView.frame = contentFrame;
        selectionIndicator.hidden = YES;
	}
    
	[UIView commitAnimations];
    
    selectionIndicator.image = self.isSelected ? [UIImage imageNamed:IMAGE_SELECTED] : [UIImage imageNamed:IMAGE_NOT_SELECTED];
}

- (void)exchangeIndicatorShown:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (![finished boolValue]) {
        return;
    }
    
    BOOL isEditing = ((UITableView *)self.superview).isEditing;
    if (isEditing) {
        selectionIndicator.hidden = NO;
    } else {
        self.accessoryType = self->originalAccessoryType;
    }
}

- (void)dealloc {
    [titleLabel release];
    [lecturerLabel release];
    [timeIntervalLabel release];
    [selectionIndicator release];
    [favoriteIndicator release];
    
    [self->title release];
    [self->lecturer release];
        
    [super dealloc];
}

+ (NSString *)nibName {
    return @"schedule-cell";
}

@end
