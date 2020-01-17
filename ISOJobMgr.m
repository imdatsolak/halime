//
//  ISOJobMgr.m
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOJobMgr.h"
#import "ISOJob.h"
#import "ISOJobViewMgr.h"
#import "ISOLogger.h"

@implementation ISOJobMgr
static id sharedJobMgr = nil;

+ (id)sharedJobMgr
{
	if (sharedJobMgr == nil) {
		sharedJobMgr = [[ISOJobMgr alloc] init];
	}
	return sharedJobMgr;
}

- (id)init
{
	[super init];
	jobs = [[NSMutableArray array] retain];
	jobViewMgr = nil;
	maxNumberOfParallelConnectionJobs = 2;
	maxNumberOfParallelNormalJobs = 4;
	mutex = [[NSLock alloc] init];
	stateChanged = NO;
	runningNormalJobs = 0;
	runningConnectionJobs = 0;
	isOffline = NO;
	return self;
}

- (void)dealloc
{
	[mutex unlock];
	[mutex release];
	[jobs release];
	[jobViewMgr release];
	[super dealloc];
}

- (id)_nextNonRunningNonConnectionJob
{
	int		i, count;
	ISOJob	*aJob;
	
	count = [jobs count];
	for (i=0;i<count;i++) {
		aJob = [jobs objectAtIndex:i];
		if (![aJob isConnectionJob] && ![aJob isJobRunning]) {
			return aJob;
		}
	}
	return nil;
}

- (id)_nextNonRunningConnectionJob
{
	int		i, count;
	ISOJob	*aJob;
	
	count = [jobs count];
	for (i=0;i<count;i++) {
		aJob = [jobs objectAtIndex:i];
		if ([aJob isConnectionJob] && ![aJob isJobRunning]) {
			return aJob;
		}
	}
	return nil;
}

- (BOOL)startNextNCJob
{
	BOOL	retval = NO;
	if ([jobs count]) {
		if (maxNumberOfParallelNormalJobs > runningNormalJobs) {
			ISOJob *aJob = [self _nextNonRunningNonConnectionJob];
			if (aJob && ![aJob isJobFinished]) {
				if ([aJob startJob]) {
					runningNormalJobs++;
					retval = YES;
				}
			} else if (aJob && [aJob isJobFinished]) {
				stateChanged = YES;
			}
		}
	}
	return NO;
}

- (BOOL)startNextCJob
{
	BOOL	retval = NO;
	if ([jobs count]) {
		if ((!isOffline) && (maxNumberOfParallelConnectionJobs > runningConnectionJobs)) {
			ISOJob *aJob = [self _nextNonRunningConnectionJob];
			if (aJob && ![aJob isJobFinished]) {
				if ([aJob startJob]) {
					runningConnectionJobs++;
					retval = YES;
				}
			} else if (aJob && [aJob isJobFinished]) {
				stateChanged = YES;
			}
		}
	}
	return retval;
}

- (void)reflectJobChanges
{
	[jobViewMgr reflectJobChanges];
}


- (void)doTheVWBeagle		// und er lŠuft und lŠuft und lŠuft und lŠuft...
{
	BOOL				changed;
	NSAutoreleasePool	*autoreleasePool;
	int	jobIndex;
	int jobCount, i;

	autoreleasePool = [[NSAutoreleasePool alloc] init];
	while (1) {
		if (stateChanged) {
			if ([mutex tryLock]) {
				changed = NO;
				stateChanged = NO;
				jobCount = [jobs count];
				for (i=jobCount-1;i>=0;i--) {
					ISOJob	*aJob = [jobs objectAtIndex:i];
					if ([aJob isJobFinished]) {
						if ([aJob isConnectionJob]) {
							runningConnectionJobs--;
							if (runningConnectionJobs <0) {
								runningConnectionJobs = 0;
							}
						} else {
							runningNormalJobs--;
							if (runningNormalJobs <0) {
								runningNormalJobs = 0;
							}
						}
						jobIndex = [self indexOfJob:aJob];
						[jobs removeObject:aJob];
						if (jobIndex >= 0) {
							[[ISOJobViewMgr sharedJobViewMgr] cleanUpJobAtIndex:jobIndex];
						}
						[aJob release];
//						[aJob dealloc];
					}
				}
				changed = [self startNextNCJob];
				changed = changed || [self startNextCJob];
				[mutex unlock];
			}
			[self reflectJobChanges];
		}
		sleep(1);
	}
	[autoreleasePool release];
}

