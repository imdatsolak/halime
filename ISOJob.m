//
//  ISOJob.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOJob.h"
#import "ISOJobMgr.h"
#import "ISOLogger.h"

@implementation ISOJob
- initWithJobname:(NSString *)aName subscriptionMgr:(id)aSubs selector:(SEL)aSel receiver:(id)aRecv userObject:(id)uOb connection:(BOOL)cFlag disconnection:(BOOL)dFlag andIdent:(int)anIdent owner:(id)anOwner
{
	[super init];
	jobname = aName;
	[aName retain];
	
	subscriptionMgr = aSubs;
	[subscriptionMgr retain];
	
	selector = aSel;
	receiver = aRecv;
	[receiver retain];

	userObject = uOb;
	[userObject retain];

	isConnectionJob = cFlag;
	isDisconnectionJob = dFlag;
	isJobRunning = NO;
	ident = anIdent;
	[receiver setJob:self];
	owner = anOwner;
	finished = NO;
	return self;
}

- (void)dealloc
{
	[jobname release];
	[subscriptionMgr release];
	[receiver release];
	[userObject release];
	[super dealloc];
}

- (NSString *)jobname
{
	return jobname;
}

- (id)subscriptionMgr
{
	return subscriptionMgr;
}

- (SEL)selector
{
	return selector;
}

- (id)receiver
{
	return receiver;
}

- (id)userObject
{
	return userObject;
}

- (BOOL)isConnectionJob
{
	return isConnectionJob;
}

- (BOOL)isDisconnectionJob
{
	return isDisconnectionJob;
}

- (BOOL)isJobRunning
{
	return isJobRunning;
}

- (id)owner
{
	return owner;
}

- (BOOL)startJob
{
	if ([receiver respondsToSelector:selector]) {
		[NSThread detachNewThreadSelector:selector toTarget:receiver withObject:userObject];
		isJobRunning = YES;
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)stopJob
{
	if ([receiver respondsToSelector:@selector(gracefullyKillOperations)]) {
		if ([receiver gracefullyKillOperations]) {
			isJobRunning = NO;
			return YES;
		} else {
			return NO;
		}
	} else {
		return NO;
	}
}

- (int)ident
{
	return ident;
}

- (void)jobFinished:sender
{
	[[ISOJobMgr sharedJobMgr] jobFinished:self];
}

- (void)setFinished:(BOOL)flag
{
	finished = flag;
}

- (BOOL)isJobFinished
{
	return finished;
}

@end
