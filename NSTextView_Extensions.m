//
//  NSTextView_Extensions.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 12 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//  This file uses code from Newsflash developed and copyright by Wolfware
//

#import "NSTextView_Extensions.h"
#import "NSString_Extensions.h"
#import "ISOPreferences.h"

@implementation NSTextView(Extensions)

- (IBAction) rot13: (id)sender
{
    NSRange selectedRange = [self selectedRange];
    [self replaceCharactersInRange: selectedRange
        withString: [[[self string] substringWithRange: selectedRange] rot13String]];
    [self setSelectedRange: selectedRange];
	[self colorizeRange:selectedRange];
}


- (int)makeBoldAtIndex:(int)theIndex withScanner:(NSScanner *)scanner
{
	int				nextIndex;
	NSDictionary	*attributes;
	NSFont			*theFont;
	int				sl, nl, crl;
	
	[scanner scanString:@"*" intoString:nil];

	sl = [scanner scanLocation];
	[scanner scanUpToString:@"*" intoString:nil];
	nextIndex = [scanner scanLocation];

	[scanner setScanLocation:sl];
	[scanner scanUpToString:@"\n" intoString:nil];
	nl = [scanner scanLocation];
	
	[scanner setScanLocation:sl];
	[scanner scanUpToString:@"\r" intoString:nil];

	crl = [scanner scanLocation];

	if ((nl < nextIndex) || (crl < nextIndex)) {
		nextIndex = -1;
	} else {
		if (nextIndex < [[self string] length]) {
			[scanner setScanLocation:nextIndex+1];
			attributes = [[self textStorage] attributesAtIndex:theIndex effectiveRange:nil];
			theFont = [attributes objectForKey:NSFontAttributeName];
			theFont = [[NSFontManager sharedFontManager] convertFont:theFont toHaveTrait:NSBoldFontMask];
			[[self textStorage] addAttribute: NSFontAttributeName 
				value: theFont
				range: NSMakeRange(theIndex, nextIndex-theIndex)];
		} else {
			nextIndex = -1;
		}
	}
	return nextIndex;
}

- (int)makeUnderlineAtIndex:(int)theIndex withScanner:(NSScanner *)scanner
{
	int nextIndex;
	int	sl, nl, crl;
	
	[scanner scanString:@"_" intoString:nil];

	sl = [scanner scanLocation];
	[scanner scanUpToString:@"_" intoString:nil];
	nextIndex = [scanner scanLocation];

	[scanner setScanLocation:sl];
	[scanner scanUpToString:@"\n" intoString:nil];
	nl = [scanner scanLocation];
	
	[scanner setScanLocation:sl];
	[scanner scanUpToString:@"\r" intoString:nil];

	crl = [scanner scanLocation];

	if ((nl < nextIndex) || (crl < nextIndex)) {
		nextIndex = -1;
	} else {
		if (nextIndex < [[self string] length]) {
			[scanner setScanLocation:nextIndex+1];
			[[self textStorage] addAttribute: NSUnderlineStyleAttributeName 
					value: [NSNumber numberWithInt:NSSingleUnderlineStyle]
					range: NSMakeRange(theIndex, nextIndex-theIndex)];
		} else {
			nextIndex = -1;
		}
	}
	return nextIndex;
}

