#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"
#import "ISOPreferences.h"
#import "compface.h"
#import "Functions.h"
#import "ISOLogger.h"

NSString *ISOCreateComparableDateFromDateHeader(NSString *dateHeader)
{
	NSCalendarDate 	*theDate;
	NSString		*cDate;
	if (dateHeader) {
		theDate = ISOCalendarDateFromString(dateHeader);
		if (theDate) {
			[theDate setTimeZone:[NSTimeZone localTimeZone]];
			cDate = [theDate descriptionWithCalendarFormat:@"%Y%m%d%H%M%S"];
			if (cDate) {
				return cDate;
			} else {
				return @"";
			}
		} else {
			return @"";
		}
	} else {
		return @"";
	}
}

NSCalendarDate *ISOCalendarDateFromString(NSString *aString)
{
	NSCalendarDate 	*theDate = nil;
	
	if (aString) {
		theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%a, %d %b %Y %H:%M:%S %z"];
		if (!theDate) {
			theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%d %b %Y %H:%M:%S %z"];
			if (!theDate) {
				theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%a, %d %b %Y %H:%M:%S %Z"];
				if (!theDate) {
					theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%d %b %Y %H:%M:%S %Z"];
					if (!theDate) {
						theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%A, %d %b %Y %H:%M:%S %z"];
						if (!theDate) {
							theDate = [NSCalendarDate dateWithString:aString calendarFormat:@"%A, %d %b %Y %H:%M:%S %Z"];
						}
					}
				}
			}
		}
	}
	return theDate;
}
/**************/
NSImage *ISOCreateXFaceImageFromString(NSString *xFace)
{
	NSBitmapImageRep	*aRep = nil;
	NSImage				*xFaceImage = nil;
	unsigned char		*buffer;
	int					len;
	int					i;
	unsigned char		c = 0;

	if (xFace && [xFace length]) {
		len = [xFace length];
		buffer = malloc(48*8);
		bzero(buffer, 48*8);
		[xFace getCString:buffer];
		UnCompAll(buffer);
		UnGenFace();
		bzero(buffer, 48*8);
		
		for (i=0;i<PIXELS/8;i++) {
			c = 0;
			c += F[(i*8)+0]? 128:0;
			c += F[(i*8)+1]?  64:0;
			c += F[(i*8)+2]?  32:0;
			c += F[(i*8)+3]?  16:0;
			c += F[(i*8)+4]?   8:0;
			c += F[(i*8)+5]?   4:0;
			c += F[(i*8)+6]?   2:0;
			c += F[(i*8)+7]?   1:0;
			buffer[i] = c;
		}
		aRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&buffer
					pixelsWide:48
					pixelsHigh:48
					bitsPerSample:1 
					samplesPerPixel:1 
					hasAlpha:NO
					isPlanar:NO
					colorSpaceName:NSDeviceBlackColorSpace
					bytesPerRow:0
					bitsPerPixel:1];
		[aRep autorelease];
		xFaceImage = [[NSImage alloc] initWithSize:NSMakeSize(48.0, 48.0)];
		[xFaceImage addRepresentation:aRep];
		[xFaceImage setScalesWhenResized:YES];
//		free(buffer);
	}
	return xFaceImage;
}


NSImage *ISOCreateXFaceURLImageFromString(NSString *xFaceURL)
{
	NSImage	*xFaceImage = nil;

	if (xFaceURL && [xFaceURL length] && (![[ISOPreferences sharedInstance] isOffline]) && [[ISOPreferences sharedInstance] prefsSupportXFaceURL]) {
		NSURL	*aURL = [NSURL URLWithString:xFaceURL];
		NSData	*aData = [NSData dataWithContentsOfURL:aURL];
    
		if (aData) {
			xFaceImage = [[NSImage alloc] initWithData:aData];
			[xFaceImage setScalesWhenResized:YES];
		}
	}
	return xFaceImage;
}


NSString *ISOBitsForCFStringEncoding(CFStringEncoding stringEncoding)
{
	switch (stringEncoding) {
		case kCFStringEncodingASCII:
		case kCFStringEncodingNonLossyASCII:
		case kCFStringEncodingISO_2022_JP:
		case kCFStringEncodingISO_2022_JP_2:
		case kCFStringEncodingISO_2022_CN:
		case kCFStringEncodingISO_2022_CN_EXT:
		case kCFStringEncodingISO_2022_KR:
			return @"7bit";
			break;
		default:
			return @"8bit";
			break;
	}
}


