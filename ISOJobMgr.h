//
//  ISOJobMgr.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 19 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISOSubscriptionMgr.h"
#import "ISOJobViewMgr.h"
#import "ISOJob.h"

@interface ISOJobMgr : NSObject 
{
	NSMutableArray	*jobs;
	ISOJobViewMgr	*jobViewMgr;
	int	maxNumberOfParallelConnectionJobs;
	int maxNumberOfParallelNormalJobs;
	NSLock	*mutex;
	BOOL	stateChanged;
	int		runningNormalJobs;
	int		runningConnectionJobs;
	BOOL	isOffline;
}

+ (id)sharedJobMgr;
- (id)init;
- (void)dealloc;

- (BOOL)detachAsSeparateThread;

- (void)setMaxNumberOfParallelConnectionJobs:(int)maxNumber;
- (void)setMaxNumberOfParallelNormalJobs:(int)maxNumber;

- (int)addJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject isConnectionJob:(BOOL)connectionJob isDisconnectionJob:(BOOL)disconnectionJob forOwner:(id)anOwner;
- (int)addConnectionJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner;
- (int)addNormalJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner;
- (int)addDisconnectionJob:(NSString *)jobname forSubscriptionMgr:(ISOSubscriptionMgr *)aSubscriptionMgr withSelector:(SEL)selector receiver:(id<ISOJobReceiverProtocol>)receiver userObject:(id)userObject forOwner:(id)anOwner;

- (BOOL)removeJobWithIdent:(int)ident;
- (BOOL)cancelJobWithIdent:(int)ident;
- (BOOL)moveUpJobWithIdent:(int)ident;
- (BOOL)moveDownJobWithIdent:(int)ident;
- (BOOL)startJobWithIdent:(int)ident;
- (void)jobFinished:(ISOJob *)aJob;
- (BOOL)jobWithReceiverIsFinished:(id)aJobReceiver;
- (int)identOfJobAtIndex:(int)index;
- (int)numberOfJobs;
- (id)jobAtIndex:(int)index;
- (int)indexOfJob:(ISOJob *)aJob;
- (ISOJobViewMgr *)newJobViewMgr;
- (BOOL)closeJobViewMgr:(ISOJobViewMgr *)aJobViewMgr;
- (void)removeJobsOfOwner:(id)anOwner;

- (void)setIsOffline:(BOOL)flag;
- (BOOL)isOffline;

- (BOOL)tryLock;
- (void)unlock;
@end

