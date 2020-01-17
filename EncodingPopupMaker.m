/*
 *  EncodingPopupMaker.c
 *  Halime
 *
 *  Created by Imdat Solak on Sat Feb 16 2002.
 *  Copyright (c) 2001 Imdat Solak. All rights reserved.
 *
 */

#include "EncodingPopupMaker.h"
#import <CoreFoundation/CoreFoundation.h>
#import "ISOPreferences.h"

void MakeEncodingPopup (id aPopupButton, id target, SEL selector, BOOL withNONE)
{
	int				i, count;
	NSArray			*encodingDisplayOrder = [[ISOPreferences sharedInstance] encodingDisplayOrder];
	NSDictionary	*cfstringEncodings = [[ISOPreferences sharedInstance] cfstringEncodings];
	NSString		*key;
	NSString		*title;
	CFStringEncoding	encoding;
	NSString 		*ianaName;
	
	count = [encodingDisplayOrder count];
	for (i=0;i<count;i++) {
		key = [encodingDisplayOrder objectAtIndex:i];
		encoding = [[cfstringEncodings objectForKey:key] intValue];
		if ([key compare:@"NONE/Automatic"] == NSOrderedSame) {
			title = NSLocalizedString(@"NONE/Automatic", @"");
			encoding = MAC_ISOUNKNOWNENCODINGINT;
		} else {
			if (CFStringConvertEncodingToIANACharSetName(encoding)) {
				ianaName = (NSString *)CFStringConvertEncodingToIANACharSetName(encoding);
			} else {
				ianaName = nil; // @"?IANA";
			}
			// title = [NSString stringWithFormat:@"%@ [0x%04X] - (%@)", (NSString *)CFStringGetNameOfEncoding(encoding), encoding, ianaName ];
			if (ianaName) {
				title = [NSString stringWithFormat:@"%@ [%@]", (NSString *)CFStringGetNameOfEncoding(encoding), ianaName ];
			} else {
				title = nil;
			}
		}
		if ((title) && (([key compare:@"NONE/Automatic"] != NSOrderedSame) || withNONE)) {
			[aPopupButton addItemWithTitle:title];
			[[aPopupButton lastItem] setTarget:target];
			[[aPopupButton lastItem] setAction:selector];
			[[aPopupButton lastItem] setTag:encoding];
		}
	}
}
