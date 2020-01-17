//
//  ISOJob.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ISOJobReceiverProtocol
- (BOOL)gracefullyKillOperations;
- (void)setJob:(id)aJob;
@end



@interface ISOJob : NSObject
{
	NSString	*jobname;
	id			subscriptionMgr;
	SEL			selector;
	id			receiver;
	id			userObject;
	BOOL		isConnectionJob;
	BOOL		isDisconnectionJob;
	BOOL		isJobRunning;
	int			ident;
	id			owner;
	BOOL		finished;
}

- initWithJobname:(NSString *)aName subscriptionMgr:(id)aSubs selector:(SEL)aSel receiver:(id)aRecv userObject:(id)uOb connection:(BOOL)cFlag disconnection:(BOOL)dFlag andIdent:(int)anIdent owner:(id)anOwner;
- (void)dealloc;
- (NSString *)jobname;
- (id)subscriptionMgr;
- (SEL)selector;
- (id)receiver;
- (id)userObject;
- (BOOL)isConnectionJob;
- (BOOL)isDisconnectionJob;
- (BOOL)isJobRunning;
- (BOOL)startJob;
- (BOOL)stopJob;
- (int)ident;
- (id)owner;
- (void)jobFinished:sender;
- (void)setFinished:(BOOL)flag;
- (BOOL)isJobFinished;
@end
