//
//  NSString_Extensions.m
//  Halime
//
//  Created by Imdat Solak on Mon Feb 04 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <unistd.h>
#import <CoreFoundation/CoreFoundation.h>
#import "NSString_Extensions.h"
#import "ISOLogger.h"
#import "uudeview.h"

@implementation NSString(Extensions)

+ (NSString *)stringWithData:(NSData *)data usingCFStringEncoding:(CFStringEncoding)cEncoding
{
	NSString			*uCodeString = nil;
	CFStringEncoding	theEncoding;
	CFStringRef			cfString;

	theEncoding = cEncoding;
	if (theEncoding <= 0) {
		theEncoding = kCFStringEncodingASCII;
	}
		
NS_DURING
	cfString = CFStringCreateWithBytes(NULL, [data bytes], [data length], theEncoding, NO);
NS_HANDLER
	[ISOActiveLogger logWithDebuglevel:1 :@"NSString-Extensions:stringWithData:usingCFStringEncoding->There was an exception here..."];
	return uCodeString;
NS_ENDHANDLER
	if (cfString) {
		uCodeString = [NSString stringWithString:(NSString *)cfString];
		CFRelease(cfString);
	}
	return uCodeString;
}

- (NSString *)base64EncodedStringUsingEncoding:(CFStringEncoding )encoding
{
	FILE		*outfp;
	FILE		*infp;
	NSString	*resultString = nil;
	NSData		*data;
	char		*buffer;
	
	UUInitialize();
	UUSetOption(UUOPT_TINYB64, 1, NULL);
	UUSetOption(UUOPT_FAST, 1, NULL);
	
	data = [self dataUsingCFStringEncoding:encoding];

	infp = fopen("/private/tmp/halime.in.text", "w+");
	outfp = fopen("/private/tmp/halime.out.text", "w+");
	fwrite([data bytes], [data length], 1, infp);
	fseek(infp, 0, SEEK_SET);

	//unlink("/private/tmp/halime.in.text");
	unlink("/private/tmp/halime.out.text");
	
	if (UUEncodeToStream(outfp, infp, NULL, B64ENCODED, "/private/tmp/halime.out.text", 0644) == UURET_OK) {
		int 	flen;
		
		fseek(outfp, 0, SEEK_END);
		flen = ftell(outfp);
		fseek(outfp, 0, SEEK_SET);
		buffer = malloc(flen+1);
		bzero(buffer, flen+1);
		fread(buffer, flen, 1, outfp);
		if (strstr(buffer, "\n") != NULL) {
			strstr(buffer, "\n")[0] = '\0';
		}
		resultString = [NSString stringWithCString:buffer];
		free (buffer);
	}
	fclose(outfp);
	fclose (infp);
	UUCleanUp();
	return resultString;
}

- (NSString *)qpEncodedStringUsingEncoding:(CFStringEncoding )encoding
{
	FILE		*outfp;
	FILE		*infp;
	NSString	*resultString = nil;
	int			ret;
	char		*buffer;
	NSData		*data;
	
	UUInitialize();
	UUSetOption(UUOPT_TINYB64, 1, NULL);
	UUSetOption(UUOPT_FAST, 1, NULL);

	data = [self dataUsingCFStringEncoding:encoding];
	
	infp = fopen("/private/tmp/halime.in.text", "w+");
	unlink("/private/tmp/halime.in.text");
	fwrite([data bytes], [data length], 1, infp);
	fprintf(infp, "\n");
	fseek(infp, 0, SEEK_SET);

	outfp = fopen("/private/tmp/halime.out.text", "w+");
	unlink("/private/tmp/halime.out.text");
	
	ret = UUEncodeToStream(outfp, infp, NULL, QP_ENCODED, "/private/tmp/halime.out.text", 0644);
	if (ret == UURET_OK) {
		int flen;
		
		fseek(outfp, 0, SEEK_END);
		flen = ftell(outfp);
		buffer = malloc(flen+1);
		bzero(buffer, flen+1);
		fseek(outfp, 0, SEEK_SET);
		fread(buffer, flen, 1, outfp);
		if (strstr(buffer, "\n") != NULL) {
			strstr(buffer, "\n")[0] = '\0';
		}
		resultString = [NSString stringWithCString:buffer];
		free (buffer);
	}
	fclose(outfp);
	fclose (infp);
	UUCleanUp();
	return resultString;
}

