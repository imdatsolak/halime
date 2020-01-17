//
//  ISOGraphicalTV.h
//  Halime
//
//  Created by Imdat Solak on Thu Jan 31 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define GTV_IS_48		48
#define GTV_IS_32		32
#define GTV_IS_16		16


@interface ISOGraphicalTV : NSView
{
	NSArray	*thread;
	id		delegate;
	int		displaySize;
	BOOL	detailedTooltip;
}

- (void)drawRect:(NSRect )aRect;
- (void)setThread:(NSArray *)thread;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)setDelegate:(id)anObject;
- (void)redisplayPosting:(id)aPosting;
- (void)changeImageSizeTo:(int)size;
- (void)setDetailedTooltip:(BOOL)flag;
@end

@interface NSObject(ISOThreadItem)
- (NSPoint)drawThreadAtPoint:(NSPoint)aPoint level:(int)level vertLevel:(int)vertLevel putLastXInto:(float *)lastX calculateOnly:(BOOL)calculateOnly inView:(id)aView;
- (id)hitTest:(NSPoint)aPoint;
- (void)redisplayWithOldFrame;
@end

@interface NSObject(ISOGraphicalTVDelegate)
- (void)graphicalTV:(id)graphicalTV itemSelected:(id)aPosting;
- (void)graphicalTV:(id)graphicalTV itemDoubleClicked:(id)aPosting;
- (void)graphicalTV:(id)graphicalTV itemRightClicked:(id)aPosting;
@end
