//
//  ISODragImageView.h
//  Halime
//
//  Created by Imdat Solak on Sun Jan 20 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ISODragImageView : NSImageView
{
	NSString	*imageFilename;
	id			doubleTarget;
	SEL			doubleAction;
}

//- (BOOL)dragFile:(NSString *)fullPath fromRect:(NSRect)aRect slideBack:(BOOL)slideBack event:(NSEvent *)theEvent;
- (void)setDoubleTarget:(id)anObject;
- (void)setDoubleAction:(SEL)anAction;
- (void)mouseDown:(NSEvent *)theEvent;
- (void)setImageFilename:(NSString *)aString;
- (void)draggedImage:(NSImage *)anImage beganAt:(NSPoint)aPoint;
- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation;
- (void)draggedImage:(NSImage *)draggedImage movedTo:(NSPoint)screenPoint;
- (unsigned int)draggingSourceOperationMaskForLocal:(BOOL)flag;
- (BOOL)ignoreModifierKeysWhileDragging;
@end
