//
//  ISONewsServerMgr.m
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//
#import <Cocoa/Cocoa.h>

#import "ISONewsServerMgr.h"
#import "ISOSocketLineReader.h"
#import "ISOSubscription.h"
#import "KWInternetAddress.h"
#import "KWTCPEndpoint.h"
#import "ISOLogger.h"
#import "NSString_Extensions.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFStringEncodingExt.h>

#define K_NNTPLISTCOMMAND @"LIST\r\n"
#define K_NEWSGROUPLISTFORMATHEADERBEGIN @"215"

#define K_NNTPMODEREADERCOMMAND @"MODE READER\r\n"
#define K_NEWSMODEREADERRESPONSE @"200"

#define K_NNTPHEADCOMMAND @"HEAD "
#define K_NNTPHEADBEGIN @"221"

#define K_NNTPGROUPCOMMAND @"GROUP"
#define K_NNTPGROUPRESPONSEOK @"211"

#define K_NNTPNEXTCOMMAND @"NEXT\r\n"
#define K_NNTPNEXTRESPONSEOK @"223"

#define K_NNTPBODYCOMMAND @"BODY "
#define K_NNTPBODYBEGIN @"222"
#define K_NNTPNOSUCHPOSTING @"430"

#define K_NNTPARTICLECOMMAND @"ARTICLE "
#define K_NNTPARTICLEBEGIN @"220"

#define K_NNTPPOSTCOMMAND @"POST\r\n"
#define K_NNTPPOSTALLOWEDRESPONSE @"340"
#define K_NNTPPOSTFORBIDDENRESPONSE @"440"
#define K_NNTPPOSTFAILURERESPONSE @"441"
#define K_NNTPPOSTOKAYRESULT @"240"

#define K_NNTPLISTOVERVIEWCOMMAND @"LIST OVERVIEW.FMT\r\n"
#define K_NNTPLISTOVERVIEWRESPONSEOK @"215"

#define K_NNTPXOVERCOMMAND @"XOVER "
#define K_NNTPXOVERRESPONSE @"224"

#define K_AUTHUSERCOMMAND @"AUTHINFO USER "
#define K_AUTHUSEROKRESPONSE @"381"
#define K_AUTHPASSCOMMAND @"AUTHINFO PASS "
#define K_AUTHPASSOKRESPONSE @"281"

#define K_AUTHFAILEDRESPONSE @"482"

#define K_TIMEOUT 			@"503"

@implementation ISONewsServerMgr

- initForServer:(ISONewsServer *)aServer
{
    [super init];
    tcpEndpoint = nil;
    spamFilters = nil;
    activeGroup = nil;
    maxHeaderPerRequest = -1;
    theServer = aServer;
    [theServer retain];
	delegate = nil;
	readBufferSize = 16*1024;
	readingPostingBody = NO;
	readingHeaders = NO;
	currentSubscription = nil;
	gracefullyKilled = NO;
	activePosting = nil;
	connectCount = 0;
	isBeingUsed = NO;
	fastServerTryCount = K_FASTSERVERTRYCOUNT;
	mutex = [[NSLock alloc] init];
	connectMutex = [[NSLock alloc] init];
    return self;
}

- (void)dealloc
{
	[mutex dealloc];
	[connectMutex dealloc];
    [tcpEndpoint release];
    [theServer release];
    [spamFilters release];
    [activeGroup release];
    [super dealloc];
}

- (ISONewsServer *)newsServer
{
    return theServer;
}