- (NSString *)getTransferableStringWithIANAName:(NSString *)iana andCFStringEncoding:(CFStringEncoding )enc
{
	NSArray			*anArray;
	NSMutableString	*theString;
	NSString		*resultString;
	NSRange			aRange;
	int				i, count;

	switch (enc) {
		case kCFStringEncodingMacRoman:
		case kCFStringEncodingMacSymbol:
		case kCFStringEncodingMacDingbats:
		case kCFStringEncodingMacTurkish:
		case kCFStringEncodingMacCroatian:
		case kCFStringEncodingMacIcelandic:
		case kCFStringEncodingMacRomanian:
		case kCFStringEncodingMacCeltic:
		case kCFStringEncodingMacGaelic:
		case kCFStringEncodingISOLatin1:
		case kCFStringEncodingISOLatin2:
		case kCFStringEncodingISOLatin3:
		case kCFStringEncodingISOLatin4:
		case kCFStringEncodingISOLatinCyrillic:
		case kCFStringEncodingISOLatinArabic:
		case kCFStringEncodingISOLatinGreek:
		case kCFStringEncodingISOLatinHebrew:
		case kCFStringEncodingISOLatin5:
		case kCFStringEncodingISOLatin6:
		case kCFStringEncodingISOLatinThai:
		case kCFStringEncodingISOLatin7:
		case kCFStringEncodingISOLatin8:
		case kCFStringEncodingISOLatin9:
			theString = [NSMutableString stringWithString:[self qpEncodedStringUsingEncoding:enc]];

			/* Now first replace blanks by =20 to make it a RFC-word */
			aRange = [theString rangeOfString:@" "];
			if (aRange.location != NSNotFound) {
				anArray = [theString componentsSeparatedByString:@" "];
				count = [anArray count];
				[theString setString:@""];
				
				if (count) {
					[theString appendString:[anArray objectAtIndex:0]];
				}
				for (i=1;i<count;i++) {
					[theString appendString:@"=20"];
					[theString appendString:[anArray objectAtIndex:i]];
				}
			}
			
			/* Next, replace ? by =3F */
			aRange = [theString rangeOfString:@"?"];
			if (aRange.location != NSNotFound) {
				anArray = [theString componentsSeparatedByString:@"?"];
				count = [anArray count];
				[theString setString:@""];
				
				if (count) {
					[theString appendString:[anArray objectAtIndex:0]];
				}
				for (i=1;i<count;i++) {
					[theString appendString:@"=3F"];
					[theString appendString:[anArray objectAtIndex:i]];
				}
			}
			resultString = [NSString stringWithFormat:@"=?%@?Q?%@?=", iana, theString];
			break;
		default:
			resultString = [NSString stringWithFormat:@"=?%@?B?%@?=",iana,[self base64EncodedStringUsingEncoding:enc]];
			break;
	}
	return resultString;
}

- (NSString *)getTransferableStringWithIANAName:(NSString *)iana andCFStringEncoding:(CFStringEncoding )enc flexible:(BOOL)flexible
{
	if (!flexible) {
		return [self getTransferableStringWithIANAName:iana andCFStringEncoding:enc];
	} else {
		if ([self canBeConvertedToEncoding:NSASCIIStringEncoding]) {
			return [NSString stringWithString:self];
		} else {
			return [self getTransferableStringWithIANAName:iana andCFStringEncoding:enc];
		}
	}
}

- (NSString *) rot13String
{
    int i;
    NSMutableString *theNewString = [NSMutableString stringWithCapacity: [self length]];
    for (i=0; i < [self length]; i++)
    {
        unichar theChar = [self characterAtIndex: i];
        if ( ((theChar > 'M') && (theChar <= 'Z')) || ((theChar > 'm') && (theChar <= 'z')) )
        {
            theChar -= 13;
        }
        else if (((theChar >= 'A') && (theChar <= 'M')) || ((theChar >= 'a') && (theChar <= 'm')))
        {
            theChar += 13;
        }
        [theNewString appendFormat: @"%c", theChar];
    }
    return theNewString;
}


- (NSString *) percentEscapedString
{
    return (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, NULL, kCFStringEncodingUTF8);
}

