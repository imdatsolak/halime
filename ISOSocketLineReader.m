//
//  ISOSocketLineReader.m
//  Halime
//
//  Created by iso on Mon May 21 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOSocketLineReader.h"
#import "ISOLogger.h"
#import "debugging.h"

@implementation ISOSocketLineReader

- initWithTCPEndpoint:(KWTCPEndpoint *)anEndpoint
{
	self = [super init];
	if (anEndpoint) {
		delegate = nil;
#ifdef MAC_SLOWDOWN_FOR_TESTING
		readBufferSize = 128;
#else
		readBufferSize = 3072;
#endif
		finishText = nil;
		tcpEndpoint = anEndpoint;
		sustainBuffer = [NSMutableString stringWithCapacity:1];
		gracefullyKilled = NO;
		readError = 0;
		return self;
	} else {
		[self dealloc];
		return nil;
	}
}

- (void)dealloc
{
	sustainBuffer = nil;
	[delegate release];
	[finishText release];
	[tcpEndpoint release];
	[super dealloc];
}

- setDelegate:(id)anObject
{
	[delegate release];
	delegate = anObject;
	[delegate retain];
	return self;
}

- setReadBufferSize:(int)aSize
{
	readBufferSize = aSize;
	return self;
}

- setFinishText:(NSString *)aText
{
	[finishText release];
	finishText = aText;
	[finishText retain];
	return self;
}

- delegate
{
	return delegate;
}

- (int)readBufferSize
{
	return readBufferSize;
}

- (NSString *)finishText
{
	return finishText;
}

- (int)readLineIntoString:(NSMutableString *)paramString
{
	NSString		*aString;
    char 			*buffer;
	char 			*buffer2;
	char			*buffer3;
    int 			len;
	BOOL 			finished = NO;
    NSRange			aRange;
	int				rBufSize;
	
	readError = 0;
	aRange = [sustainBuffer rangeOfString:@"\n"];
	if ((aRange.location >= 0) && (aRange.length == 1)) {
		aRange.length = aRange.location+1;
		aRange.location = 0;
		[paramString setString:[sustainBuffer substringWithRange:aRange]];
		[sustainBuffer deleteCharactersInRange:aRange];
#ifdef MAC_SLOWDOWN_FOR_TESTING
		sleep(1);
#endif
		return 0;
	} else if (tcpEndpoint) {
		rBufSize = [self readBufferSize];
		buffer = malloc(rBufSize+1);
		memset(buffer, 0, rBufSize+1);
		buffer2 = malloc((rBufSize+1)*2);
		memset(buffer2, 0, (rBufSize+1)*2);
		buffer3 = NULL;
		do {
			memset(buffer, 0, rBufSize+1);
			len = [tcpEndpoint readBytes:buffer length:rBufSize-1];
			if (len >0) {
				buffer[len] = '\0';
				if (strstr(buffer, "\n")) {
					finished = YES;
					strcpy(buffer2, buffer);
					strstr(buffer2, "\n")[1] = '\0';
					strcpy(buffer, strstr(buffer,"\n")+1);

					buffer3 = malloc([sustainBuffer length] + strlen(buffer2)+128);
					memset(buffer3, 0, [sustainBuffer length] + strlen(buffer2)+128);
					[sustainBuffer getCString:buffer3];
					strcat(buffer3, buffer2);
					aString = [NSString stringWithCString:buffer3];
					free(buffer3);

					[paramString setString:aString];
					aString = nil;
					[sustainBuffer setString:@""];
				}							
				aString = [NSString stringWithCString:buffer];
				if (aString) {
					[sustainBuffer appendString:aString];
				}
				aString = nil;
			} else if (len == -1) {
				[self setReadError:[tcpEndpoint readError]];
			} else if (len == 0) {
				[self setReadError:-10000];		// SocketClosed Error
			}
#ifdef MAC_SLOWDOWN_FOR_TESTING
			sleep(1);
#endif
		} while ((len > 0) && (!finished));
		free(buffer2);
		free(buffer);
		if (finished) {
			return 0;
		} else {
			return -1;
		}
    } else {
		return -1;
	}
}

- (int)readLinesIntoArray:(NSMutableArray *)stringArray untilFinishText:(NSString *)aFinishText
{
	NSMutableString	*oneLine;
	BOOL			finished;
	int				resultCode;
	int				lineNo;
	NSRange			aRange;
	
	lineNo = 0;
	resultCode = 0;
    finished = NO;
	while (!finished && !gracefullyKilled) {
        oneLine = [NSMutableString stringWithCapacity:1];
        [oneLine setString:@""];
		resultCode = [self readLineIntoString:oneLine];
		if (resultCode == 0) {
			aRange = [oneLine rangeOfString:aFinishText];
			if ([oneLine hasPrefix:aFinishText] || ([self readError] != 0)) {
				finished = YES;
            } else {
				lineNo++;
				if (delegate && ([delegate respondsToSelector:@selector(socketLineReader:didReadLine:inString:)])) {
					resultCode = [delegate socketLineReader:self didReadLine:lineNo inString:oneLine];
				}
				[stringArray addObject:oneLine];
			}
		} else {
            [ISOActiveLogger logWithDebuglevel:1 :@"Weird line in ISOSocketLineReader: [%@]", oneLine];
        }
		if (resultCode != 0) {
			finished = YES;
		}
        oneLine = nil;
	}
	return resultCode;
}

- (BOOL)gracefullyKillOperations
{
	gracefullyKilled = YES;
	return YES;
}

- (int)readError
{
	return readError;
}

- (void)setReadError:(int)anError
{
	readError = anError;
}

@end
