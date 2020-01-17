//
//  ISOReaderPanel.m
//  Halime
//
//  Created by Imdat Solak on Sun Feb 17 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOReaderPanel.h"

#define IR_LASTKEYWASUP		1
#define IR_LASTKEYWASDOWN	2
#define IR_LASTKEYWASLEFT	3
#define IR_LASTKEYWASRIGHT	4
#define IR_LASTKEYNONE		-1


@implementation ISOReaderPanel

- (void)keyDown:(NSEvent *)theEvent
{
	NSString	*chars = [theEvent characters];
	NSString	*uchars = [theEvent charactersIgnoringModifiers];
	int			modifiers = [theEvent modifierFlags];

	lastKey = IR_LASTKEYNONE;
	if (modifiers & NSAlternateKeyMask) {
		if (([uchars hasPrefix:@"+"] || [uchars hasPrefix:@"y"] || [uchars hasPrefix:@"x"] || [uchars hasPrefix:@"c"])) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:modPlusKeyPressed:)]) {
				[[self delegate] window:self modPlusKeyPressed:theEvent];
				return;
			}
		} else if (([uchars hasPrefix:@"-"] || [uchars hasPrefix:@"q"] || [uchars hasPrefix:@"w"] || [uchars hasPrefix:@"e"])) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:modMinusKeyPressed:)]) {
				[[self delegate] window:self modMinusKeyPressed:theEvent];
				return;
			}
		}
	} else if ([chars hasPrefix:@" "]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:spaceBarPressed:)]) {
			[[self delegate] window:self spaceBarPressed:theEvent];
			return;
		}
	} else if ([chars hasPrefix:@" "]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:spaceBarPressed:)]) {
			[[self delegate] window:self spaceBarPressed:theEvent];
			return;
		}
	} else if ([chars hasPrefix:@"+"] || [chars hasPrefix:@"y"] || [chars hasPrefix:@"x"] || [chars hasPrefix:@"c"]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:plusKeyPressed:)]) {
			[[self delegate] window:self plusKeyPressed:theEvent];
			return;
		}
	} else if ([chars hasPrefix:@"-"] || [chars hasPrefix:@"q"] || [chars hasPrefix:@"w"] || [chars hasPrefix:@"e"]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:minusKeyPressed:)]) {
			[[self delegate] window:self minusKeyPressed:theEvent];
			return;
		}
	} else if (registeredChars) {
		NSRange aRange = [chars rangeOfCharacterFromSet:registeredChars];
		if (aRange.length == 1) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:otherKeyPressed:)]) {
				NSString	*theKey = [chars substringWithRange:aRange];
				[[self delegate] window:self otherKeyPressed:theKey];
				return;
			}
		}
	}
	[super keyDown:theEvent];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	lastKey = IR_LASTKEYNONE;
	[super mouseDown:theEvent];
}

- (int)lastKey
{
	return lastKey;
}

- (void)registerCharacterSetAsKeys:(NSCharacterSet *)aSet
{
	registeredChars = aSet;
}


@end
