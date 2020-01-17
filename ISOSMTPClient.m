//
//  ISONewsServerMgr.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//
#import <Cocoa/Cocoa.h>

#import "ISOSMTPClient.h"
#import "ISOSocketLineReader.h"
#import "KWInternetAddress.h"
#import "KWTCPEndpoint.h"
#import "ISOLogger.h"
#import "ISONewsServerMgr.h"
#import "NSString_Extensions.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFStringEncodingExt.h>

#define K_HELO				@"HELO me\r\n"
#define K_HELO_RESPONSE 	@"250 "

#define K_MAILFROM @"MAIL FROM: "
#define K_MAILFROM_RESPONSE	@"250 "

#define K_RCPTTO @"RCPT TO: "
#define K_RCPTTO_RESPONSE	@"250 "

#define K_DATA @"DATA\r\n"
#define K_DATA_RESPONSE		@"354 "

#define K_QUIT @"QUIT\r\n"
#define K_QUIT_RESPONSE		@"221 "

#define K_CONFIRM_RESPONSE	@"250 "

#define K_SMTP_PORT			25


@implementation ISOSMTPClient

- initForServerNamed:(NSString *)aServer withSender:(NSString *)sEmail forRecipient:(NSString *)rEmail sendAsPostingAndEmail:(BOOL)flag
{
    [super init];
    tcpEndpoint = nil;
	serverName = [NSString stringWithString:aServer];
	[serverName retain];
	serverPort = K_SMTP_PORT;
	
	readBufferSize = 16*1024;
	connectCount = 0;
	fastServerTryCount = K_FASTSERVERTRYCOUNT;
	mutex = [[NSLock alloc] init];
	recipientEmail = [NSString stringWithString:rEmail];
	[recipientEmail retain];
	senderEmail = [NSString stringWithString:sEmail];
	[senderEmail retain];
	sendAsPostingAndEmail = flag;
    return self;
}

- (void)dealloc
{
	[mutex dealloc];
    [tcpEndpoint release];
    [serverName release];
	[recipientEmail release];
	[senderEmail release];
    [super dealloc];
}


- (BOOL)_retrieveOneLineResponse:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished withSocketLineReader:(ISOSocketLineReader *)socketLineReader
{
    int	res;
    int	readResult;
	int	tryCount = 0, maxTryCount = fastServerTryCount;
    
	[ISOActiveLogger logWithDebuglevel:66 :@"_retrieveOneLineResponse: failed: %d finished: %d withSocketLineReader:", *failed, *finished];
	if (tcpEndpoint && !*failed) {
		if (socketLineReader == nil) {
			socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
			[socketLineReader setReadBufferSize:readBufferSize];
			[socketLineReader setDelegate:self];
		}
		
		*finished = NO;
		while ((!*failed) && (!*finished) && ((res = [tcpEndpoint selectForRead:YES write:NO timeout:100]) >= 0)){
			if (res > 0) {
				readResult = (int)[socketLineReader readLineIntoString:resultString];
				*finished = YES;
			}
			tryCount++;
			if (tryCount > maxTryCount) {
				res = -1;
				*failed = YES;
				*finished = YES;
			}
		}
		if (*finished && !*failed) {
			[ISOActiveLogger logWithDebuglevel:66 :@"Retrieved: [%@]", resultString];
			return YES;
		}
	}
	return NO;
}

- (BOOL)_retrieveOneLineResponse:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished
{
	return [self _retrieveOneLineResponse:resultString failed:failed finished:finished withSocketLineReader:nil];
}