- (BOOL)detachAsSeparateThread
{
	[NSThread detachNewThreadSelector:@selector(doTheVWBeagle) toTarget:self withObject:nil];
	return YES;
}

- (void)setMaxNumberOfParallelConnectionJobs:(int)maxNumber
{
	[mutex lock];
	maxNumberOfParallelConnectionJobs = maxNumber;
	stateChanged = YES;
	[mutex unlock];
}

- (void)setMaxNumberOfParallelNormalJobs:(int)maxNumber
{
	[mutex lock];
	maxNumberOfParallelNormalJobs = maxNumber;
	stateChanged = YES;
	[mutex unlock];
}

- (int)addJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject isConnectionJob:(BOOL)connectionJob isDisconnectionJob:(BOOL)disconnectionJob forOwner:(id)anOwner
{
	int		ident = -1;
	ISOJob	*theJob;
	
	[mutex lock];
	ident = [jobs count];
	theJob = [[ISOJob alloc] initWithJobname:jobname
				subscriptionMgr:aSubscriptionMgr
				selector:selector
				receiver:receiver
				userObject:userObject
				connection:connectionJob
				disconnection:disconnectionJob
				andIdent:ident owner:anOwner];
				
	[jobs addObject:theJob];
	stateChanged = YES;
	if (connectionJob) {
		[self startNextCJob];
	} else {
		[self startNextNCJob];
	}
	[mutex unlock];
//	[self reflectJobChanges];
	return ident;
}

- (int)addConnectionJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner
{
	return [self addJob:jobname
				forSubscriptionMgr:aSubscriptionMgr
				withSelector:selector
				receiver:receiver
				userObject:userObject
				isConnectionJob:YES
				isDisconnectionJob:NO
				forOwner:anOwner];
}

- (int)addNormalJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner
{
	return [self addJob:jobname
				forSubscriptionMgr:aSubscriptionMgr
				withSelector:selector
				receiver:receiver
				userObject:userObject
				isConnectionJob:NO
				isDisconnectionJob:NO
				forOwner:anOwner];
}

- (int)addDisconnectionJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner
{
	return [self addJob:[NSString stringWithFormat:@"#%@", jobname]
				forSubscriptionMgr:aSubscriptionMgr
				withSelector:selector
				receiver:receiver
				userObject:userObject
				isConnectionJob:NO
				isDisconnectionJob:YES
				forOwner:anOwner];
}

- (id)_jobWithIdent:(int)ident
{
	int		i, count;
	
	i = 0;
	count = [jobs count];
	while (i<count) {
		if ([[jobs objectAtIndex:i] ident] == ident) {
			return [jobs objectAtIndex:i];
		}
		i++;
	}
	return nil;
}

- (BOOL)removeJobWithIdent:(int)ident
{
	BOOL result = NO;
	ISOJob	*aJob;
	
	[mutex lock];
	aJob = [self _jobWithIdent:ident];
		
	if (aJob) {
		if ([aJob isJobRunning]) {
			if ([aJob stopJob]) {
//				[[ISOJobViewMgr sharedJobViewMgr] cleanUpJobAtIndex:[self indexOfJob:aJob]];
//				[jobs removeObject:aJob];
//				[aJob release];
				result = YES;
			}
		} else {
//			[[ISOJobViewMgr sharedJobViewMgr] cleanUpJobAtIndex:[self indexOfJob:aJob]];
//			[jobs removeObject:aJob];
//			[aJob release];
			result = YES;
		}
		[aJob setFinished:YES];
		stateChanged = YES;
	}
	[mutex unlock];
//	[self reflectJobChanges];
	return result;
}
		
