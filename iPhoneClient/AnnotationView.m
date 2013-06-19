//
//  AnnotationView.m
//  ARIS
//
//  Created by Brian Deith on 8/11/09.
//  Copyright 2009 Brian Deith. All rights reserved.
//

#import "AppModel.h"
#import "ARISAppDelegate.h"
#import "AsyncMediaImageView.h"
#import "AnnotationView.h"
#import "Annotation.h"
#import "Media.h"
#import "NearbyObjectProtocol.h"

#define POINTER_LENGTH 10
#define WIGGLE_DISTANCE 3.0
#define WIGGLE_SPEED 0.3
#define WIGGLE_FRAMELENGTH 0.05 //<-The lower = the faster
#define ANNOTATION_MAX_WIDTH 300
#define ANNOTATION_PADDING 5.0
#define IMAGE_HEIGHT 30
#define IMAGE_WIDTH 30

@interface AnnotationView()
{
    CGRect titleRect;
	CGRect subtitleRect;
	CGRect contentRect;
	UIFont *titleFont;
	UIFont *subtitleFont;
	NSMutableData *asyncData;
	UIImage *icon;
	AsyncMediaImageView *iconView;
    bool showTitle;
    bool shouldWiggle;
    float totalWiggleOffsetFromOriginalPosition;
    float incrementalWiggleOffset;
    float xOnSinWave;
}

@end

@implementation AnnotationView

- (id)initWithAnnotation:(Annotation *)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier])
    {
        titleFont = [UIFont fontWithName:@"Arial" size:18];
        subtitleFont = [UIFont fontWithName:@"Arial" size:12];
#warning add in?
      //  showTitle = (annotation.location.showTitle && annotation.title != nil && ![annotation.title isEqualToString:@""]) ? YES : NO;
      //  shouldWiggle = annotation.location.wiggle;
        totalWiggleOffsetFromOriginalPosition = 0;
        incrementalWiggleOffset = 0;
        xOnSinWave = 0;

        CGRect imageViewFrame;
        if(showTitle || annotation.kind == NearbyObjectPlayer) {
            //Find width of annotation
            CGSize titleSize = [annotation.title sizeWithFont:titleFont];
            CGSize subtitleSize = [annotation.subtitle sizeWithFont:subtitleFont];
            int maxWidth = titleSize.width > subtitleSize.width ? titleSize.width : subtitleSize.width;
            if(maxWidth > ANNOTATION_MAX_WIDTH) maxWidth = ANNOTATION_MAX_WIDTH;
            
            titleRect = CGRectMake(0, 0, maxWidth, titleSize.height);
            if (annotation.subtitle)
                subtitleRect = CGRectMake(0, titleRect.origin.y+titleRect.size.height, maxWidth, subtitleSize.height);
            else
                subtitleRect = CGRectMake(0,0,0,0);
            
            contentRect=CGRectUnion(titleRect, subtitleRect);
            contentRect.size.width += ANNOTATION_PADDING*2;
            contentRect.size.height += ANNOTATION_PADDING*2;
            
            titleRect=CGRectOffset(titleRect, ANNOTATION_PADDING, ANNOTATION_PADDING);
            if(annotation.subtitle) subtitleRect=CGRectOffset(subtitleRect, ANNOTATION_PADDING, ANNOTATION_PADDING);
            
            imageViewFrame = CGRectMake((contentRect.size.width/2)-(IMAGE_WIDTH/2), 
                                        contentRect.size.height+POINTER_LENGTH, 
                                        IMAGE_WIDTH, 
                                        IMAGE_HEIGHT);
            self.centerOffset = CGPointMake(0, ((contentRect.size.height+POINTER_LENGTH+IMAGE_HEIGHT)/-2)+(IMAGE_HEIGHT/2));
        }
        else
        {
            contentRect=CGRectMake(0,0,0,0);
            imageViewFrame = CGRectMake(0, 0, IMAGE_WIDTH, IMAGE_HEIGHT);
            //self.centerOffset = CGPointMake(IMAGE_WIDTH/-2.0, IMAGE_HEIGHT/-2.0);
        }
        
        [self setFrame: CGRectUnion(contentRect, imageViewFrame)];

        iconView = [[AsyncMediaImageView alloc] init];
        [iconView setFrame:imageViewFrame];
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        
        [self addSubview:iconView];
        
        iconView.userInteractionEnabled = NO;
        
        //Only load the icon media if it is > 0, otherwise, lets load a default
        if (annotation.iconMediaId > 0) {
            Media *iconMedia = [[AppModel sharedAppModel] mediaForMediaId:annotation.iconMediaId];
            [iconView loadImageFromMedia:iconMedia];
        }
#warning recomment in and fix numbers
 /*       else if (annotation.iconMediaId < 0)
        {
            if(annotation.iconMediaId == -1) ...
            else if(annotation.iconMediaId == -2) ...
            else iconView.image = [UIImage imageNamed:@"noteicon.png"];
        } */
        else if (annotation.kind == NearbyObjectItem)    iconView.image = [UIImage imageNamed:@"item.png"];
        else if (annotation.kind == NearbyObjectNode)    iconView.image = [UIImage imageNamed:@"page.png"];
        else if (annotation.kind == NearbyObjectNPC)     iconView.image = [UIImage imageNamed:@"npc.png"];
        else if (annotation.kind == NearbyObjectPlayer)  iconView.image = [UIImage imageNamed:@"player.png"];
        else if (annotation.kind == NearbyObjectWebPage) iconView.image = [UIImage imageNamed:@"page.png"];
        else if (annotation.kind == NearbyObjectNote)    iconView.image = [UIImage imageNamed:@"noteicon.png"]; //annotation.icon
        
        self.opaque = NO; 
    }
    return self;
}

