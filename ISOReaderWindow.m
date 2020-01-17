//
//  ISOReaderWindow.m
//  Halime
//
//  Created by Imdat Solak on Fri Jan 25 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOReaderWindow.h"


@implementation ISOReaderWindow

- (BOOL)tryKeyDown:(NSEvent *)theEvent
{
	NSString	*chars = [theEvent characters];
	NSString	*uchars = [theEvent charactersIgnoringModifiers];
	int			modifiers = [theEvent modifierFlags];
	NSString	*rightArrow = [NSString stringWithCharacters:(unichar *)"\xf7\x03" length:1];
	NSString	*leftArrow = [NSString stringWithCharacters:(unichar *)"\xf7\x02" length:1];
	
	lastKey = IR_LASTKEYNONE;
	if (modifiers & NSAlternateKeyMask) {
		if (([uchars hasPrefix:@"+"] || [uchars hasPrefix:@"y"] || [uchars hasPrefix:@"x"] || [uchars hasPrefix:@"c"])) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:modPlusKeyPressed:)]) {
				[[self delegate] window:self modPlusKeyPressed:theEvent];
				return YES;
			}
		} else if (([uchars hasPrefix:@"-"] || [uchars hasPrefix:@"q"] || [uchars hasPrefix:@"w"] || [uchars hasPrefix:@"e"])) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:modMinusKeyPressed:)]) {
				[[self delegate] window:self modMinusKeyPressed:theEvent];
				return YES;
			}
		}
	} else if (modifiers & NSControlKeyMask) {
		if ([uchars hasPrefix:@" "]) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:controlSpacePressed:)]) {
				[[self delegate] window:self controlSpacePressed:theEvent];
				return YES;
			}
		}
	} else if (modifiers & NSCommandKeyMask) {
		if ([uchars hasPrefix:@"\x7f"]) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:commandBackspacePressed:)]) {
				[[self delegate] window:self commandBackspacePressed:theEvent];
				return YES;
			}
		}
	} else if ([chars hasPrefix:rightArrow]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:rightArrowPressed:)]) {
			[[self delegate] window:self rightArrowPressed:theEvent];
			return YES;
		}
	} else if ([chars hasPrefix:leftArrow]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:leftArrowPressed:)]) {
			[[self delegate] window:self leftArrowPressed:theEvent];
			return YES;
		}
	} else if ([chars hasPrefix:@" "]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:spaceBarPressed:)]) {
			[[self delegate] window:self spaceBarPressed:theEvent];
			return YES;
		}
	} else if ([chars hasPrefix:@"+"] || [chars hasPrefix:@"y"] || [chars hasPrefix:@"x"] || [chars hasPrefix:@"c"]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:plusKeyPressed:)]) {
			[[self delegate] window:self plusKeyPressed:theEvent];
			return YES;
		}
	} else if ([chars hasPrefix:@"-"] || [chars hasPrefix:@"q"] || [chars hasPrefix:@"w"] || [chars hasPrefix:@"e"]) {
		if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:minusKeyPressed:)]) {
			[[self delegate] window:self minusKeyPressed:theEvent];
			return YES;
		}
	} else if (registeredChars) {
		NSRange aRange = [chars rangeOfCharacterFromSet:registeredChars];
		if (aRange.length == 1) {
			if ([self delegate] && [[self delegate] respondsToSelector:@selector(window:otherKeyPressed:)]) {
				NSString	*theKey = [chars substringWithRange:aRange];
				[[self delegate] window:self otherKeyPressed:theKey];
				return YES;
			}
		}
	}
	return NO;
}

- (void)keyDown:(NSEvent *)theEvent
{
	if (![self tryKeyDown:theEvent]) {
		[super keyDown:theEvent];
	}
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

- (NSCharacterSet *)registeredChars
{
	return registeredChars;
}

@end
