//
//  ISOGraphicalTV.m
//  Halime
//
//  Created by Imdat Solak on Thu Jan 31 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOGraphicalTV.h"
#import "ISONewsPosting.h"
#import "ISOLogger.h"

@implementation ISOGraphicalTV
- (id)initWithFrame:(NSRect )frameRect
{
	delegate = nil;
	displaySize = GTV_IS_32;
	detailedTooltip = NO;
	return [super initWithFrame:frameRect];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)drawRect:(NSRect )aRect
{
	float	lastX;
	
	[super drawRect:aRect];
	if (thread) {
		int			i, count;
		NSPoint		point;
		NSRect		lineRect;
		
		point.x = 5;
		point.y = 25;
		count = [thread count];
		for (i=0;i<count;i++) {
			point = [[thread objectAtIndex:i] drawThreadAtPoint:point level:0 vertLevel:0 putLastXInto:&lastX calculateOnly:NO inView:self shouldRect:aRect intersect:YES];
			point.x = 5;
		}

		lineRect.origin.x = 5;
		lineRect.origin.y = 25;
		lineRect.size.width = 4;
		lineRect.size.height = point.y - 10;
	}
}

- (void)recalculate
{
	int			i, count;
	NSPoint		point;
	NSSize	newSize;
	float	lastX;
	NSRect	selfFrame;
	
	[self removeAllToolTips];
	if (thread) {
		[self lockFocus];
		point.x = 5;
		point.y = 50;
		count = [thread count];
		for (i=0;i<count;i++) {
			[[thread objectAtIndex:i] setGTVImageSize:displaySize];
			[[thread objectAtIndex:i] setDetailedTooltip:detailedTooltip];
			point = [[thread objectAtIndex:i] drawThreadAtPoint:point level:0 vertLevel:0 putLastXInto:&lastX calculateOnly:YES inView:self shouldRect:NSMakeRect(0,0,0,0) intersect:NO];
			point.x = 5;
		}
		newSize.width = lastX;
		newSize.height = point.y + 50;
		selfFrame = [self frame];
		if ((newSize.width > selfFrame.size.width+10) ||
			(newSize.width < selfFrame.size.width-10) ||
			(newSize.height > selfFrame.size.height+10) ||
			(newSize.height < selfFrame.size.height-10)) {
			selfFrame.size = newSize;
			[self setFrame:selfFrame];
			[self setNeedsDisplay:YES];
		}
		[self unlockFocus];
	}
	[self setNeedsDisplay:YES];
	[self displayIfNeeded];
}

- (void)setThread:(NSArray *)aThread
{
	BOOL changed = NO;
	
	if ((aThread && !thread) ||
		(!aThread && thread) ||
		([aThread count] && ![thread count]) ||
		(![aThread count] && [thread count]) ||
		([aThread objectAtIndex:0] != [thread objectAtIndex:0]) ) {
		changed = YES;
	}
	if (thread) {
		[thread release];
		thread = nil;
	}
	if (changed) {
		[self display];
	}
	thread = aThread;
	[thread retain];
	if (changed) {
		[self recalculate];
	}
}

- (void)changeImageSizeTo:(int)size
{
	int	i, count;
	
	displaySize = size;
	if (thread) {
		id	oldThread = thread;
		thread = nil;
		[self display];
		thread = oldThread;
		
		count = [thread count];
		for (i=0;i<count;i++) {
			[[thread objectAtIndex:i] setGTVImageSize:size];
		}
		[self recalculate];
	}
}

- (void)setDetailedTooltip:(BOOL)flag
{
	int	i, count;
	detailedTooltip = flag;
	if (thread) {
		count = [thread count];
		for (i=0;i<count;i++) {
			[[thread objectAtIndex:i] setDetailedTooltip:detailedTooltip];
		}
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	BOOL	found = NO;
	int		i, count;
	id		foundItem = nil;
	if (thread) {
		NSPoint	location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		count = [thread count];
		i = 0;
		while (i<count && !found) {
			foundItem = [((ISONewsPosting *)[thread objectAtIndex:i]) hitTest:location];
			if (foundItem) {
				found = YES;
			}
			i++;
		}
		if (([theEvent clickCount] == 2) && found && delegate && [delegate respondsToSelector:@selector(graphicalTV:itemDoubleClicked:)]) {
			[delegate graphicalTV:self itemDoubleClicked:foundItem];
		} else if (([theEvent type] == NSRightMouseDown) && found && delegate && [delegate respondsToSelector:@selector(graphicalTV:itemRightClicked:)]) {
			[delegate graphicalTV:self itemRightClicked:foundItem];
		} else if (found && delegate && [delegate respondsToSelector:@selector(graphicalTV:itemSelected:)]) {
			[delegate graphicalTV:self itemSelected:foundItem];
		} else {
			[super mouseDown:theEvent];
		}
	} else {
		[super mouseDown:theEvent];
	}
}

- (void)setDelegate:(id)anObject
{
	delegate = anObject;
}

- (void)redisplayPosting:(id)aPosting
{
	[self lockFocus];
	[aPosting redisplayWithOldFrame];
	[self unlockFocus];
	[self setNeedsDisplayInRect:[aPosting gtvFrameRect]];
	[self displayIfNeeded];
}

@end