NSString *ISOCreateDisplayableDateFromDateHeader(NSString *originalDate, BOOL relativeDate, BOOL shortDate)
{
	NSCalendarDate 		*theDate;
	NSMutableDictionary	*theLocale = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];

	theDate = ISOCalendarDateFromString(originalDate);
	if (theDate) {
		if (relativeDate) {
			NSRange				aRange;
			NSMutableString		*keyStr;
			NSString			*designation;
			NSCalendarDate		*today = [NSCalendarDate calendarDate];
			int					ceDay = [theDate dayOfCommonEra];
			int					ceToday = [today dayOfCommonEra];
			int 				weDay = [theDate dayOfWeek];
			if (ceToday-6 <= ceDay) { // it was in this week
				if (ceToday -1 == ceDay) { // it was yesterday
					designation = NSLocalizedString(@"Yesterday", @"");
				} else if (ceToday == ceDay) {
					designation = NSLocalizedString(@"Today", @"");
				} else {
					designation = [[theLocale objectForKey:NSWeekDayNameArray] objectAtIndex:weDay];
				}
				keyStr = [NSMutableString stringWithString:[theLocale objectForKey:NSTimeFormatString]];
				aRange = [keyStr rangeOfString:@":%S"];
				if (aRange.length == [@":%S" length]) {
					[keyStr replaceCharactersInRange:aRange withString:@""];
				}
				[theLocale setObject:[theLocale objectForKey:NSShortDateFormatString] forKey:NSDateFormatString];
				[theLocale setObject:keyStr forKey:NSTimeDateFormatString];
				keyStr = [NSMutableString stringWithFormat:@"%@, %@", designation, 
							[theDate descriptionWithCalendarFormat:@"%x" timeZone:[NSTimeZone localTimeZone] locale:theLocale]];
				return keyStr;
			} else {
				shortDate = YES;
			}
		}
		if (shortDate) {
			NSMutableString *str = [NSMutableString stringWithFormat:@"%@ %@", 
										[theLocale objectForKey:NSShortDateFormatString],
										[theLocale objectForKey:NSTimeFormatString]];
			NSRange aRange = [str rangeOfString:@":%S"];
			if (aRange.length == [@":%S" length]) {
				[str replaceCharactersInRange:aRange withString:@""];
			}
			[theLocale setObject:[theLocale objectForKey:NSShortDateFormatString] forKey:NSDateFormatString];
			[theLocale setObject:str forKey:NSTimeDateFormatString];
		} else {
			[theLocale setObject:[theLocale objectForKey:NSShortDateFormatString] forKey:NSDateFormatString];
			[theLocale setObject:[theLocale objectForKey:NSShortTimeDateFormatString] forKey:NSTimeDateFormatString];
		}
		return [theDate descriptionWithCalendarFormat:@"%c" timeZone:[NSTimeZone localTimeZone] locale:theLocale];
	} else {
		return NSLocalizedString(@"Date error", @"");
	}
}

NSString *ISOHumanReadableSizeFrom(int sizeInBytes)
{
	float		lSize = sizeInBytes;
	NSString	*dimension;
	if (lSize > 1024.0) {
		if (lSize > 1024.0 * 1024.0) {
			if (lSize > 1024.0 * 1024.0 * 1024.0) {
				lSize /= 1024.0 * 1024.0 * 1024.0;
				dimension = @"G";
			} else {
				lSize /= 1024.0 * 1024.0;
				dimension = @"M";
			}
		} else {
			lSize /= 1024.0;
			dimension = @"K";
		}
	} else {
		dimension = nil;
	}
	if (dimension) {
		return [NSString stringWithFormat:@"%6.2f%@", lSize, dimension];
	} else {
		return [NSString stringWithFormat:@"%6dB", (int)lSize, dimension];
	}
}

