//
//  ISONewsHeader.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISONewsHeader.h"
#import "ISOLogger.h"
#import "Functions.h"

#define MAX_HEADER_LENGTH 70

@implementation ISONewsHeader
- init
{
	[super init];
	headers = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
	rawHeader = nil;
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

- initFromDictionary:(NSDictionary *)aDictionary
{
	if (aDictionary) {
		if (headers) {
			[headers dealloc];
		}
		headers = [NSMutableDictionary dictionaryWithDictionary:aDictionary];
		[headers retain];
		if (![headers objectForKey:@"X-Halime-Read:"]) {
			[headers setObject:@"NO" forKey:@"X-Halime-Read:"];
		}
		if (![headers objectForKey:@"X-Halime-Invalid:"]) {
			[headers setObject:@"NO" forKey:@"X-Halime-Invalid:"];
		}
		if (![headers objectForKey:@"X-Halime-CompDate:"]) {
			[self createComparableDate];
		}
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{
    [headers release];
	headers = nil;
	[rawHeader release];
	[super dealloc];
}

- (int)headerCount
{
	return [headers count];
}

- (NSString *)rawHeader
{
	if (!rawHeader) {
		NSMutableString	*aString = [NSMutableString string];
		NSEnumerator	*enumerator = [headers keyEnumerator];
		id				key;
		id				anObject;
		
		while ((key = [enumerator nextObject])) {
			anObject = [headers objectForKey:key];
			if (anObject) {
				[aString appendString:key];
				[aString appendString:@" "];
				[aString appendString:anObject];
				[aString appendString:@"\r\n"];
			}
		}
		rawHeader = [NSString stringWithString:aString];
		[rawHeader retain];
	}
	return rawHeader;
}

- (NSDictionary *)fullHeader
{
	return (NSDictionary *)headers;
}

- (NSString *)headerForKey:(NSString *)headerKey
{
	if (headers) {
		return [headers objectForKey:headerKey];
	} else {
		return @"";
	}
}

- (NSString *)fromHeader
{
	return [self headerForKey:@"From:"];
}

- (NSString *)newsgroupsHeader
{
	return [self headerForKey:@"Newsgroups:"];
}

- (NSString *)dateHeader
{
	return [self headerForKey:@"Date:"];
}

- (NSString *)subjectHeader
{
	return [self headerForKey:@"Subject:"];
}

- (NSString *)linesHeader
{
	return [self headerForKey:@"Lines:"];
}

- (NSString *)messageIDHeader
{
	return [self headerForKey:@"Message-ID:"];
}

- (NSString *)organizationHeader
{
	return [self headerForKey:@"Organization:"];
}

- (NSString *)contentTypeHeader
{
	return [self headerForKey:@"Content-Type:"];
}

- (NSString *)contentTransferEncodingHeader
{
	return [self headerForKey:@"Content-Transfer-Encoding:"];
}

- (NSString *)referencesHeader
{
	return [self headerForKey:@"References:"];
}

- (NSString *)followUpHeader
{
	return [self headerForKey:@"Followup-To:"];
}

- (NSString *)replyToHeader
{
	return [self headerForKey:@"Reply-To:"];
}

- (NSString *)xFaceHeader
{
	return [self headerForKey:@"X-Face:"];
}

- (NSString *)xFaceURLHeader
{
	return [self headerForKey:@"X-FaceURL:"];
}

- (NSString *)bytesHeader
{
	return [self headerForKey:@"Bytes:"];
}


- (BOOL)isPostingRead
{
	return ([[self headerForKey:@"X-Halime-Read:"] compare:@"YES"] == NSOrderedSame);
}

- setPostingRead:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Read:"];
	return self;
}

- (BOOL)isPostingInvalid
{
	return ([[self headerForKey:@"X-Halime-Invalid:"] compare:@"YES"] == NSOrderedSame);
}

- setPostingInvalid:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Invalid:"];
	return self;
}

- (void)setPostingPath:(NSString *)aPath
{
	[headers setObject:aPath forKey:@"X-Halime-Postingpath:"];
}

- (NSString *)postingPath
{
	return [self headerForKey:@"X-Halime-Postingpath:"];
}

- (void)setMainGroupName:(NSString *)groupName
{
	[headers setObject:groupName forKey:@"X-Halime-Maingroup:"];
}

- (NSString *)mainGroupName
{
	return [self headerForKey:@"X-Halime-Maingroup:"];
}

- (int)articleServerID
{
	return [[self headerForKey:@"X-Halime-ArticleServerID:"] intValue];
}

- (void)setArticleServerID:(int)anID
{
	[headers setObject:[NSString stringWithFormat:@"%d", anID] forKey:@"X-Halime-ArticleServerID:"];
}

- (int)hasAttachments
{
	NSString	*aHeader;
	NSRange		aRange;
	
	aHeader = [self contentTypeHeader];
	if (aHeader) {
		aHeader = [aHeader lowercaseString];
		aRange = [aHeader rangeOfString:@"multipart"];
		if (aRange.length >0) {
			return K_HASATTACHMENTS;
		}
	}
	aHeader = [self linesHeader];
	if ([aHeader intValue] > K_MAYBEATTACHMENT_LINE_LIMIT) {
		return K_MAYBEHASATTACHMENTS;
	} else {
		return K_HASNOATTACHMENTS;
	}
}

- (void)extractHeaders:(NSString *)headerString
{
	NSArray			*headerList;
	int				i, count;
	NSString		*oneHeader;
	NSString		*keyString = nil;
	NSString		*valueString;
	NSRange			aRange;
	
	headerList = [headerString componentsSeparatedByString:@"\n"];
	if (headerList) {
		count = [headerList count];
		for (i=0;i<count;i++) {
			oneHeader = [headerList objectAtIndex:i];
			if (![oneHeader hasPrefix:@" "] && ![oneHeader hasPrefix:@"\t"]) {
				aRange = [oneHeader rangeOfString:@":"];
				if ((aRange.location >= 0) && (aRange.length == 1)) {
					keyString = [oneHeader substringToIndex:aRange.location+1];
					if ([oneHeader length] > [keyString length]) {
						valueString = [oneHeader substringFromIndex:aRange.location+2];
						aRange = [valueString rangeOfString:@"\r"];
						if (aRange.length == 1) {
							valueString = [valueString substringToIndex:aRange.location];
						}
						aRange = [valueString rangeOfString:@"\n"];
						if (aRange.length == 1) {
							valueString = [valueString substringToIndex:aRange.location];
						}
					} else {
						valueString = nil;
					}
					if (valueString && keyString) {
						[headers setObject:valueString forKey:keyString];
					}
				}
			} else if (keyString) {
				NSCharacterSet	*aSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
				NSRange			beginRange;
				
				beginRange = [oneHeader rangeOfCharacterFromSet:aSet];
				if (beginRange.length == 1) {
					NSMutableString	*theVal = [NSMutableString stringWithString:[headers objectForKey:keyString]];
					NS_DURING
						[theVal appendString:[oneHeader substringFromIndex:beginRange.location]];
						aRange = [theVal rangeOfString:@"\r"];
						if (aRange.length == 1) {
							theVal = [NSMutableString stringWithString:[theVal substringToIndex:aRange.location]];
						}
						aRange = [theVal rangeOfString:@"\n"];
						if (aRange.length == 1) {
							theVal = [NSMutableString stringWithString:[theVal substringToIndex:aRange.location]];
						}
					NS_HANDLER
						theVal = [NSMutableString stringWithString:NSLocalizedString(@"<UNSUPPORTED HEADER ENCODING>",@"")];
						NSLog(@"Exceptio TWO in extractHeaders:");
					NS_ENDHANDLER
					if (theVal && keyString) {
						[headers setObject:theVal forKey:keyString];
					}
				}
			}
		}
		aRange = [[headers objectForKey:@"Content-Type:"] rangeOfString:@"charset="];
		if (aRange.length != 8) {
			aRange = [headerString rangeOfString:@"charset="];
			if (aRange.length == 8) {
				NSString *aString = [headerString substringFromIndex:aRange.location+aRange.length];
				NSMutableString	*head;
				aRange = [aString rangeOfString:@"\r"];
				if (aRange.length == 1) {
					aString = [aString substringToIndex:aRange.location];
				} else {
					aRange = [aString rangeOfString:@"\n"];
					if (aRange.length == 1) {
						aString = [aString substringToIndex:aRange.location];
					}
				}
				if ([headers objectForKey:@"Content-Type:"]) {
					head = [NSMutableString stringWithString:[headers objectForKey:@"Content-Type:"]];
				} else {
					head = [NSMutableString stringWithString:@"Content-Type: text/plain;"];
				}
				[head appendFormat:@" charset=%@", aString];
				[headers setObject:head forKey:@"Content-Type:"];
			}
		}
	}
}

- (BOOL)readFromString:(NSString *)aString
{
	NSRange aRange;
	NSRange	rnRange;
	
	rnRange = [aString rangeOfString:@"\r\n\r\n"];
	if (rnRange.location == NSNotFound) {
		return NO;
	}
	aRange = rnRange;
	aRange.length = aRange.location;
	aRange.location = 0;

	rawHeader = [[aString substringWithRange:aRange] retain];
	aRange = [rawHeader rangeOfString:@"X-Halime-Read:"];
	if (aRange.length == 0) {
		[headers setObject:@"NO" forKey:@"X-Halime-Read:"];
	}
	aRange = [rawHeader rangeOfString:@"X-Halime-Invalid:"];
	if (aRange.length == 0) {
		[headers setObject:@"NO" forKey:@"X-Halime-Invalid:"];
	}
	[self extractHeaders:rawHeader];
	aRange = [rawHeader rangeOfString:@"X-Halime-CompDate:"];
	if (aRange.length == 0) {
		[self createComparableDate];
	}

	return YES;
}

- (BOOL)writeToString:(NSMutableString *)aString
{
	if (rawHeader) {
		NSEnumerator	*enumerator = [headers keyEnumerator];
		id				key;
		id				anObject;
	
		while ((key = [enumerator nextObject])) {
			anObject = [headers objectForKey:key];
			if (anObject) {
				[aString appendString:key];
				[aString appendString:@" "];
				[aString appendString:anObject];
				[aString appendString:@"\r\n"];
			}
		}
		[aString appendString:@"\r\n"];
		return YES;
	} else {
		return NO;
	}
}

- (id)setIsOnHold:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-OnHold:"];
	return self;
}