- (void)_searchForCharacter:(NSString *)aString makeUnderline:(BOOL)underline
{
    NSScanner 		*scanner = [[NSScanner alloc] initWithString: [self string]];
	NSString		*bString = [NSString stringWithFormat:@" %@", aString];
	NSString		*rString = [NSString stringWithFormat:@"\n%@", aString];
	NSString		*pString = [NSString stringWithFormat:@".%@", aString];
	NSString		*kString = [NSString stringWithFormat:@",%@", aString];
	NSString		*crString = [NSString stringWithFormat:@"\r%@", aString];
	int				nextIndex;
	int				lastIndex;
	int				sl, ol, tl, pl, kl, rl;
	NSMutableArray	*positions = [NSMutableArray array];
	int				i, count;
	
    while (![scanner isAtEnd]) {
		sl = [scanner scanLocation];
		[scanner scanUpToString:bString intoString:nil];
		ol = [scanner scanLocation];
		[scanner setScanLocation:sl];
		[scanner scanUpToString:rString intoString:nil];
		tl = [scanner scanLocation];
		[scanner setScanLocation:sl];
		[scanner scanUpToString:pString intoString:nil];
		pl = [scanner scanLocation];
		[scanner setScanLocation:sl];
		[scanner scanUpToString:kString intoString:nil];
		kl = [scanner scanLocation];
		[scanner setScanLocation:sl];
		[scanner scanUpToString:crString intoString:nil];
		rl = [scanner scanLocation];
		lastIndex = MIN(ol, tl);
		lastIndex = MIN(lastIndex, pl);
		lastIndex = MIN(lastIndex, kl);
		lastIndex = MIN(lastIndex, rl);
		lastIndex++;
		if (lastIndex < [[self string] length]) {
			[scanner setScanLocation:lastIndex];
			[positions addObject:[NSNumber numberWithInt:lastIndex]];
			if (underline) {
				nextIndex = [self makeUnderlineAtIndex:lastIndex withScanner:scanner];
			} else {
				nextIndex = [self makeBoldAtIndex:lastIndex withScanner:scanner];
			}
			if (nextIndex == -1) {
				break;
			} else {
				[positions addObject:[NSNumber numberWithInt:nextIndex]];
			}
		} else {
			break;
		}
    }
    [scanner release];
	count = [positions count];
	for (i=count-1;i>=0;i--) {
		NSString *aS = [[[self textStorage] attributedSubstringFromRange:NSMakeRange([[positions objectAtIndex:i] intValue], 1)] string];
		if (([aS compare:@"*"] == NSOrderedSame) || ([aS compare:@"_"] == NSOrderedSame)) {
			[[self textStorage] replaceCharactersInRange:NSMakeRange([[positions objectAtIndex:i] intValue], 1) withString:@""];
		}
	}
}

- (NSRange)_addLinkAtRange:(NSRange )foundRange inSearchRange:(NSRange )searchRange inString:(NSString *)string withCharSet:(NSCharacterSet *)endCharSet
{
	NSDictionary	*linkAttributes;
	NSString		*urlString;
	NSRange			endOfURLRange;

	// restrict the searchRange so that it won't find the same string again
	searchRange.location = (foundRange.location+1);
	searchRange.length = [string length] - searchRange.location;
	
	// find the end of the URL
	endOfURLRange = [string rangeOfCharacterFromSet: endCharSet options: 0 range: searchRange];
	if (NSNotFound == endOfURLRange.location)
	{
		endOfURLRange.location = [string length];
	}
	foundRange.length = endOfURLRange.location-foundRange.location;
	
	// create the link
	urlString = [string substringWithRange: foundRange];
	if (urlString && [urlString length]) {
		linkAttributes = [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSURL URLWithString: [urlString percentEscapedString]], NSLinkAttributeName,
			[NSNumber numberWithInt: NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
			[NSColor blueColor], NSForegroundColorAttributeName,
			nil];
		[[self textStorage] addAttributes: linkAttributes range: foundRange];
	}
	return searchRange;

}

- (void)_addLinks
{
	static NSMutableCharacterSet *endCharSet = nil;
	
	NSString *string= [[self textStorage] string];
	NSRange searchRange = NSMakeRange(0, [string length]);
	NSRange httpRange, ftpRange, mailtoRange;
//	NSRange telnetRange, nntpRange, newsRange;
	NSRange	sRange;
	BOOL	urlFound = NO;
	
	if (!endCharSet)
	{
		endCharSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] mutableCopy];
		[endCharSet formUnionWithCharacterSet: [NSCharacterSet characterSetWithCharactersInString: @">"]];
	}
	
//	[[self textStorage] beginEditing];
	urlFound |= (NSNotFound != (httpRange = [string rangeOfString: @"http://" options: 0 range: searchRange]).location);
	urlFound |= (NSNotFound != (ftpRange = [string rangeOfString: @"ftp://" options: 0 range: searchRange]).location);
	urlFound |= (NSNotFound != (mailtoRange = [string rangeOfString: @"mailto://" options: 0 range: searchRange]).location);
