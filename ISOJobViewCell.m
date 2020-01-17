//
//  ISOJobViewCell.m
//  Halime
//
//  Created by Imdat Solak on Sun Mar 10 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOJobViewCell.h"
#import "ISOLogger.h"
#import "ISOSubscriptionMgr.h"
#import "ISOSubscription.h"

@implementation ISOJobViewCell
#define MAC_MAX_IMAGE_NO 7

- (id)initTextCell:(NSString *)aString
{
	[super initTextCell:aString];
	piImage = nil;
	cleanedUp = NO;
	job = nil;
	isIndeterminate = YES;
	minValue = 0.0;
	maxValue = 1.0;
	doubleValue = 0.0;
	indeterminateImageNo = 0;
	return self;
}

- (void)dealloc
{
	if (piImage) {
		cleanedUp = YES;
		piImage = nil;
	}
	if (job) {
		[job release];
	}
	[super dealloc];
}

- (id)piImage
{
	NSImage		*anImage;
	NSSize		aSize;
	NSString	*imageName;
	
	if (!cleanedUp) {
		if (isIndeterminate) {
			if (job && [job isJobRunning]) {
				imageName = [NSString stringWithFormat:@"loadanimation_%d",indeterminateImageNo];
			} else {
				imageName = [NSString stringWithString:@"loadanimation_0"];
			}
			anImage = [NSImage imageNamed:imageName];
			[anImage setScalesWhenResized:YES];
			aSize = [anImage size];
			aSize.height = 32;
			[anImage setSize:aSize];
			if (job && [job isJobRunning]) {
				indeterminateImageNo++;
				if (indeterminateImageNo > MAC_MAX_IMAGE_NO) {
					indeterminateImageNo = 0;
				}
			}
			return anImage;
		} else {
			if (!piImage) {
				piImage = [NSImage imageNamed:@"load_posting"];
				[piImage setScalesWhenResized:YES];
				aSize = [piImage size];
				aSize.height = 32;
				[piImage setSize:aSize];
			}
			return piImage;
		}
	} else {
		return nil;
	}
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{	
	NSRect	srcRect;
	NSSize	imageSize;
	NSPoint iOrigin;
	NSImage	*theImage;

	[super drawInteriorWithFrame:cellFrame inView:controlView];
	
	theImage = [self piImage];
	imageSize.width = 32;
	if (theImage) {
		srcRect.origin.x = srcRect.origin.y = 0.0;
		imageSize = [theImage size];
		if (isIndeterminate) {
			srcRect.size = imageSize;
		} else {
			srcRect.size.width = imageSize.width;
			srcRect.size.height = (imageSize.height / (maxValue - minValue)) * (doubleValue - minValue);
		}
		
		iOrigin.y = cellFrame.origin.y + imageSize.height;
		iOrigin.x = 2; // cellFrame.origin.x + cellFrame.size.width - imageSize.width;
		if (job && [job isJobRunning]) {
			[theImage compositeToPoint:iOrigin fromRect:srcRect operation:NSCompositeSourceOver];
		} else {
			srcRect.size = imageSize;
			[theImage dissolveToPoint:iOrigin fromRect:srcRect fraction:0.5];
		}
	}
	if (job) {
		NSMutableAttributedString 	*aString;
		NSMutableDictionary			*attributes = [NSMutableDictionary dictionary];
		NSPoint						drawPoint = cellFrame.origin;
		NSFont						*aFont;
		
		aFont = [[NSFontManager sharedFontManager] convertFont:[NSFont systemFontOfSize:11.0] toHaveTrait:NSCompressedFontMask];
		[attributes setObject:aFont forKey:NSFontAttributeName];
		aString = [[NSMutableAttributedString alloc] initWithString:[job jobname] attributes:attributes];
		[[NSColor blackColor] set];
		drawPoint.x = iOrigin.x + imageSize.width + 6;
		[aString drawAtPoint:drawPoint];
		[aString release];
		
		[attributes setObject:[NSFont systemFontOfSize:10.0] forKey:NSFontAttributeName];
		[attributes setObject:[NSColor darkGrayColor] forKey:NSForegroundColorAttributeName];
		if (job) {
			NSString	*subsName = [[[job subscriptionMgr] theSubscription] subscriptionName];
			aString = [[NSMutableAttributedString alloc] 
						initWithString:((subsName)? subsName:NSLocalizedString(@"Untitled", @""))
						attributes:attributes];
			drawPoint.y += 15;
			[aString drawAtPoint:drawPoint];
			[aString release];
		}
	}
}

- (void)setMinValue:(double)aValue
{
	minValue = aValue;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (double)minValue
{
	return minValue;
}

- (void)setMaxValue:(double)aValue
{
	maxValue = aValue;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (double)maxValue
{
	return maxValue;
}

- (void)animate:sender
{
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (void)incrementBy:(double)delta
{
	doubleValue += delta;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (void)setIndeterminate:(BOOL)flag
{
	isIndeterminate = flag;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}


- (void)setDoubleValue:(double)value
{
	doubleValue = value;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (void)cleanUp
{
	cleanedUp = YES;
	piImage = nil;
	if (job) {
		[job release];
	}
	job = nil;
	[[self controlView] setNeedsDisplay:YES];
//	[[[self controlView] window] flushWindow];
}

- (void)setJob:(ISOJob *)aJob
{
	job = aJob;
	[job retain];
}

- (ISOJob *)job
{
	return job;
}
@end