- (BOOL)isOnHold
{
	return ([self headerForKey:@"X-Halime-OnHold:"] && ([[self headerForKey:@"X-Halime-OnHold:"] compare:@"YES"] == NSOrderedSame));
}

- setServerName:(NSString *)serverName
{
	[headers setObject:serverName forKey:@"X-Halime-Servername:"];
	return self;
}

- (NSString *)serverName
{
	return [self headerForKey:@"X-Halime-Servername:"];
}

- (void)setIsForwarded:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Forwarded:"];
}

- (void)setIsReplied:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Replied:"];
}

- (void)setIsFollowedUp:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-FollowedUp:"];
}

- (BOOL)isForwarded
{
	return ([self headerForKey:@"X-Halime-Forwarded:"] && ([[self headerForKey:@"X-Halime-Forwarded:"] compare:@"YES"] == NSOrderedSame));
}

- (BOOL)isReplied
{
	return ([self headerForKey:@"X-Halime-Replied:"] && ([[self headerForKey:@"X-Halime-Replied:"] compare:@"YES"] == NSOrderedSame));
}

- (BOOL)isFollowedUp
{
	return ([self headerForKey:@"X-Halime-FollowedUp:"] && ([[self headerForKey:@"X-Halime-FollowedUp:"] compare:@"YES"] == NSOrderedSame));
}