- (BOOL)_retrieveMultiLineResponse:(NSMutableArray *)stringArray failed:(BOOL *)failed finished:(BOOL *)finished withSelect:(BOOL)withSelect withSocketLineReader:(ISOSocketLineReader *)socketLineReader
{
    int						res = 0;
    int						readResult;
	int						tryCount = 0, maxTryCount = fastServerTryCount;
    
	if ([theServer isSlowServer]) {
		maxTryCount = K_SLOWSERVERTRYCOUNT;
	}
	if (tcpEndpoint && !*failed) {
		if (socketLineReader == nil) {
			socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
			[socketLineReader setReadBufferSize:[self readBufferSize]];
			[socketLineReader setDelegate:self];
		}

        *finished = NO;
		tryCount = 0;
		while ((!*failed) && (!*finished) && (res >= 0)) {
			if (withSelect) {
				res = [tcpEndpoint selectForRead:YES write:NO timeout:100];
			} else {
				res = 1;
			}
			if (res > 0) {
				readResult = (int)[socketLineReader readLinesIntoArray:stringArray untilFinishText:@".\r\n"];
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
			return YES;
		}
	}
	return NO;
}

- (BOOL)_retrieveMultiLineResponse:(NSMutableArray *)stringArray failed:(BOOL *)failed finished:(BOOL *)finished
{
	return [self _retrieveMultiLineResponse:stringArray failed:failed finished:finished withSelect:YES withSocketLineReader:nil];
}



- (BOOL)_retrieveOneLineResponse:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished withSocketLineReader:(ISOSocketLineReader *)socketLineReader
{
    int						res;
    int						readResult;
	int						tryCount = 0, maxTryCount = fastServerTryCount;
    
	if ([theServer isSlowServer]) {
		maxTryCount = K_SLOWSERVERTRYCOUNT;
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"_retrieveOneLineResponse: failed: %d finished: %d withSocketLineReader:", *failed, *finished];
	if (tcpEndpoint && !*failed) {
		if (socketLineReader == nil) {
			socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
			[socketLineReader setReadBufferSize:[self readBufferSize]];
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
	if ([theServer isSlowServer]) {
		maxTryCount = K_SLOWSERVERTRYCOUNT;
	}
    [ISOActiveLogger logWithDebuglevel:66 :@"_sendOneLineResponseCommand:failed:finished: %d, %d [%@...]", *failed, *finished, [theCommand substringToIndex:commandlength]];
	*finished = NO;
	*failed = NO;
	if ((encoding == -1) || (encoding == kCFStringEncodingASCII)) { // No encoding, just binary data
		data = [NSData dataWithBytes:[theCommand cString] length:[theCommand length]];
	} else if (theCommand) {
		data = [theCommand dataUsingCFStringEncoding:encoding];
		[data writeToFile:@"/private/tmp/data.out" atomically:NO];
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
						if (![tcpEndpoint reconnect]) {
							localTryCount = maxTryCount+1;
							*failed = YES;
							*finished = YES;
							break;
						}
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
	gracefullyKilled = NO;
    if (theServer) {
		if (connectCount == 0) {
			tcpEndpoint = [[[KWTCPEndpoint alloc] init] retain];
			if (tcpEndpoint) {
				theAddress = [[KWInternetAddress alloc] initWithHost:[theServer serverName] port:[theServer port]];
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
							if ([self authenticate]) {
								[self setModeReader];
								[ISOActiveLogger logWithDebuglevel:66 :@"Connected..."];
								returnvalue = YES;
								connectCount = 2; // No, really 2. We keep one connection for ourselfs...
							} else {
								NSRunAlertPanel(NSLocalizedString(@"Authentication Failure",@""),
										NSLocalizedString(@"Authentication failed. Either your login name or your password is wrong. Please check in the preferences and try again.", @""),
										NSLocalizedString(@"OK", @""),
										nil,
										nil);
								[tcpEndpoint disconnect];
								[tcpEndpoint release];
								tcpEndpoint = nil;
								returnvalue = NO;
							}
						}
					}
					[theAddress release];
				} else {
					returnvalue = NO;
					[ISOActiveLogger logWithDebuglevel:66 :@"Could not resolve nntp-host: [%@]", [theServer serverName]];
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


- (BOOL)setModeReader
{
    NSMutableString			*resultString;
	NSMutableString			*theCommand;
    BOOL					finished = NO, failed = NO;
    BOOL					retvalue = NO;
	
	[ISOActiveLogger logWithDebuglevel:66 :@"Set Mode Reader"];
	[ISOActiveLogger incrementLoglevel];
	gracefullyKilled = NO;
	theCommand = [NSMutableString stringWithString:K_NNTPMODEREADERCOMMAND];
	resultString = [NSMutableString stringWithString:@""];
	if ([self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:&failed finished:&finished]) {
		if ([resultString hasPrefix:@"2"]) { // 2xx is usually "Okay"; 200=OK, 211=Okay, but here is some more info, etc.
			retvalue = YES;
		} else {
			retvalue = NO;
		}
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"ResultString: %@", resultString];
	[ISOActiveLogger logWithDebuglevel:66 :@"Set Mode Reader"];
	[ISOActiveLogger decrementLoglevel];
	return retvalue;
}


- (BOOL)authenticate
{
    NSMutableString			*resultString;
    BOOL					finished = NO, failed = NO;
	NSMutableString			*theCommand;
	BOOL					retval = NO;
    
	gracefullyKilled = NO;
	if (![theServer needsAuthentication]) {
		retval = YES;
	} else {
		[ISOActiveLogger logWithDebuglevel:66 :@"authenticate"];
		[ISOActiveLogger incrementLoglevel];
		theCommand = [NSMutableString stringWithString:K_AUTHUSERCOMMAND];
		[theCommand appendString:[theServer login]];
		[theCommand appendString:@"\r\n"];
		resultString = [NSMutableString stringWithString:@""];
		if ([self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:&failed finished:&finished]) {
			if ([resultString hasPrefix:K_AUTHUSEROKRESPONSE]) {
				[theCommand setString:K_AUTHPASSCOMMAND];
				[theCommand appendString:[theServer password]];
				[theCommand appendString:@"\r\n"];
				[resultString setString:@""];
				if ([self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:&failed finished:&finished]) {
					if ([resultString hasPrefix:K_AUTHPASSOKRESPONSE]) {
						retval = YES;
					}
				}
			}
		}
		[ISOActiveLogger decrementLoglevel];
		[ISOActiveLogger logWithDebuglevel:66 :@"authenticate"];
	}
	return retval;
}


- (void)disconnect:sender
{
	[mutex lock];
	gracefullyKilled = NO;
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
	gracefullyKilled = NO;
    if (tcpEndpoint) {
        [tcpEndpoint disconnect];
        [tcpEndpoint release];
        tcpEndpoint = nil;
    }
	[mutex unlock];
}

- (BOOL)checkAndReconnectIfNecessary
{
	BOOL	retval = NO;
	
	[connectMutex lock];
	[ISOActiveLogger logWithDebuglevel:66 :@"checkAndReconnectIfNecessary"];
	[ISOActiveLogger incrementLoglevel];
	fastServerTryCount = 100; // we try only 100 times to select for read, that should be enough
							  // to see whether we still have a connection
	if (![self setModeReader]) {
		fastServerTryCount = K_FASTSERVERTRYCOUNT;
		[ISOActiveLogger logWithDebuglevel:66 :@"It seems connection is closed for now: writeError == %d; I will try to reconnect!", [tcpEndpoint writeError]];
		[self hardcoreDisconnect];
		if ([self connect:self]) {
			retval = YES;
		}
	} else {
		if ([tcpEndpoint readError]) {
			[ISOActiveLogger logWithDebuglevel:66 :@"readError: %d", [tcpEndpoint readError]];
		}
		retval = YES;
	}
	[connectMutex unlock];
	fastServerTryCount = K_FASTSERVERTRYCOUNT;
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"checkAndReconnectIfNecessary"];
	return retval;
}


- (int)updateActiveList:sender
{
	NSMutableArray	*stringArray;
	NSMutableString	*theCommand;
    BOOL			finished = NO, failed = NO;
    int				retval = -1;
	
	[ISOActiveLogger logWithDebuglevel:66 :@"updateActiveList"];
	[ISOActiveLogger incrementLoglevel];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
	[self setIsBeingUsed:YES];
	gracefullyKilled = NO;
	theCommand = [NSMutableString stringWithString:K_NNTPLISTCOMMAND];
	stringArray = [NSMutableArray arrayWithCapacity:1];
	if ([self _sendOneLineResponseCommand:theCommand failed:&failed finished:&finished usingStringEncoding:-1 cte:nil]) {
		BOOL f = [self _retrieveMultiLineResponse:stringArray failed:&failed finished:&finished];
		[ISOActiveLogger logWithDebuglevel:66 :@"+  updateActiveList: _retrieveMLR/Result: %@, failed=%d, finished=%d", (f? @"ACK":@"NACK"), failed, finished];
		[self _parseActiveList:stringArray];
		retval = 0;
	}
	[self setIsBeingUsed:NO];
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"updateActiveList"];
	return retval;
}

- (int)socketLineReader:(id)sender didReadLine:(int)lineNo inString:(NSString *)aString
{
	if (gracefullyKilled) {
		[sender gracefullyKillOperations];
	}
	if (delegate) {
		if (readingPostingBody) {
			if ([delegate respondsToSelector:@selector(newsServerMgr:readsPosting:atLine:)]) {
				return (int)[delegate newsServerMgr:self readsPosting:activePosting atLine:lineNo];
			} else {
				return 0;
			}
		} else if (readingHeaders) {
			if ([self _parseOneHeader:aString intoHeaderList:headerList withSubscription:currentSubscription andGroup:activeGroup]) {
				if ([delegate respondsToSelector:@selector(newsServerMgr:didReadPostingHeader:)]) {
					[delegate newsServerMgr:self didReadPostingHeader:[headerList lastObject]];
				}
			}
			return 0;
		} else if ([delegate respondsToSelector:@selector(newsServerMgr:readGroup:)]) {
			return (int)[delegate newsServerMgr:self readGroup:lineNo];
		} else {
			return 0;
		}
	} else {
		return 0;
	}
}

- setSPAMFilter:(NSArray *)spamFilterList
{
//  [spamFilters release];
    spamFilters = spamFilterList;
//	[spamFilters retain];
    return self;
}

- (BOOL)setActiveGroup:(ISONewsGroup *)aGroup
{
    [activeGroup release];
    activeGroup = aGroup;
    [activeGroup retain];
    if ([self _selectGroup:aGroup] > 0) {
        return YES;
	} else {
        return NO;
    }
}

/* ********************************************************************************* 
* HEAD SECTION
* The process of retrieving the article headers:
*
* C: Connect to S
* C: GROUP <groupname>
* S: 211 104 10011 10125 <groupname> slected
* C: XOVER %d-
* S: 224 Data follows
* ... Following the head data until
* .
* QUIT
* ******************************************************************************** */
- (NSArray *)_retrieveHeadersForGroup:(ISONewsGroup *)aGroup fromHeader:(int )beginHeader toHeader:(int)endHeader  withSubscription:(ISOSubscription *)theSubscription
{
	ISOSocketLineReader		*socketLineReader;
	NSMutableArray			*stringArray;
	NSMutableString			*firstLineString;
	BOOL					finished = NO, failed = NO;
	NSMutableString			*theCommand;
    
	headerList = nil;
	currentSubscription = theSubscription;
	
	socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
	[socketLineReader setReadBufferSize:[self readBufferSize]];
	[socketLineReader setDelegate:self];
	headerList = [[NSMutableArray arrayWithCapacity:1] retain];
	if (delegate && [delegate respondsToSelector:@selector(newsServerMgr:numberOfPostingsToLoad:inGroup:)]) {
		[delegate newsServerMgr:self numberOfPostingsToLoad:(endHeader - beginHeader) inGroup:aGroup];
	}
	theCommand = [NSMutableString stringWithString:K_NNTPXOVERCOMMAND];
	[theCommand appendFormat:@" %d-", beginHeader];
	[theCommand appendFormat:@"%d\r\n", endHeader];
	stringArray = [NSMutableArray arrayWithCapacity:1000];
	firstLineString = [NSMutableString stringWithCapacity:128];
	if ([self _sendOneLineResponseCommand:theCommand failed:&failed finished:&finished usingStringEncoding:-1 cte:nil]) {
		if ([self _retrieveOneLineResponse:firstLineString failed:&failed finished:&finished withSocketLineReader:socketLineReader]) {
			if (!gracefullyKilled && [firstLineString hasPrefix:K_NNTPXOVERRESPONSE]) {
				if (!gracefullyKilled && [self _retrieveMultiLineResponse:stringArray failed:&failed finished:&finished withSelect:NO withSocketLineReader:socketLineReader]) {
					if (finished && !failed) {
						if ([headerList count] == 0) {
							[self _parseHeaders:stringArray intoHeaderList:headerList withSubscription:theSubscription andGroup:aGroup];
						}
					}
				}
			}
		}
	}
    return headerList;
}

- (NSArray *)retrieveHeadersForGroup:(ISONewsGroup *)aGroup maximum:(int)maxHeaderCount withSubscription:(ISOSubscription *)theSubscription
{
    int		headerCount;
	int		startPosting, endPosting;
	int		startPostingNumber, endPostingNumber;
	int		headerCountLoaded = 0;
	int		maxHeaderCountToDownload;
	NSArray	*theHeaders = nil;
	BOOL	dontLoadAnything = NO;
	NSDate	*oldDate;
    
	[ISOActiveLogger logWithDebuglevel:66 :@"retrieveHeadersForGroup"];
	[ISOActiveLogger incrementLoglevel];
	[self setIsBeingUsed:YES];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
	gracefullyKilled = NO;
	readingHeaders = YES;
	NSLog(@"STARTING TO LOAD HEADERS");
	oldDate = [NSDate date];
    headerCount = [self _selectGroup:aGroup startPosting:&startPostingNumber endPosting:&endPostingNumber];
	currentSubscription = theSubscription;
    if (!gracefullyKilled && headerCount > 0) {
		headerCountLoaded = 0;
		if (maxHeaderCount == 0) {
			maxHeaderCountToDownload = endPostingNumber - startPostingNumber;
			if ([aGroup lastPostingIndex] == 0) {
				startPosting = startPostingNumber;
				endPosting = endPostingNumber;
			} else {
				startPosting = [aGroup lastPostingIndex]+1;
				endPosting = endPostingNumber;
			}
		} else {
			maxHeaderCountToDownload = maxHeaderCount;
			endPosting = endPostingNumber;
			if ([aGroup lastPostingIndex] > 0) {
				startPosting = MAX([aGroup lastPostingIndex]+1, endPostingNumber - maxHeaderCount);
			} else {
				startPosting = MAX(0,endPostingNumber - maxHeaderCount);
			}
			if (startPosting > endPostingNumber) {
				dontLoadAnything = YES;
			}
		}
		if (!dontLoadAnything) {
			do {
				[ISOActiveLogger logWithDebuglevel:1 :@"Getting headers: %d - %d (=%d), maxHeaderCount: %d", startPosting, endPosting, endPosting-startPosting, maxHeaderCount];
				theHeaders = [self _retrieveHeadersForGroup:aGroup fromHeader:startPosting toHeader:endPosting  withSubscription:theSubscription];
				headerCountLoaded += [theHeaders count];
				startPosting = endPosting+1;
				[theHeaders release];
				theHeaders = nil;
				if (maxHeaderCount > 0) {
					endPosting = MIN(startPosting+(maxHeaderCount - headerCountLoaded), endPostingNumber);
				} else {
					endPosting = endPostingNumber;
				}
			} while (!gracefullyKilled && (headerCountLoaded < maxHeaderCountToDownload) && (startPosting < endPostingNumber ));
		}
	}
	NSLog(@"FINISHED LOADING %d HEADERS, elapsed time=%f seconds", headerCountLoaded, -1*[oldDate timeIntervalSinceNow]);
	readingHeaders = NO;
	[self setIsBeingUsed:NO];
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"retrieveHeadersForGroup"];
    return theHeaders;
}

- (int)_selectGroup:(ISONewsGroup *)aGroup startPosting:(int *)startPosting endPosting:(int *)endPosting
{
    NSMutableString			*theCommand;
    NSMutableString			*resultString;
	int						result = 0;
    BOOL					finished = NO, failed = NO;
    
    theCommand = [NSMutableString stringWithString:K_NNTPGROUPCOMMAND];
    [theCommand appendString:@" "];
    [theCommand appendString:[aGroup groupName]];
    [theCommand appendString:@"\r\n"];
	resultString = [NSMutableString string];

    activeGroup = aGroup;
	
	if ([self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:&failed finished:&finished]) {
		if (finished && ([resultString hasPrefix:K_NNTPGROUPRESPONSEOK])) {
			NSScanner	*aScanner;
            int			response, countPostings, lowPosting, highPosting;
            
            countPostings = -1;
            aScanner = [NSScanner scannerWithString:resultString];
            [aScanner scanInt:&response];
            [aScanner scanInt:&countPostings];
            [aScanner scanInt:&lowPosting];
            [aScanner scanInt:&highPosting];
			if (startPosting) {
				*startPosting = lowPosting;
			}
			if (endPosting) {
				*endPosting = highPosting;
			}
            result = countPostings;
        }
	}
    return result;
}

- (int)_selectGroup:(ISONewsGroup *)aGroup
{
	return [self _selectGroup:aGroup startPosting:NULL endPosting:NULL];
}

- (BOOL)_parseOneHeader:(NSString *)headerString intoHeaderList:(NSMutableArray *)aList withSubscription:(ISOSubscription *)theSubscription andGroup:(ISONewsGroup *)aGroup
{
	ISONewsPosting	*aPosting;
	
	aPosting = [[ISONewsPosting alloc] initLazyFromOverviewString:headerString withOverviewFmt:[theSubscription overviewFmt]];
	if (aPosting) {
		if ([aPosting wouldItExistAfterApplyingFilters:spamFilters]) {
			if ([aPosting articleServerID] > [aGroup lastPostingIndex]) {
				[aGroup setLastPostingIndex:[aPosting articleServerID]];
			}
			[aPosting setMainGroup:aGroup];
			[aList addObject:aPosting];
			return YES;
		} else {
			[aPosting release];
			return NO;
		}
	} else {
		return NO;
	}
}

- (BOOL)_parseHeaders:(NSArray *)stringList intoHeaderList:(NSMutableArray *)aList withSubscription:(ISOSubscription *)theSubscription andGroup:(ISONewsGroup *)aGroup
{
	int i, count;
	
	count = [stringList count];
	for (i=0; i<count; i++) {
		[self _parseOneHeader:[stringList objectAtIndex:i] 
			  intoHeaderList:aList
			  withSubscription:theSubscription
			  andGroup:aGroup];
	}
	return YES;
}

/* HEAD SECTION */



- (BOOL)completePostingHeaders:(ISONewsPosting *)aPosting
{
    BOOL			result = NO;
    ISONewsGroup	*aGroup = nil;
    
	[ISOActiveLogger logWithDebuglevel:66 :@"completePostingHeaders"];
	[ISOActiveLogger incrementLoglevel];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
	gracefullyKilled = NO;
    aGroup = [aPosting mainGroup];
	result = [self _completePostingHeaders:aPosting];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"completePostingHeaders"];
	[mutex unlock];
    return result;
}

- (BOOL)_completePostingHeaders:(ISONewsPosting *)aPosting
{
    NSMutableArray			*stringArray;
	NSMutableString			*firstLineString;
    BOOL					result = NO;
    BOOL					finished = NO, failed = NO;
    NSMutableString			*theCommand;
	ISOSocketLineReader		*socketLineReader;
	
	if ([aPosting messageIDHeader]) {
		activePosting = aPosting;
		socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
		[socketLineReader setReadBufferSize:[self readBufferSize]];
		[socketLineReader setDelegate:self];
		stringArray = [NSMutableArray arrayWithCapacity:1];
		firstLineString = [NSMutableString stringWithCapacity:128];
		theCommand = [NSMutableString stringWithString:K_NNTPHEADCOMMAND];
		[theCommand appendString:@" "];
		[theCommand appendString:[aPosting messageIDHeader]];
		[theCommand appendString:@"\r\n"];
		
		result = NO;
		readingPostingBody = YES;
		if ([self _sendOneLineResponseCommand:theCommand failed:&failed finished:&finished usingStringEncoding:-1 cte:nil]) {
			if ([self _retrieveOneLineResponse:firstLineString failed:&failed finished:&finished withSocketLineReader:socketLineReader]) {
				if (!gracefullyKilled && [firstLineString hasPrefix:K_NNTPHEADBEGIN]) {
					if ([self _retrieveMultiLineResponse:stringArray failed:&failed finished:&finished withSelect:NO withSocketLineReader:socketLineReader]) {
						result = [self _completeHeaders:stringArray inPosting:aPosting];
						if (finished && !failed) {
							if ([delegate respondsToSelector:@selector(newsServerMgr:didReadPosting:)]) {
								[delegate newsServerMgr:self didReadPosting:aPosting];
							}
						}
					}
				} else {
					[stringArray addObject:firstLineString];
					result = NO;
				}
			}
		}
		activePosting = nil;
		readingPostingBody = NO;
	}
	return result;
}

- (BOOL)_completeHeaders:(NSArray *)stringList inPosting:(ISONewsPosting *)aPosting
{

	NSMutableString	*bodyString;
	int				i;
	
	bodyString = [NSMutableString string];
	for (i=0;i<[stringList count];i++) {
		[bodyString appendString:[stringList objectAtIndex:i]];
	}
	if (![bodyString hasSuffix:@"\r\n\r\n"]) {
		if (![bodyString hasSuffix:@"\r\n"]) {
			[bodyString appendString:@"\r\n\r\n"];
		} else {
			[bodyString appendString:@"\r\n"];
		}
	}
	[ISOActiveLogger logWithDebuglevel:5 :@"_completeHeadersWith: [%@]", bodyString];
	return [aPosting readFromString:bodyString];
}

- (BOOL)retrievePostingBody:(ISONewsPosting *)aPosting
{
    int				headerCount = 0;
    BOOL			result = NO;
    ISONewsGroup	*aGroup = nil;
    
	[ISOActiveLogger logWithDebuglevel:66 :@"retrievePostingBody"];
	[ISOActiveLogger incrementLoglevel];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
	gracefullyKilled = NO;
    aGroup = [aPosting mainGroup];
    headerCount = [self _selectGroup:aGroup];

    if (headerCount > 0) {
        result = [self _getPostingBody:aPosting];
    }
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"retrievePostingBody"];
	[mutex unlock];
    return result;
}

- (BOOL)_getPostingBody:(ISONewsPosting *)aPosting
{
    NSMutableArray			*stringArray;
	NSMutableString			*firstLineString;
    BOOL					result = NO;
    BOOL					finished = NO, failed = NO;
    NSMutableString			*theCommand;
	ISOSocketLineReader		*socketLineReader;
	
	if ([aPosting messageIDHeader]) {
		activePosting = aPosting;
		socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
		[socketLineReader setReadBufferSize:[self readBufferSize]];
		[socketLineReader setDelegate:self];
		stringArray = [NSMutableArray arrayWithCapacity:1];
		firstLineString = [NSMutableString stringWithCapacity:128];
		theCommand = [NSMutableString stringWithString:K_NNTPARTICLECOMMAND];
		[theCommand appendString:@" "];
		[theCommand appendString:[aPosting messageIDHeader]];
		[theCommand appendString:@"\r\n"];
		
		result = NO;
		readingPostingBody = YES;
		if ([self _sendOneLineResponseCommand:theCommand failed:&failed finished:&finished usingStringEncoding:-1 cte:nil]) {
			if ([self _retrieveOneLineResponse:firstLineString failed:&failed finished:&finished withSocketLineReader:socketLineReader]) {
				if (!gracefullyKilled && [firstLineString hasPrefix:K_NNTPARTICLEBEGIN]) {
					[stringArray addObject:firstLineString];
					if ([self _retrieveMultiLineResponse:stringArray failed:&failed finished:&finished withSelect:NO withSocketLineReader:socketLineReader]) {
						result = [self _parseBody:stringArray intoPosting:aPosting];
						if (finished && !failed) {
							if ([delegate respondsToSelector:@selector(newsServerMgr:didReadPosting:)]) {
								[delegate newsServerMgr:self didReadPosting:aPosting];
							}
						}
					}
				} else {
					[stringArray addObject:firstLineString];
					result = [self _parseBody:stringArray intoPosting:aPosting];
				}
			}
		}
		activePosting = nil;
		readingPostingBody = NO;
	}
	return result;
}

- (BOOL)_parseBody:(NSArray *)stringList intoPosting:(ISONewsPosting *)aPosting
{
	NSMutableString	*bodyString;
	int				i, count;
	NSString		*oneLine;
	NSRange			aRange;
	BOOL			beginBody;
    BOOL			result = NO;
	BOOL			noSuchPosting = NO;
	
	count = [stringList count];
	bodyString = [NSMutableString stringWithString:@""];
	beginBody = NO;
	for (i=0; i<count; i++) {
		oneLine = [stringList objectAtIndex:i];
		if (!beginBody) {
			aRange = [oneLine rangeOfString:K_NNTPARTICLEBEGIN];
			if ((aRange.location == 0) && (aRange.length == 3)) {
				beginBody = YES;
			}
			aRange = [oneLine rangeOfString:K_NNTPNOSUCHPOSTING];
			if ((aRange.location == 0) && (aRange.length == 3)) {
				result = NO;
				noSuchPosting = YES;
			}
		} else {
            [bodyString appendString:oneLine];
		}
	}
	if ([bodyString length] > 4) {
		result = [aPosting updateFromString:bodyString];
    } else {
		if ([bodyString length] == 0) {
			[bodyString appendString:@"\r\n\r\n"];
		}
		if (noSuchPosting) {
			[bodyString appendString:NSLocalizedString(@"<The server returned a 'NO SUCH POSTING' Error Message.>\n<The posting may have expired already.>\n<This happens often in 'binaries'-groups very quickly>\n<due to harddisc space constraints.>", @"")];
		} else {
			[bodyString appendString:NSLocalizedString(@"<The server didn't return any response. I even tried a couple of times.>\n<It may be that the server is too slow.>\n<In this case please switch on 'Slow Server'>\n<in 'Preferences->Servers' and try again.>", @"")];
		}
		[aPosting setBodyFromString:bodyString];
		[aPosting setPostingInvalid:YES];
	}
	return result;
}


- _parseActiveList:(NSMutableArray *)stringList
{
	NSMutableArray	*activeListArray;
	ISONewsGroup	*oneGroup;
	int				i, count, startEntry;
	NSString		*oneLine;
	BOOL			beginGroups = NO;
	
	count = [stringList count];
	activeListArray = [NSMutableArray arrayWithCapacity:count];
	beginGroups = NO;
	[ISOActiveLogger logWithDebuglevel:66 :@"_parseActiveList: # of lines retrieved: %d", count];
	if ([stringList count] && ![[stringList objectAtIndex:0] hasPrefix:K_NEWSGROUPLISTFORMATHEADERBEGIN]) {
		beginGroups = YES;
		startEntry = 0;
	} else {
		beginGroups = YES;
		startEntry = 1;
	}
	for (i=startEntry; i<count; i++) {
		oneLine = [stringList objectAtIndex:i];
		if (!beginGroups) {
			if ([oneLine hasPrefix:K_NEWSGROUPLISTFORMATHEADERBEGIN]) {
				beginGroups = YES;
				[ISOActiveLogger logWithDebuglevel:66 :@"_parseActiveList: K_NEWSGROUPLISTFORMATHEADERBEGIN found"];
			}
		} else {
			oneGroup = [[ISONewsGroup alloc] initFromString:oneLine withServer:theServer withNotificationRegistration:NO];
			if (oneGroup) {
				[activeListArray addObject:oneGroup];
			}
		}
	}
	[ISOActiveLogger logWithDebuglevel:66 :@"_parseActiveList: activeListArray count: %d", [activeListArray count]];
	if ([activeListArray count] > 0) {
		[theServer setActiveList:activeListArray];
		[ISOActiveLogger logWithDebuglevel:66 :@"_parseActiveList: savingActiveList->Result: %@", [theServer saveActiveList:activeListArray]? @"ACK":@"NACK"];
		[theServer saveActiveList:activeListArray];
	}
	return self;
}

- setDelegate:(id)anObject
{
	delegate = anObject;
	return self;
}

- delegate
{
	return delegate;
}

- setReadBufferSize:(int)bufSize
{
	readBufferSize = bufSize;
	return self;
}

- (int)readBufferSize
{
	return readBufferSize;
}

/*
*/
- (ISONewsPosting *)postingHeaderAtIndex:(int)index
{
	if (index < [headerList count]) {
		return [headerList objectAtIndex:index];
	} else {
		return nil;
	}
}

/* POSTING A MESSAGE TO THE SERVER */
- (int)sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorString usingStringEncoding:(int)encoding cte:(NSString *)cte
{
	int	retval;
	[ISOActiveLogger logWithDebuglevel:66 :@"sendPosting:writeErrorsInto:usingStringEncoding:cte:"];
	[ISOActiveLogger incrementLoglevel];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
	if ([self _sendPOSTCommand]) {
		retval = [self _sendPosting:aPosting writeErrorsInto:errorString usingStringEncoding:encoding cte:cte];
	} else {
		retval = K_NNTPPOSTFORBIDDENRESPONSE_INT;
	}
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"sendPosting:writeErrorsInto:usingStringEncoding:cte:"];
	return retval;
}