- (void)dealloc {
	asyncData= nil;
	[iconView removeFromSuperview];
}

- (void)drawRect:(CGRect)rect {
    if (showTitle) {
        CGMutablePathRef calloutPath = CGPathCreateMutable();
        CGPoint pointerPoint = CGPointMake(contentRect.origin.x + 0.5 * contentRect.size.width,  contentRect.origin.y + contentRect.size.height + POINTER_LENGTH);
        CGFloat radius = 7.0;
        CGPathMoveToPoint(calloutPath, NULL, CGRectGetMinX(contentRect) + radius, CGRectGetMinY(contentRect));
        CGPathAddArc(calloutPath, NULL, CGRectGetMaxX(contentRect) - radius, CGRectGetMinY(contentRect) + radius, radius, 3 * M_PI / 2, 0, 0);
        CGPathAddArc(calloutPath, NULL, CGRectGetMaxX(contentRect) - radius, CGRectGetMaxY(contentRect) - radius, radius, 0, M_PI / 2, 0);
        
        CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x + 10.0, CGRectGetMaxY(contentRect));
        CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x, pointerPoint.y);
        CGPathAddLineToPoint(calloutPath, NULL, pointerPoint.x - 10.0,  CGRectGetMaxY(contentRect));
        
        CGPathAddArc(calloutPath, NULL, CGRectGetMinX(contentRect) + radius, CGRectGetMaxY(contentRect) - radius, radius, M_PI / 2, M_PI, 0);
        CGPathAddArc(calloutPath, NULL, CGRectGetMinX(contentRect) + radius, CGRectGetMinY(contentRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);	
        CGPathCloseSubpath(calloutPath);
        
        CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
        [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8] set];
        CGContextFillPath(UIGraphicsGetCurrentContext());
        [[UIColor whiteColor] set];
        [self.annotation.title drawInRect:titleRect withFont:titleFont lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentCenter];
        [self.annotation.subtitle drawInRect:subtitleRect withFont:subtitleFont lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentCenter];
        CGContextAddPath(UIGraphicsGetCurrentContext(), calloutPath);
        CGContextStrokePath(UIGraphicsGetCurrentContext());
    }
    
    if(shouldWiggle)
    {
        xOnSinWave += WIGGLE_SPEED;
        float oldTotal = totalWiggleOffsetFromOriginalPosition;
        totalWiggleOffsetFromOriginalPosition = sin(xOnSinWave) * WIGGLE_DISTANCE;
        incrementalWiggleOffset = totalWiggleOffsetFromOriginalPosition-oldTotal;
        iconView.frame = CGRectOffset(iconView.frame, 0.0f, incrementalWiggleOffset);
        [self performSelector:@selector(setNeedsDisplay) withObject:nil afterDelay:WIGGLE_FRAMELENGTH];
    }
}	

@end