- (BOOL)_sendOneLineResponseCommand:(NSString *)theCommand failed:(BOOL *)failed finished:(BOOL *)finished  usingStringEncoding:(int)encoding cte:(NSString *)cte
{
    int		res;
	int		maxTryCount = fastServerTryCount;
	NSData	*data = nil;
	int		commandlength = [theCommand length] - 2;
    
	[ISOActiveLogger incrementLoglevel];
	commandlength = MIN(32, commandlength);
    [ISOActiveLogger logWithDebuglevel:66 :@"_sendOneLineResponseCommand:failed:finished: %d, %d [%@...]", *failed, *finished, [theCommand substringToIndex:commandlength]];
	*finished = NO;
	*failed = NO;
	if ((encoding == -1) || (encoding == kCFStringEncodingASCII)) { // No encoding, just binary data
		data = [NSData dataWithBytes:[theCommand cString] length:[theCommand length]];
	} else if (theCommand) {
		data = [theCommand dataUsingCFStringEncoding:encoding];
	} else {
		data = nil;
		*failed = YES;
		*finished = YES;
	}
	if (data && tcpEndpoint) {
		int localTryCount = 0;
		int	localResult;
		int	commandLength;
		int	writeCount = 0;
        while (!*finished && !*failed && (localTryCount < maxTryCount) && ((res = [tcpEndpoint selectForRead:NO write:YES timeout:100]) >= 0)) {
            if (res > 0) {
				commandLength = [data length];
				while (writeCount < commandLength) {
					localResult = [tcpEndpoint writeBytes:[data bytes] length:[data length]];
					if (localResult >= 0) {
						writeCount += localResult;
						if (writeCount < commandLength) {
							NSRange aRange;
							aRange.location = localResult;
							aRange.length = [data length] - localResult;
							data = [data subdataWithRange:aRange];
						}
					} else if ((writeCount == -1) && ([tcpEndpoint writeError] == SIGPIPE_RAISED_ERR)) {
						localTryCount++;
						[ISOActiveLogger logWithDebuglevel:50 :@"SIGPIPE RAISED ERR"];
						localTryCount = maxTryCount+1;
						*failed = YES;
						*finished = YES;
						break;
					} else {
						localTryCount = maxTryCount+1;
						*failed = YES;
						*finished = YES;
						break;
					}
				}
                *finished = YES;
            }
			localTryCount++;
		}
		if (*finished && !*failed) {
			[ISOActiveLogger logWithDebuglevel:66 :@"finished: %d, failed: %d", *finished, *failed];
			[ISOActiveLogger decrementLoglevel];
			return YES;
		}
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"finished: %d, failed: %d", *finished, *failed];
	[ISOActiveLogger decrementLoglevel];
    return NO;
}

- (BOOL)_sendOneLineResponseCommand:(NSString *)theCommand putResultInto:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished usingStringEncoding:(int)encoding cte:(NSString *)cte
{
	[self _sendOneLineResponseCommand:theCommand failed:failed finished:finished usingStringEncoding:encoding cte:cte];
	return [self _retrieveOneLineResponse:resultString failed:failed finished:finished];
}

- (BOOL)_sendOneLineResponseCommand:(NSString *)theCommand putResultInto:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished
{
	return [self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:failed finished:finished usingStringEncoding:-1 cte:nil];
}


- (BOOL)connect:sender
{
    KWInternetAddress 	*theAddress;
    BOOL 				returnvalue;
	BOOL				finished = NO, failed = NO;
    NSMutableString		*resultString;

	[mutex lock];
	[ISOActiveLogger logWithDebuglevel:66 :@"connect"];
	[ISOActiveLogger incrementLoglevel];
    if (serverName) {
		if (connectCount == 0) {
			tcpEndpoint = [[[KWTCPEndpoint alloc] init] retain];
			if (tcpEndpoint) {
				theAddress = [[KWInternetAddress alloc] initWithHost:serverName port:serverPort];
				[ISOActiveLogger logWithDebuglevel:66 :@"TheAddress..."];
				if (theAddress) {
					[ISOActiveLogger logWithDebuglevel:66 :@"Connecting..."];
					returnvalue = [tcpEndpoint connectToAddress:theAddress];
					if (returnvalue == NO) {
						[tcpEndpoint release];
						tcpEndpoint = nil;
					} else {
						resultString = [NSMutableString stringWithString:@""];
						if ([self _retrieveOneLineResponse:resultString failed:&failed finished:&finished]) {
							returnvalue = YES;
							connectCount = 2; // No, really 2. We keep one connection for ourselfs...
						}
					}
					[theAddress release];
				} else {
					returnvalue = NO;
					[ISOActiveLogger logWithDebuglevel:66 :@"Could not resolve SMTP-host: [%@]", serverName];
				}
			} else {
				returnvalue = NO;
			}
		} else {
			connectCount++;
			returnvalue = YES;
		}
    } else {
        returnvalue = NO;
    }
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"connect"];
    return returnvalue;
}


- (void)disconnect:sender
{
	[mutex lock];
	connectCount--;
    if (tcpEndpoint && (connectCount == 0)) {
		BOOL f = NO, fi=NO;
		
		[self _sendOneLineResponseCommand:@"QUIT\r\n" failed:&f finished:&fi usingStringEncoding:-1 cte:nil];
        [tcpEndpoint disconnect];
        [tcpEndpoint release];
        tcpEndpoint = nil;
    }
	[mutex unlock];
}

- (void)hardcoreDisconnect
{
	[mutex lock];
	connectCount = 0;
    if (tcpEndpoint) {
        [tcpEndpoint disconnect];
        [tcpEndpoint release];
        tcpEndpoint = nil;
    }
	[mutex unlock];
}