- (BOOL)_sendPOSTCommand
{
    NSMutableString			*resultString;
    BOOL					finished = NO, failed = NO;
	NSString				*theCommand;
	BOOL					retval = NO;
    
	[ISOActiveLogger logWithDebuglevel:66 :@"_sendPOSTCommand"];
	[ISOActiveLogger incrementLoglevel];
	theCommand = [NSString stringWithString:K_NNTPPOSTCOMMAND];
	resultString = [NSMutableString stringWithCapacity:128];
	if ([self _sendOneLineResponseCommand:theCommand putResultInto:resultString failed:&failed finished:&finished]) {
		if (finished && !failed) {
			retval = [resultString hasPrefix:K_NNTPPOSTALLOWEDRESPONSE];
		}
	}
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"_sendPOSTCommand"];
	return retval;
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
		body = [NSMutableString stringWithString:[aPosting bodyAsRawText]];
		if (body) {
			[body writeToFile:@"/private/tmp/outposting.body.before" atomically:NO];
			[self _replaceString:"\r\n" withString:"\n" inString:body usingStringEncoding:encoding];
			[body writeToFile:@"/private/tmp/outposting.body.after.1" atomically:NO];
			[self _replaceString:"\r" withString:"\n" inString:body usingStringEncoding:encoding];
			[body writeToFile:@"/private/tmp/outposting.body.after.2" atomically:NO];
			[self _replaceString:"\n" withString:K_DELIMITERSTRING inString:body usingStringEncoding:encoding];
			[body writeToFile:@"/private/tmp/outposting.body.after.3" atomically:NO];
			[self _replaceString:K_DELIMITERSTRING withString:"\r\n" inString:body usingStringEncoding:encoding];
			[body writeToFile:@"/private/tmp/outposting.body.after.4" atomically:NO];
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
			if ([resultString hasPrefix:K_NNTPPOSTOKAYRESULT]) {
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
    int	returnValue = K_NNTPPOSTFAILURERESPONSE_INT;

	[errorMsg setString:NSLocalizedString(@"Unknown error", @"")];
	if ([self _sendPostingHeader:aPosting writeErrorsInto:errorMsg cte:cte]) {
		if ([self _sendPostingBody:aPosting writeErrorsInto:errorMsg usingStringEncoding:encoding cte:cte]) {
			if ([self _sendPostingConfirmWritingErrorsInto:errorMsg]) {
				returnValue = K_NNTPPOSTOKAYRESULT_INT;
			}
		}
	}
	return returnValue;
}

- (NSArray *)retrieveOverviewFmt
{
    NSMutableArray			*stringArray;
	NSMutableString			*firstLineString;
    BOOL					finished = NO, failed = NO;
    NSMutableString			*theCommand;
	ISOSocketLineReader		*socketLineReader;
	
	[ISOActiveLogger logWithDebuglevel:66 :@"retrieveOverviewFmt"];
	[ISOActiveLogger incrementLoglevel];
	[self checkAndReconnectIfNecessary];
	[mutex lock];
    theCommand = [NSMutableString stringWithString:K_NNTPLISTOVERVIEWCOMMAND];
	stringArray = [NSMutableArray arrayWithCapacity:16];
	firstLineString = [NSMutableString stringWithCapacity:128];
	socketLineReader = [[ISOSocketLineReader alloc] initWithTCPEndpoint:tcpEndpoint];
	[socketLineReader setReadBufferSize:[self readBufferSize]];
	[socketLineReader setDelegate:self];
	if ([self _sendOneLineResponseCommand:theCommand failed:&failed finished:&finished usingStringEncoding:-1 cte:nil]) {
		if ([self _retrieveOneLineResponse:firstLineString failed:&failed finished:&finished withSocketLineReader:socketLineReader]) {
			if ([firstLineString hasPrefix:K_NNTPLISTOVERVIEWRESPONSEOK]) {
				[self _retrieveMultiLineResponse:stringArray failed:&failed finished:&finished withSelect:NO withSocketLineReader:socketLineReader];
			}
		}
	}
	[mutex unlock];
	[ISOActiveLogger decrementLoglevel];
	[ISOActiveLogger logWithDebuglevel:66 :@"retrieveOverviewFmt"];
	return stringArray;
}

- (BOOL)gracefullyKillOperations
{
	gracefullyKilled = YES;
	connectCount = 1; // After a graceful kill, we *have* to close the connection, otherwise we will have problems
	return YES;
}

- (BOOL)isBeingUsed
{
	return isBeingUsed;
}

- (void)setIsBeingUsed:(BOOL)flag
{
	isBeingUsed = flag;
}

@end
