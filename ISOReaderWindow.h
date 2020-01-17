//
//  ISOReaderWindow.h
//  Halime
//
//  Created by Imdat Solak on Fri Jan 25 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define IR_LASTKEYWASUP		1
#define IR_LASTKEYWASDOWN	2
#define IR_LASTKEYWASLEFT	3
#define IR_LASTKEYWASRIGHT	4
#define IR_LASTKEYNONE		-1

@interface ISOReaderWindow : NSWindow
{
	int				lastKey;
	NSCharacterSet	*registeredChars;
}


- (BOOL)tryKeyDown:(NSEvent *)theEvent;
- (void)keyDown:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (int)lastKey;
- (void)registerCharacterSetAsKeys:(NSCharacterSet *)aSet;
- (NSCharacterSet *)registeredChars;
@end

@interface NSObject(ISOReaderWindowDelegate)
- (void)window:(id)sender spaceBarPressed:(NSEvent *)theEvent;
- (void)window:(id)sender rightArrowPressed:(NSEvent *)theEvent;
- (void)window:(id)sender leftArrowPressed:(NSEvent *)theEvent;
- (void)window:(id)sender plusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender minusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender modPlusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender modMinusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)sender controlSpacePressed:(NSEvent *)theEvent;
- (void)window:(id)sender commandBackspacePressed:(NSEvent *)theEvent;
- (void)window:(id)sender otherKeyPressed:(NSString *)aKey;
@end