/* POSTING A MESSAGE TO THE SERVER */
- (BOOL)_sendCommand:(NSString *)command checkForResponse:(NSString *)response putErrorsInto:(NSMutableString *)errorString
{
    BOOL	finished = NO, failed = NO;
	BOOL	retval = NO;

	if ([self _sendOneLineResponseCommand:command putResultInto:errorString failed:&failed finished:&finished]) {
		if (finished && !failed) {
			retval = [errorString hasPrefix:response];
		}
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"CMD=[%@], RESPONSE=[%@]", command, errorString];
	return retval;
}

- (int)_sendPreamblePuttingErrorsInto:(NSMutableString *)errorString
{
	NSString	*theCommand;
	
	[ISOActiveLogger logWithDebuglevel:66 :@"_sendPreamble"];

	[ISOActiveLogger logWithDebuglevel:66 :@"Sending [HELO me]"];
	theCommand = [NSString stringWithString:K_HELO];
	if (![self _sendCommand:theCommand checkForResponse:K_HELO_RESPONSE putErrorsInto:errorString]) {
		return K_HELO_ERROR;
	}
	
	[ISOActiveLogger logWithDebuglevel:66 :@"Sending [%@ %@]", K_MAILFROM, senderEmail];
	theCommand = [NSString stringWithFormat:@"%@ %@\r\n", K_MAILFROM, senderEmail];
	if (![self _sendCommand:theCommand checkForResponse:K_MAILFROM_RESPONSE putErrorsInto:errorString]) {
		return K_MAILFROM_ERROR;
	}
	
	[ISOActiveLogger logWithDebuglevel:66 :@"Sending [%@ %@]", K_RCPTTO, recipientEmail];
	theCommand = [NSString stringWithFormat:@"%@ %@\r\n", K_RCPTTO, recipientEmail];
	if (![self _sendCommand:theCommand checkForResponse:K_RCPTTO_RESPONSE putErrorsInto:errorString]) {
		return K_RCPTTO_ERROR;
	}
	
	[ISOActiveLogger logWithDebuglevel:66 :@"Sending [DATA]"];
	theCommand = [NSString stringWithString:K_DATA];
	if (![self _sendCommand:theCommand checkForResponse:K_DATA_RESPONSE putErrorsInto:errorString]) {
		return K_DATA_ERROR;
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"_sendPreamble"];
	return 0;
}

- (void)_replaceString:(char *)stringToReplace withString:(char *)replaceString inString:(NSMutableString *)theString usingStringEncoding:(NSStringEncoding)enc
{
	NSData			*searchData;
	int				length;
	NSMutableData	*mdata;
	const char  	*dbytes;
	int				i, count, lastIndex, thisIndex, stringToReplaceLength;
	NSString		*tempString;
	NSMutableArray	*positions;

	[ISOActiveLogger logWithDebuglevel:66 :@"_replaceString"];
	[ISOActiveLogger incrementLoglevel];
	searchData = [theString dataUsingCFStringEncoding:enc];
	if (searchData) {
		length = [searchData length];
		mdata = [NSMutableData dataWithCapacity:length];
		dbytes = [searchData bytes];
		positions = [NSMutableArray array];
	
		stringToReplaceLength = strlen(stringToReplace);
		i = 0;
		while (i <= length) {
			if (strncmp(dbytes+i, stringToReplace, stringToReplaceLength) == 0) {
				[positions addObject:[NSNumber numberWithInt:i]];
				i += stringToReplaceLength;
			} else {
				i++;
			}
		}
		
		count = [positions count];
		lastIndex = 0;
		for (i=0; i<count; i++) {
			thisIndex = [[positions objectAtIndex:i] intValue];
			if (lastIndex >0) {
				[mdata appendBytes:replaceString length:strlen(replaceString)];
			}
			[mdata appendData:[searchData subdataWithRange:NSMakeRange(lastIndex,thisIndex-lastIndex)]];
			lastIndex = thisIndex + stringToReplaceLength;
		}
		if (lastIndex < length) {
			if ([mdata length]) {
				[mdata appendBytes:replaceString length:strlen(replaceString)];
			}
			[mdata appendData:[searchData subdataWithRange:NSMakeRange(lastIndex,[searchData length]-lastIndex)]];
		}
		tempString = [NSString stringWithData:mdata usingCFStringEncoding:enc];
		if (tempString) {
			[theString setString:tempString];
		} else {
			[ISOActiveLogger logWithDebuglevel:0 :@"PANIC: _replaceString:withString:inString:usingStringEncoding:->Couldn't create back a sString after replacing some characters in it..."];
		}
	} else {
		[ISOActiveLogger logWithDebuglevel:66 :@"Couldn't create DATA with encoding."];
	}
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"_replaceString"];
}