- (BOOL)cancelJobWithIdent:(int)ident
{
	return [self removeJobWithIdent:ident];
}

- (BOOL)moveUpJobWithIdent:(int)ident
{
	return YES;
}

- (BOOL)moveDownJobWithIdent:(int)ident
{
	return YES;
}

- (BOOL)startJobWithIdent:(int)ident
{
	ISOJob	*aJob;
	BOOL	retval = NO;
	
	[mutex lock];
	aJob = [self _jobWithIdent:ident];
	if (![aJob isJobRunning]) {
		retval = [aJob startJob];
	}
	[mutex unlock];
	return retval;
}

- (void)jobFinished:(ISOJob *)aJob
{
	[mutex lock];
	[aJob setFinished:YES];
	stateChanged = YES;
	[mutex unlock];
}

- (BOOL)jobWithReceiverIsFinished:(id)aJobReceiver
{
	ISOJob	*aJob = nil;
	int		i, count;
	BOOL	found = NO;
	
	[mutex lock];
	count = [jobs count];
	i = 0;
	while (i<count && !found) {
		aJob = [jobs objectAtIndex:i];
		if ([aJob receiver] == aJobReceiver) {
			found = YES;
		}
		i++;
	}
	if (found) {
		[aJob setFinished:YES];
	}
	[mutex unlock];
	return found;
}

- (int)identOfJobAtIndex:(int)index
{
	if (index >= 0 && (index < [jobs count])) {
		return [[jobs objectAtIndex:index] ident];
	} else {
		return -1;
	}
}

- (int)indexOfJob:(ISOJob *)aJob
{
	if ([jobs containsObject:aJob]) {
		return [jobs indexOfObject:aJob];
	} else {
		return -1;
	}
}	

- (int)numberOfJobs
{
	return [jobs count];
}

- (id)jobAtIndex:(int)index
{
	if (index >= 0 && (index < [jobs count])) {
		return [jobs objectAtIndex:index];
	} else {
		return nil;
	}
}

- (ISOJobViewMgr *)newJobViewMgr
{
	if (!jobViewMgr) {
		jobViewMgr = [[ISOJobViewMgr alloc] init];
	}
	return jobViewMgr;
}

- (BOOL)closeJobViewMgr:(ISOJobViewMgr *)aJobViewMgr
{
	return YES;
}

- (void)removeJobsOfOwner:(id)anOwner
{
	int	i, count;
	
	[mutex lock];
	count = [jobs count];
	for (i=count-1; i>=0; i--) {
		ISOJob	*aJob = [jobs objectAtIndex:i];
		if ([aJob owner] == anOwner) {
			if ([aJob isJobRunning]) {
				if ([aJob stopJob]) {
//					[[ISOJobViewMgr sharedJobViewMgr] cleanUpJobAtIndex:[self indexOfJob:aJob]];
//					[jobs removeObject:aJob];
//					[aJob release];
				}
			} else {
//				[[ISOJobViewMgr sharedJobViewMgr] cleanUpJobAtIndex:[self indexOfJob:aJob]];
//				[jobs removeObject:aJob];
//				[aJob release];
			}
			[aJob setFinished:YES];
			stateChanged = YES;
		}
	}
	[mutex unlock];
}


- (void)setIsOffline:(BOOL)flag
{
	[mutex lock];
	isOffline = flag;
	[mutex unlock];
}

- (BOOL)isOffline
{
	return isOffline;
}

- (BOOL)tryLock
{
	return [mutex tryLock];
}

- (void)unlock
{
	[mutex unlock];
}

@end