- (void)createComparableDate
{
	NSString	*cDate = ISOCreateComparableDateFromDateHeader([self dateHeader]);
	if (cDate) {
		[headers setObject:ISOCreateComparableDateFromDateHeader([self dateHeader]) forKey:@"X-Halime-CompDate:"];
	}
}

- (NSString *)comparableDate
{
	if ([self headerForKey:@"X-Halime-CompDate:"]) {
		return [self headerForKey:@"X-Halime-CompDate:"];
	} else {
		return @"20000101010101";
	}
}

- (NSString *)_multiLineHeaderFromHeader:(NSString *)value
{
	NSMutableString	*theHeader = [NSMutableString string];
	if ([value length] <= MAX_HEADER_LENGTH) {
		[theHeader appendString:value];
	} else {
		NSMutableString *aString = [NSMutableString string];
		NSArray			*stringComponents = [value componentsSeparatedByString:@" "];
		int				i, count;
		if (stringComponents && [stringComponents count]) {
			count = [stringComponents count];
			[aString setString:@""];
			i = 0;
			while (i<count) {
				NSString *oneString = [stringComponents objectAtIndex:i];
				if (i>0 && ([aString length] == 0)) { // it is NOT the first line we are appending as the value of the header
					[aString setString:@"\r\n\t"];
				}
				if (([aString length] + [oneString length] <= MAX_HEADER_LENGTH) || ([aString length] <= 3)) {
					[aString appendString:oneString];
					[aString appendString:@" "];
					i++;
				} else {
					[theHeader appendString:aString];
					[aString setString:@""];
				}
			}
			if ([aString length]>3) {
				[theHeader appendString:aString];
			}
		} else {
			[theHeader appendString:value];
		}
	}
	return theHeader;
}