//	urlFound |= (9 == (telnetRange = [string rangeOfString: @"telnet://" options: 0 range: searchRange]).length);
//	urlFound |= (7 == (nntpRange = [string rangeOfString: @"nntp://" options: 0 range: searchRange]).length);
//	urlFound |= (7 == (newsRange = [string rangeOfString: @"news://" options: 0 range: searchRange]).length);
	while (urlFound) {
		sRange = searchRange;
		if (httpRange.location != NSNotFound) {
			httpRange = [self _addLinkAtRange:httpRange inSearchRange:searchRange inString:string withCharSet:endCharSet];		
			if (httpRange.location > sRange.location) {
				sRange = httpRange;
			}
		}
		if (ftpRange.location != NSNotFound) {
			ftpRange = [self _addLinkAtRange:ftpRange inSearchRange:searchRange inString:string withCharSet:endCharSet];
			if (ftpRange.location > sRange.location) {
				sRange = ftpRange;
			}
		}
		if (mailtoRange.location != NSNotFound) {
			mailtoRange = [self _addLinkAtRange:mailtoRange inSearchRange:searchRange inString:string withCharSet:endCharSet];
			if (mailtoRange.location > sRange.location) {
				sRange = mailtoRange;
			}
		}
/*
		if (telnetRange.length == 9) {
			telnetRange = [self _addLinkAtRange:telnetRange inSearchRange:searchRange inString:string withCharSet:endCharSet];
			if (telnetRange.location > sRange.location) {
				sRange = telnetRange;
			}
		}
		if (nntpRange.length == 7) {
			nntpRange = [self _addLinkAtRange:nntpRange inSearchRange:searchRange inString:string withCharSet:endCharSet];
			if (nntpRange.location > sRange.location) {
				sRange = nntpRange;
			}
		}
		if (newsRange.length == 7) {
			newsRange = [self _addLinkAtRange:newsRange inSearchRange:searchRange inString:string withCharSet:endCharSet];
			if (newsRange.location > sRange.location) {
				sRange = newsRange;
			}
		}
*/
		searchRange = sRange;
		urlFound = NO;
		urlFound |= (NSNotFound != (httpRange = [string rangeOfString: @"http://" options: 0 range: searchRange]).location);
		urlFound |= (NSNotFound != (ftpRange = [string rangeOfString: @"ftp://" options: 0 range: searchRange]).location);
		urlFound |= (NSNotFound != (mailtoRange = [string rangeOfString: @"mailto://" options: 0 range: searchRange]).location);
//		urlFound |= (9 == (telnetRange = [string rangeOfString: @"telnet://" options: 0 range: searchRange]).length);
//		urlFound |= (7 == (nntpRange = [string rangeOfString: @"nntp://" options: 0 range: searchRange]).length);
//		urlFound |= (7 == (newsRange = [string rangeOfString: @"news://" options: 0 range: searchRange]).length);
	} 
	
//	[[self textStorage] endEditing];

}


- (void)displayUsenetAttributes
{
	[self _searchForCharacter:@"_" makeUnderline:YES];
	[self _searchForCharacter:@"*" makeUnderline:NO];
}


- (void)colorizeRange:(NSRange)aRange
{
    NSScanner *scanner = [[NSScanner alloc] initWithString: [[self string] substringWithRange: aRange]];
	NSColor		*aColor;
	NSArray		*colorDataArray;
	NSCharacterSet	*aSet = [NSCharacterSet characterSetWithCharactersInString:@">]|"];
	
	[self _addLinks];
    [scanner setCharactersToBeSkipped: [NSCharacterSet whitespaceCharacterSet]];
    while (![scanner isAtEnd])
    {
        NSArray *quoteColors = [[ISOPreferences sharedInstance] prefsQuoteColors];
        NSString *quoteMarksString = NULL;
        unsigned quoteLevel = 0, lineStart = [scanner scanLocation];
        while ([scanner scanCharactersFromSet:aSet  intoString: &quoteMarksString]) {
            quoteLevel += [quoteMarksString length];
        }
        [scanner scanUpToString: @"\n" intoString: NULL];
        [scanner scanString: @"\n" intoString: NULL];
		if (quoteLevel > 0) {
			quoteLevel--;
			colorDataArray = [quoteColors objectAtIndex: quoteLevel % [quoteColors count]];
		
			aColor = [NSColor colorWithCalibratedRed:[[colorDataArray objectAtIndex:0] floatValue]
						green:[[colorDataArray objectAtIndex:1] floatValue]
						blue:[[colorDataArray objectAtIndex:2] floatValue]
						alpha:[[colorDataArray objectAtIndex:3] floatValue]];
			[[self textStorage] addAttribute: NSForegroundColorAttributeName 
				value: aColor
				range: NSMakeRange(aRange.location+lineStart, [scanner scanLocation]-lineStart)];
		} else {
			aColor = [NSColor blackColor];
		}
    }
    [scanner release];
}

@end
