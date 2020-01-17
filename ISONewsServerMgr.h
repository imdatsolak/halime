//
//  ISONewsServerMgr.h
//  Halime
//
//  Created by iso on Fri Apr 27 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsServer.h"
#import "ISONewsGroup.h"
#import "ISONewsHeader.h"
#import "ISONewsPosting.h"
#import "ISOSocketLineReader.h"
#import "KWTCPEndpoint.h"

#define K_NNTPPOSTFORBIDDENRESPONSE_INT 440
#define K_NNTPPOSTFAILURERESPONSE_INT 441
#define K_NNTPPOSTOKAYRESULT_INT 240
#define K_FASTSERVERTRYCOUNT	600
#define K_SLOWSERVERTRYCOUNT	1200
#define K_DELIMITERSTRING 	"\x13"
#define K_CONFIRMSIGN		@"\r\n.\r\n"

@interface ISONewsServerMgr : NSObject
{
    ISONewsServer	*theServer;
    ISONewsGroup	*activeGroup;
    NSArray			*spamFilters;
    int				maxHeaderPerRequest;
    KWTCPEndpoint	*tcpEndpoint;
	id				delegate;
	int				readBufferSize;
	BOOL			readingPostingBody;
	BOOL			readingHeaders;
	NSMutableArray	*headerList;
	id				currentSubscription;
	BOOL			gracefullyKilled;
	ISONewsPosting	*activePosting;
	int				connectCount;
	BOOL			isBeingUsed;
	int				fastServerTryCount;
	NSLock			*mutex;
	NSLock			*connectMutex;
}

- initForServer:(ISONewsServer *)aServer;
- (void)dealloc;

- (ISONewsServer *)newsServer;

- (BOOL)_retrieveMultiLineResponse:(NSMutableArray *)stringArray failed:(BOOL *)failed finished:(BOOL *)finished withSelect:(BOOL)withSelect withSocketLineReader:(ISOSocketLineReader *)socketLineReader;
- (BOOL)_retrieveMultiLineResponse:(NSMutableArray *)stringArray failed:(BOOL *)failed finished:(BOOL *)finished;
- (BOOL)_retrieveOneLineResponse:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished withSocketLineReader:(ISOSocketLineReader *)socketLineReader;
- (BOOL)_retrieveOneLineResponse:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished;
- (BOOL)_sendOneLineResponseCommand:(NSString *)theCommand failed:(BOOL *)failed finished:(BOOL *)finished  usingStringEncoding:(int)encoding cte:(NSString *)cte;
- (BOOL)_sendOneLineResponseCommand:(NSString *)theCommand putResultInto:(NSMutableString *)resultString failed:(BOOL *)failed finished:(BOOL *)finished;

- (BOOL)connect:sender;
- (BOOL)setModeReader;
- (BOOL)authenticate;
- (void)disconnect:sender;
- (void)hardcoreDisconnect;

- (int)updateActiveList:sender;

- setSPAMFilter:(NSArray *)spamFilterList;
- (BOOL)setActiveGroup:(ISONewsGroup *)aGroup;
- (int)socketLineReader:(id)sender didReadLine:(int)lineNo inString:(NSString *)aString;
- (NSArray *)retrieveHeadersForGroup:(ISONewsGroup *)aGroup maximum:(int)maxHeaderCount withSubscription:(id)theSubscription;
- (int)_selectGroup:(ISONewsGroup *)aGroup startPosting:(int *)startPosting endPosting:(int *)endPosting;
- (int)_selectGroup:(ISONewsGroup *)aGroup;
- (BOOL)_parseOneHeader:(NSString *)headerString intoHeaderList:(NSMutableArray *)aList withSubscription:(id)theSubscription andGroup:(ISONewsGroup *)aGroup;
- (BOOL)_parseHeaders:(NSArray *)stringList intoHeaderList:(NSMutableArray *)aList withSubscription:(id)theSubscription andGroup:(ISONewsGroup *)aGroup;

- (BOOL)completePostingHeaders:(ISONewsPosting *)aPosting;
- (BOOL)_completePostingHeaders:(ISONewsPosting *)aPosting;
- (BOOL)_completeHeaders:(NSArray *)stringList inPosting:(ISONewsPosting *)aPosting;

- (BOOL)retrievePostingBody:(ISONewsPosting *)aPosting;
- (BOOL)_getPostingBody:(ISONewsPosting *)aPosting;
- (BOOL)_parseBody:(NSArray *)stringList intoPosting:(ISONewsPosting *)aPosting;

- _parseActiveList:(NSMutableArray *)activeString;

- setDelegate:(id)anObject;
- delegate;
- setReadBufferSize:(int)bufSize;
- (int)readBufferSize;
- (ISONewsPosting *)postingHeaderAtIndex:(int)index;

- (int)sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorString usingStringEncoding:(int)encoding cte:(NSString *)cte;
- (BOOL)_sendPOSTCommand;
- (int)_sendPosting:(ISONewsPosting *)aPosting writeErrorsInto:(NSMutableString *)errorMsg usingStringEncoding:(int)encoding cte:(NSString *)cte;
- (NSArray *)retrieveOverviewFmt;

- (BOOL)gracefullyKillOperations;
- (BOOL)isBeingUsed;
- (void)setIsBeingUsed:(BOOL)flag;
@end

@interface NSObject(ISONewsServerMgrDelegate)
- (int)newsServerMgr:(id)sender readGroup:(int)lineNo;
- (int)newsServerMgr:(id)newsServerMgr numberOfPostingsToLoad:(int)maxPostings inGroup:(ISONewsGroup *)aGroup;
- (BOOL)newsServerMgr:(id)newsServerMgr willReadPostingHeader:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr didReadPostingHeader:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr willReadPosting:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr didReadPosting:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine;


@end

