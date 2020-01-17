//
//  ISONewsBody.m
//  Halime
//
//  Created by iso on Mon May 21 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISONewsBody.h"
#import "ISOLogger.h"

#define K_EMPTYBODYSTRING @"@@##@@##SOLAKIMDAT##@@##@@"


@implementation ISONewsBody
- init
{
	[super init];
	body = nil;
	return self;
}

- initFromString:(NSString *)aString
{
	self = [self init];
	if ([self readFromString:aString]) {
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{
	[body release];
	body = nil;
	[super dealloc];
}


- (BOOL)readFromString:(NSString *)aString
{
	NSRange aRange;
	NSRange	rnRange;
	
	rnRange = [aString rangeOfString:@"\r\n\r\n"];
	aRange = rnRange;
	if (rnRange.location == NSNotFound) {
		return NO;
	}
	aRange.location += aRange.length;
	body = [aString substringFromIndex:aRange.location];
	aRange = [body rangeOfString:K_EMPTYBODYSTRING];
	if (!body || ([body length] == 0) || (aRange.length == [K_EMPTYBODYSTRING length])) {
		[body release];
		body = nil;
		return NO;
	} else {
		[body retain];
		return YES;
	}
}

- (BOOL)writeToString:(NSMutableString *)aString
{
	if (body) {
		if ([body length] == 0) {
			[aString appendString:K_EMPTYBODYSTRING];
		} else {
			[aString appendString:body];
		}
		return YES;
	} else {
		return NO;
	}
}

- (NSString *)body
{
	return body;
}

- (int)hasAttachments
{
	NSRange			aRange;
	NSScanner		*scanner;
	NSMutableString	*command;
	int				umask;
	NSMutableString	*filename;
	NSString		*blankString = @" ";
	BOOL			found = NO;

	aRange = [body rangeOfString:@"\nbegin "];
	if (aRange.length == 0) {
		aRange = [body rangeOfString:@"begin "];
		if ((aRange.length >0) && (aRange.location == 0)) {
			found = YES;
		}
	} else {
		aRange.location++;
		aRange.length--;
		found = YES;
	}
	if (found) {
		scanner = [NSScanner scannerWithString:[body substringFromIndex:aRange.location]];
		if ([scanner scanUpToString:blankString intoString:&command] &&
			[scanner scanInt:&umask] &&
			[scanner scanUpToString:blankString intoString:&filename]) {
			if (command && filename && (umask > 0) && (umask <= 9999)) {
				return 1;
			} else {
				return -1;
			}
		}
	}
	return 0;
}
@end