- (NSData *)dataUsingCFStringEncoding:(CFStringEncoding)theEncoding
{
	NSData			*data;
	unsigned char	*buffer;
	CFIndex			buflength;

	if (CFStringGetBytes((CFStringRef )self, CFRangeMake(0, [self length]), theEncoding, '?', NO, NULL, 0, &buflength)) {
		buffer = malloc(buflength+1);
		bzero(buffer, buflength+1);
		CFStringGetBytes((CFStringRef )self, CFRangeMake(0, buflength), theEncoding, '?', NO, buffer, buflength, &buflength);
		data = [NSData dataWithBytes:buffer length:buflength];
		free(buffer);
	} else {
		data = nil;
	}
	return data;
}

- (NSString *)unicodeStringWithCFStringEncoding:(CFStringEncoding )cEncoding
{
	NSData				*aData;
	NSString			*uCodeString = nil;
	CFStringEncoding	theEncoding;
	CFStringRef			cfString;
	CFDataRef			cfData;

	theEncoding = cEncoding;
	if (theEncoding <= 0) {
		theEncoding = kCFStringEncodingASCII;
	}
		
NS_DURING
	cfString = CFStringCreateWithBytes(NULL, [self cString], [self length], theEncoding, NO);
NS_HANDLER
	[ISOActiveLogger logWithDebuglevel:1 :@"NSString-Extensions:unicodeStringWithCFStringEncoding->There was an exception here...; self==%@", self];
	return self;
NS_ENDHANDLER
	if (cfString) {
		cfData = CFStringCreateExternalRepresentation(NULL, cfString, kCFStringEncodingUnicode, '?');
		if (cfData) {
			aData = [NSData dataWithBytes:CFDataGetBytePtr(cfData) length:CFDataGetLength(cfData)];
			uCodeString = [[NSString alloc] initWithData:aData encoding:NSUnicodeStringEncoding];
			[uCodeString autorelease];
			CFRelease(cfData);
		}
		CFRelease(cfString);
	}
	if (uCodeString) {
		return uCodeString;
	} else {
		return self;
	}
}

- (NSString *)_quotePrefixOfLine:(NSString *)aLine
{
	NSMutableString *quotePrefix = [NSMutableString string];
	NSCharacterSet	*cSet = [NSCharacterSet characterSetWithCharactersInString:@">}]|: "] ;
	NSScanner		*scanner = [NSScanner scannerWithString:aLine];
	NSString		*sString;

	while ([scanner scanCharactersFromSet:cSet intoString:&sString]) {
		[quotePrefix appendString:sString];
	}
	return quotePrefix;
	
}

