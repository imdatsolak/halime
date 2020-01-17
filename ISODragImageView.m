//
//  ISODragImageView.m
//  Halime
//
//  Created by Imdat Solak on Sun Jan 20 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISODragImageView.h"


@implementation ISODragImageView

- (void)setDoubleTarget:(id)anObject
{
	doubleTarget = anObject;
}

- (void)setDoubleAction:(SEL)anAction
{
	doubleAction = anAction;
}


- (void)dealloc
{
	if (imageFilename) {
		[imageFilename release];
	}
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL keepOn = YES;
    BOOL isInside = YES;
    NSPoint mouseLoc;
	NSRect thisrect;
	NSPoint	location = [theEvent locationInWindow];

	if (imageFilename) {
		location = [self convertPoint:location fromView:nil]; 
		thisrect = NSMakeRect(location.x-16, location.y-16, 32, 32);
		if ([theEvent clickCount] == 2) {
			if (doubleTarget && [doubleTarget respondsToSelector:doubleAction]) {
				[doubleTarget performSelector:doubleAction withObject:self];
			}
		} else {
			while (keepOn) {
				theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
				mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
				isInside = [self mouse:mouseLoc inRect:[self bounds]];
		
				switch ([theEvent type]) {
					case NSLeftMouseDragged:
							[self dragFile:imageFilename fromRect:thisrect slideBack:YES event:theEvent];
							keepOn = NO;
							break;
					case NSLeftMouseUp:
							keepOn = NO;
							break;
					default:
							break;
				}
		
			}
		}
	} else {
		[super mouseDown:theEvent];
	}

    return;
}

- (void)setImageFilename:(NSString *)aString
{
	if (imageFilename) {
		[imageFilename release];
	}
	imageFilename = [[NSString stringWithString:aString] retain];
}

- (void)draggedImage:(NSImage *)anImage beganAt:(NSPoint)aPoint
{
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation
{
}

- (void)draggedImage:(NSImage *)draggedImage movedTo:(NSPoint)screenPoint
{
}

- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	return NSDragOperationCopy;
}

- (BOOL)ignoreModifierKeysWhileDragging
{
	return YES;
}


@end