- (NSString *)transferableHeader
{
	NSMutableString	*transferableHeaders;
	NSEnumerator	*enumerator = [headers keyEnumerator];
	id 				key;
	
	transferableHeaders = [NSMutableString string];
	while ((key = [enumerator nextObject])) {
		if (![key hasPrefix:@"X-Halime"]) {
			NSString		*oneHeader = [headers objectForKey:key];
			NSMutableString	*xFStr = [NSMutableString string];
			
			if (oneHeader && [oneHeader length]) {
				if ([((NSString *)key) compare:@"X-Face:"] == NSOrderedSame) {
					int	startPos = 0;
					int length = MAX_HEADER_LENGTH;
					
					length = MIN(MAX_HEADER_LENGTH, [oneHeader length]);
					while (startPos < [oneHeader length]) {
						NSString	*aStr = [oneHeader substringWithRange:NSMakeRange(startPos, length)];
						if (aStr) {
							if ([xFStr length]) {
								[xFStr appendString:@"\r\n\t"];
							}
							[xFStr appendString:aStr];
						}
						startPos += length;
						length = MIN(MAX_HEADER_LENGTH, [oneHeader length] - startPos);
					}
				} else {
					[xFStr setString:[self _multiLineHeaderFromHeader:oneHeader]];
//					[xFStr setString:oneHeader];
				}
			}
			if ([xFStr length]) {
				[transferableHeaders appendFormat:@"%@ %@\r\n", key, xFStr];
			}
		}
	}
	return transferableHeaders;
}


- (BOOL)isLocked
{
	return ([self headerForKey:@"X-Halime-Locked:"] && ([[self headerForKey:@"X-Halime-Locked:"] compare:@"YES"] == NSOrderedSame));
}

- (void)setIsLocked:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Locked:"];
}

- (BOOL)isFlagged
{
	return ([self headerForKey:@"X-Halime-Flagged:"] && ([[self headerForKey:@"X-Halime-Flagged:"] compare:@"YES"] == NSOrderedSame));
}

- (void)setIsFlagged:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-Flagged:"];
}

- (void)setIsInDownloadManager:(BOOL)flag
{
	[headers setObject:(flag)? @"YES":@"NO" forKey:@"X-Halime-InDownloadManager:"];
}

- (BOOL)isInDownloadManager
{
	return ([self headerForKey:@"X-Halime-InDownloadManager:"] && ([[self headerForKey:@"X-Halime-InDownloadManager:"] compare:@"YES"] == NSOrderedSame));
}
@end