- (BOOL)_sendPostingHeader:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorMsg cte:(NSString *)cte
{
	NSMutableString	*header;
	BOOL			finished = NO, failed = NO;
	BOOL			retval = NO;
	
	[ISOActiveLogger logWithDebuglevel:10 :@"_sendPostingHeader"];
	[ISOActiveLogger incrementLoglevel];
	[errorMsg setString:@"Error sending the header."];
	if (aPosting) {
		header = [NSMutableString stringWithString:[aPosting transferableHeader]];
		if (header) {
			[ISOActiveLogger logWithDebuglevel:10 :@"Will send headers:[%@]", header];
			[header appendFormat:@"To: %@\r\n", recipientEmail];
			[header appendString:@"\r\n"];
			if ([self _sendOneLineResponseCommand:header failed:&failed finished:&finished usingStringEncoding:kCFStringEncodingASCII cte:cte]) {
				if (finished && !failed) {
					[errorMsg setString:@""];
					retval = YES;
				}
			}
		}
	}
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:10 :@"_sendPostingHeader"];
	return retval;
}

- (BOOL)_sendPostingBody:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorMsg usingStringEncoding:(int)encoding cte:(NSString *)cte
{
	NSMutableString	*body;
	BOOL			finished = NO, failed = NO;
	BOOL			retval = NO;
	
	[errorMsg setString:@"Error sending the body."];
	if (aPosting) {
		body = [NSMutableString string];
		if (sendAsPostingAndEmail) {
			[body appendString:@"*** Please note: this mail was sent to you AND sent as ***\n*** followup to the newsgroup specified.               ***\n\n"];
		}
		[body appendString:[aPosting bodyAsRawText]];
		if (body) {
			[self _replaceString:"\r\n" withString:"\n" inString:body usingStringEncoding:encoding];
			[self _replaceString:"\r" withString:"\n" inString:body usingStringEncoding:encoding];
			[self _replaceString:"\n" withString:K_DELIMITERSTRING inString:body usingStringEncoding:encoding];
			[self _replaceString:K_DELIMITERSTRING withString:"\r\n" inString:body usingStringEncoding:encoding];
			if ([self _sendOneLineResponseCommand:body failed:&failed finished:&finished usingStringEncoding:encoding cte:cte]) {
				if (finished && !failed) {
					[errorMsg setString:@""];
					retval = YES;
				}
			}
		}
	}
	return retval;
}

- (BOOL)_sendPostingConfirmWritingErrorsInto:(NSMutableString *)errorMsg
{
	NSMutableString *resultString;
	BOOL			finished = NO, failed = NO;
	BOOL			retval = NO;
	
	resultString = [NSMutableString string];
	[errorMsg setString:@"Error sending the Confirmation sign (\\r\\n.\\r\\n)"];
	if ([self _sendOneLineResponseCommand:K_CONFIRMSIGN putResultInto:resultString failed:&failed finished:&finished usingStringEncoding:kCFStringEncodingASCII cte:@"7bit"]) {
		if (finished && !failed) {
			if ([resultString hasPrefix:K_CONFIRM_RESPONSE]) {
				retval = YES;
				[errorMsg setString:@""];
			} else {
				[errorMsg setString:resultString];
			}
		} else {
			[errorMsg setString:resultString];
		}
	}
	return retval;
}

- (int)_sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorMsg usingStringEncoding:(int)encoding cte:(NSString *)cte
{
    int	returnValue = K_SMTPPOSTFAILURERESPONSE_INT;

	[errorMsg setString:NSLocalizedString(@"Unknown error", @"")];
	if ([self _sendPostingHeader:aPosting writeErrorsInto:errorMsg cte:cte]) {
		if ([self _sendPostingBody:aPosting writeErrorsInto:errorMsg usingStringEncoding:encoding cte:cte]) {
			if ([self _sendPostingConfirmWritingErrorsInto:errorMsg]) {
				returnValue = K_SMTPPOSTOKAYRESULT_INT;
			}
		}
	}
	return returnValue;
}


- (int)sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorString usingStringEncoding:(int)encoding cte:(NSString *)cte
{
	int	retval;
	[ISOActiveLogger logWithDebuglevel:66 :@"sendPosting:writeErrorsInto:usingStringEncoding:cte:"];
	[ISOActiveLogger incrementLoglevel];
	[mutex lock];
	retval = [self _sendPreamblePuttingErrorsInto:errorString];
	if (retval == 0) {
		retval = [self _sendPosting:aPosting writeErrorsInto:errorString usingStringEncoding:encoding cte:cte];
	}
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"sendPosting:writeErrorsInto:usingStringEncoding:cte:"];
	return retval;
}

@end