- (NSString *)wrappedStringWithLineLength:(int)lineLength andQuotedWithQuoteString:(NSString *)quoteString
{
	NSArray					*lines = [self componentsSeparatedByString: @"\n"];
	NSMutableArray			*resultLines = [NSMutableArray array];
	NSString				*currentLine = nil;
	NSMutableString			*workString = nil;
	NSMutableString			*backupString = [NSMutableString string];
	NSMutableString			*quotePrefix = [NSMutableString string];
	NSString 				*resultString = nil;
	NSString				*newQuotePrefix = nil;
	int						i, count;
	NSMutableCharacterSet	*cSet = (NSMutableCharacterSet *)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
	NSString				*text = nil;
	NSString				*charSet = nil;
	int						lastScanPosition = 0;
	BOOL					finished = NO;
	NSScanner				*scanner = nil;
	NSScanner				*breakScanner = nil;
	BOOL					workOnNewLine = YES;
	BOOL					lineIsBreakeable = NO;
	NSString				*emptyString = [NSString string];

	[cSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	[cSet formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
	[cSet removeCharactersInString:@"\"'«`"];
	
	if (quoteString) {
		lineLength = lineLength - [quoteString length];
	}
	count = [lines count];
	i = 0;
	workOnNewLine = YES;
	while (i<count) {
		if (workOnNewLine) {
			currentLine = [lines objectAtIndex:i];
			newQuotePrefix = [self _quotePrefixOfLine:currentLine];
			[backupString setString:currentLine];
			if (![backupString hasSuffix:@"\r"]) {
				[backupString appendString:@"\r"];
			}
		} else {
			newQuotePrefix = quotePrefix;
		}
		breakScanner = [NSScanner scannerWithString:backupString];
		if (workOnNewLine) {
			[ISOActiveLogger logWithDebuglevel:1 :@"1. setScanLocation; string=[%@], line=%d", [scanner string], i];
			NS_DURING
				[scanner setScanLocation:MAX(0,MIN([[scanner string] length], [newQuotePrefix length]))];
			NS_HANDLER
				[ISOActiveLogger logWithDebuglevel:1 :@"1. setScanLocation: newQuotePrefix: [%@]", newQuotePrefix];
				NSLog(@"Before if");
				if ([[scanner string] length]) {
					[scanner setScanLocation:[[scanner string] length]-1];
				} else if ([scanner string]) {
					[scanner setScanLocation:0];
				}
			NS_ENDHANDLER
		}
		lineIsBreakeable = [breakScanner scanUpToCharactersFromSet:cSet intoString:nil];
		breakScanner = nil;
		if ([newQuotePrefix compare:quotePrefix] != NSOrderedSame) {
			[quotePrefix setString:newQuotePrefix];
			if (workString) {
				[resultLines addObject:workString];
			}
			workString = nil;
		}
		if (workString && ([workString length] >= lineLength)) {
			[resultLines addObject:workString];
			workString = nil;
		}
		if (!workString && ([backupString length] < lineLength) && ([quotePrefix length] == 0 || [backupString hasPrefix:quotePrefix]) && workOnNewLine) {
			workString = [NSMutableString string];
			if (quoteString && ([quotePrefix length] == 0)) {
				[workString appendString:@" "];
			}
			[workString appendString:backupString];
			if (![workString hasSuffix:@"\r"]) {
				[workString appendString:@"\r"];
			}
			[resultLines addObject:workString];
			workString = nil;
			workOnNewLine = YES;
			i++;
			continue;
		}
		if (([backupString length] + (workString? [workString length]:0) - (workString? [quotePrefix length]:0) < lineLength) && !quoteString) {
			if (!workString) {
				if ([backupString hasPrefix:quotePrefix]) {
					workString = [NSMutableString string];
				} else {
					workString = [NSMutableString stringWithString:quotePrefix];
				}
			}
			if ([backupString hasPrefix:quotePrefix]) {
				[workString appendString:[backupString substringFromIndex:[quotePrefix length]]];
			} else {
				[workString appendString:backupString];
			}
			if (![workString hasSuffix:@"\r"]) {
				[workString appendString:@"\r"];
			}
			[resultLines addObject:workString];
			workString = nil;
			workOnNewLine = YES;
			i++;
			continue;
		} else if ((!lineIsBreakeable && ([backupString length] <= lineLength)) && !quoteString) {
			if (workString) {
				if (![workString hasSuffix:@"\r"]) {
					[workString appendString:@"\r"];
				}
				[resultLines addObject:workString];
				workString = nil;
			}
			if ([backupString hasPrefix:quotePrefix]) {
				workString = [NSMutableString string];
			} else {
				workString = [NSMutableString stringWithString:quotePrefix];
			}
			if (([quotePrefix length] == 0) && (quoteString) && ([quoteString length])) {
				[workString appendString:@" "];
			}
			[workString appendString:backupString];
			[resultLines addObject:workString];
			workString = nil;
			workOnNewLine = YES;
			i++;
			continue;
		} else if ((!quoteString) && !lineIsBreakeable && ([quotePrefix length] > 0)) {
			if (workString) {
				if (![workString hasSuffix:@"\r"]) {
					[workString appendString:@"\r"];
				}
				[resultLines addObject:workString];
				workString = nil;
			}
			if ([backupString hasPrefix:quotePrefix]) {
				workString = [NSMutableString string];
			} else {
				workString = [NSMutableString stringWithString:quotePrefix];
			}
			[workString appendString:backupString];
			[resultLines addObject:workString];
			workString = nil;
			workOnNewLine = YES;
			i++;
			continue;
		}
		if (!workString) {
			workString = [NSMutableString stringWithString:quotePrefix];
			if (([quotePrefix length] == 0) && (quoteString) && ([quoteString length])) {
				[workString appendString:@" "];
			}
		}
		if ([backupString compare:@"\r"] == NSOrderedSame) {
			if (![workString hasSuffix:@"\r"]) {
				[workString appendString:backupString];
			}
			if (([workString length] == 1) || (workOnNewLine)) {
				[resultLines addObject:workString];
				workString = nil;
				if (([workString length] > 1) || (workOnNewLine)) {
					[resultLines addObject:@"\r"];
				}
			}
			[backupString setString:@""];
			workOnNewLine = YES;
			i++;
		} else {
			scanner = [NSScanner scannerWithString:backupString];
			[scanner setCharactersToBeSkipped:nil];
			if (workOnNewLine) {
				[ISOActiveLogger logWithDebuglevel:1 :@"2. setScanLocation"];
				NS_DURING
					[scanner setScanLocation:[quotePrefix length]];
				NS_HANDLER
					[scanner setScanLocation:[[scanner string] length]-1];
				NS_ENDHANDLER
			}
			lastScanPosition = [scanner scanLocation];
			finished = NO;
			charSet = nil;
			text = nil;
			while (!finished && ([workString length] < lineLength) && ([scanner scanUpToCharactersFromSet:cSet intoString:&text] || [scanner scanCharactersFromSet:cSet intoString:&charSet])) {
				if (text) {
					[scanner scanCharactersFromSet:cSet intoString:&charSet];
				} else {
					text = emptyString;
				}
				if (([workString length] <= 1) && ([text length] >= lineLength)) {
					// Text doesn't contain spaces or other mark where we can break
					// mostly occurs in japanese, chinese or korean text
					int	oldWorkStringLength = [workString length];
					[workString appendString:[text substringToIndex:MIN(lineLength+oldWorkStringLength, [text length])]];
					lastScanPosition = [scanner scanLocation];
					lastScanPosition -= [text length] - MIN(lineLength+oldWorkStringLength, [text length]);
					if (charSet && (MIN(lineLength+oldWorkStringLength, [text length]) != [text length])) {
						lastScanPosition -= [charSet length];
					}
					[workString appendString:@"\r"];
					[resultLines addObject:workString];
					finished = YES;
					workString = nil;
				} else if ([workString length] + [text length] > lineLength) {
					if ([workString compare:quotePrefix] == NSOrderedSame) { // workString is only Prefix
						[workString appendString:[text substringToIndex:lineLength - ([quotePrefix length] + (quoteString? [quoteString length]:0))]];
						lastScanPosition = [scanner scanLocation];
						lastScanPosition -= [text length] - (lineLength - ([quotePrefix length] + (quoteString? [quoteString length]:0)));
						if (charSet && ((lineLength - ([quotePrefix length] + (quoteString? [quoteString length]:0))) != [text length])) {
							lastScanPosition -= [charSet length];
						}
						[workString appendString:@"\r"];
						[resultLines addObject:workString];
						finished = YES;
						workString = nil;
					} else {
						finished = YES;
						[ISOActiveLogger logWithDebuglevel:1 :@"3. setScanLocation"];
						NS_DURING
							[scanner setScanLocation:lastScanPosition];
						NS_HANDLER
							[scanner setScanLocation:[[scanner string] length]-1];
						NS_ENDHANDLER
						[resultLines addObject:workString];
						workString = nil;
					}
				} else {
					lastScanPosition = [scanner scanLocation];
					if ([workString hasSuffix:@"\r"]) {
						[workString setString:[workString substringToIndex:[workString length]-1]];
						if ([workString length] > [quotePrefix length]) {
							[workString appendString:@" "];
						}
					}
					[workString appendString:text];
					if (charSet) {
						[workString appendString:charSet];
					}
				}
				text = nil;
				charSet = nil;
			}
			if (lastScanPosition < [backupString length]) {
				[backupString setString:[backupString substringFromIndex:lastScanPosition]];
				workOnNewLine = NO;
			} else {
				[backupString setString:@""];
				workOnNewLine = YES;
				i++;
			}
		}
	}
	if (workString) {
		[resultLines addObject:workString];
		workString = nil;
	}
	if (quoteString) {
		resultString = [resultLines componentsJoinedByString: [NSString stringWithFormat: @"\n%@", quoteString]];
		return [quoteString stringByAppendingString: [resultString substringToIndex: [resultString length]-1]];
	} else {
		resultString = [resultLines componentsJoinedByString: @"\n"];
		return resultString;
	}
}


- (NSString *)wrappedStringWithLineLength:(int)lineLength
{
	return [self wrappedStringWithLineLength:lineLength andQuotedWithQuoteString:nil];
}


@end
