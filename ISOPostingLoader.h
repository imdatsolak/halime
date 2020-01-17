//
//  ISOPostingLoader.h
//  Halime
//
//  Created by iso on Mon Aug 20 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISONewsPosting.h"
#import "ISONewsServerMgr.h"
#import "ISONewsGroup.h"
#import "ISOJob.h"

@interface ISOPostingLoader : NSObject <ISOJobReceiverProtocol>
{
	NSArray				*groups;
	NSMutableArray		*spamFilters;
    id					delegate;
    int					maxNumberToLoad;
    BOOL				cancelled;
	int					postingsLoaded;
	NSMutableArray		*loadedPostings;
	ISONewsServerMgr	*aServerMgr;
	BOOL				workInProgress;
	ISONewsGroup		*activeGroup;
	id					theJob;
	BOOL				gracefullyKilled;
	
	id					loadTarget;
	SEL					loadAction;
	id					postingBeingLoaded;
	BOOL				newPostingAlert;
	
}

- initWithDelegate:(id)aDelegate groups:(NSArray *)groupsList andSpamFilter:(NSArray *)aList;
- initWithDelegate:(id)aDelegate;
- (void)loadPostings:(id)theSubscriptionMgr;
- (BOOL)completePostingHeaders:(ISONewsPosting *)aPosting;
- (BOOL)loadPostingBody:(ISONewsPosting *)aPosting;
- loadGroup:(ISONewsGroup *)aGroup intoArray:(NSMutableArray *)anArray withSubscriptionMgr:(id)theSubscriptionMgr;
- (void)setLoadTarget:(id)aTarget;
- (void)setLoadAction:(SEL)anAction;
- (void)dealloc;

/* ISONewsServerMgr Delegate Methods */
- (BOOL)newsServerMgr:(id)newsServerMgr willBeginGroup:(ISONewsGroup *)aGroup;
- (int)newsServerMgr:(id)newsServerMgr numberOfPostingsToLoad:(int)maxPostings inGroup:(ISONewsGroup *)aGroup;
- (BOOL)newsServerMgr:(id)newsServerMgr willReadPostingHeader:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr didReadPostingHeader:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr willReadPosting:(ISONewsPosting *)aPosting;
- (BOOL)newsServerMgr:(id)newsServerMgr didReadPosting:(ISONewsPosting *)aPosting;
- (int)newsServerMgr:(id)newsServerMgr readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine;

- (int)numberOfPostingHeadersLoadedSoFar;
- (ISONewsPosting *)postingHeaderAtIndex:(int)index;
- (BOOL)isWorkInProgress;
- (BOOL)loadOverviewFmtWithSubscriptionMgr:(id)theSubscriptionMgr andGroup:(id)aGroup;

- (BOOL)gracefullyKillOperations;
- (void)setJob:(id)aJob;
- (id)job;
- (id)postingBeingLoaded;
- (void)setActiveGroup:(ISONewsGroup *)aGroup;
- (ISONewsGroup *)activeGroup;
- (void)setNewPostingAlert:(BOOL)flag;
@end

@interface NSObject(ISOPostingLoaderDelegate)
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader willBeginGroup:(ISONewsGroup *)aGroup;
- (int)postingLoader:(ISOPostingLoader *)aPostingLoader numberOfPostingsToLoad:(int)maxPostings;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader willLoadPostingHeader:(ISONewsPosting *)aPosting;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPostingHeader:(ISONewsPosting *)aPosting;
- (void)postingLoader:(ISOPostingLoader *)aPostingLoader didFinishLoadingPostingHeaders:(BOOL)flag;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader willLoadPosting:(ISONewsPosting *)aPosting;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPosting:(ISONewsPosting *)aPosting;
- (int)postingLoader:(ISOPostingLoader *)aPostingLoader readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine;
@end