NSString *ISONameOnlyFromSenderString(NSString *aSender)
{
	NSRange	parenRange;
	NSRange	aquoRange;
	int		beginIndex;
	int		endIndex = 1000000;
	NSMutableString	*returnString = [NSMutableString stringWithString:@""];
	
	if (aSender) {
		returnString = [NSMutableString stringWithString:aSender];
		aquoRange = [aSender rangeOfString:@"<"];
		if (aquoRange.length != 1) {
			parenRange = [aSender rangeOfString:@"("];
			if (parenRange.location != NSNotFound) {
				int	length;
				beginIndex = parenRange.location+1;
				parenRange = [aSender rangeOfString:@")"];
				if (parenRange.length == 1) {
					endIndex = parenRange.location-1;
				} else {
					endIndex = [aSender length];
				}
				if (beginIndex > [aSender length]) {
					beginIndex = 0;
				}
				length = endIndex-beginIndex+1;
				if (beginIndex + length > [aSender length]) {
					length = [aSender length] - beginIndex;
				}
				length = MAX(0, length);
				[returnString setString:[aSender substringWithRange:NSMakeRange(beginIndex, length)]];
			}
		} else {
			beginIndex = aquoRange.location;
			aquoRange = [aSender rangeOfString:@">"];
			if (aquoRange.location != NSNotFound) {
				NSMutableString *str;
				endIndex = aquoRange.location;
				str = [NSMutableString stringWithString:aSender];
				[str replaceCharactersInRange:NSMakeRange(beginIndex, endIndex-beginIndex+1) withString:@""];
				[returnString setString:str];
			}
		}
		if ([returnString compare:aSender] != NSOrderedSame) { // Lets remove all double-quotes and leading blanks
			if ([returnString hasPrefix:@" \""]) {
				[returnString setString:[returnString substringFromIndex:2]];
			} else if (([returnString hasPrefix:@"\""]) || ([returnString hasPrefix:@" "])) {
				[returnString setString:[returnString substringFromIndex:1]];
			}
			if ([returnString hasSuffix:@"\" "]) {
				[returnString setString:[returnString substringToIndex:[returnString length]-2]];
			} else if ([returnString hasSuffix:@"\""]) {
				[returnString setString:[returnString substringToIndex:[returnString length]-1]];
			}
		}
	}
	return returnString;
}


/* ********************** */
int compareSubjects(id postingOne, id postingTwo, void *ascending)
{
	NSString	*firstString = [postingOne decodedSubject];
	NSString	*secondString = [postingTwo decodedSubject];
	if ([firstString hasPrefix:@"Re: "] || [firstString hasPrefix:@"RE: "] || [firstString hasPrefix:@"re: "]) {
		firstString = [firstString substringFromIndex:4];
	}
	if ([secondString hasPrefix:@"Re: "] || [secondString hasPrefix:@"RE: "] || [secondString hasPrefix:@"re: "]) {
		secondString = [secondString substringFromIndex:4];
	}
	if (*((BOOL *)ascending) == NO) {
		return [firstString caseInsensitiveCompare:secondString];
	} else {
		return [secondString caseInsensitiveCompare:firstString];
	}
}

int compareSender(id postingOne, id postingTwo, void *ascending)
{
	if (*((BOOL *)ascending) == NO) {
		return [ISONameOnlyFromSenderString([postingOne decodedSender]) caseInsensitiveCompare:ISONameOnlyFromSenderString([postingTwo decodedSender])];
	} else {
		return [ISONameOnlyFromSenderString([postingTwo decodedSender]) caseInsensitiveCompare:ISONameOnlyFromSenderString([postingOne decodedSender])];
	}
}

int compareDate(id postingOne, id postingTwo, void *ascending)
{
	NSString	*fD = [postingOne comparableDate];
	NSString	*sD = [postingTwo comparableDate];
	if (*((BOOL *)ascending) == NO) {
		return [fD compare:sD];
	} else {
		return [sD compare:fD];
	}
}

int compareSize(id postingOne, id postingTwo, void *ascending)
{
	if ([[postingOne linesHeader] intValue] < [[postingTwo linesHeader] intValue])
		return (*((BOOL *)ascending) == NO)? NSOrderedAscending:NSOrderedDescending;
	else if ([[postingOne linesHeader] intValue] > [[postingTwo linesHeader] intValue])
		return (*((BOOL *)ascending) == NO)? NSOrderedDescending:NSOrderedAscending;
	else
		return NSOrderedSame;
}

