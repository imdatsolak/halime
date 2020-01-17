//
//  ISOPostingLoader.m
//  Halime
//
//  Created by iso on Mon Aug 20 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOPostingLoader.h"
#import "ISOPreferences.h"
#import "ISONewsServerMgr.h"
#import "ISOSubscriptionMgr.h"
#import "ISOJob.h"
#import "ISOLogger.h"

@implementation ISOPostingLoader
- initWithDelegate:(id)aDelegate groups:(NSArray *)groupsList andSpamFilter:(NSArray *)aList
{
    [super init];
    delegate = aDelegate;
    groups = groupsList;
    spamFilters = [NSMutableArray arrayWithArray:aList];
//    [aDelegate retain];
//    [groups retain];
    [spamFilters retain];
    maxNumberToLoad = 0;
	postingsLoaded = 0;
	loadedPostings = nil;
    aServerMgr = nil;
	workInProgress = NO;
	activeGroup = nil;
	gracefullyKilled = NO;
	loadTarget = nil;
	theJob = nil;
	postingBeingLoaded = nil;
	newPostingAlert = YES;
    return self;
}

- initWithDelegate:(id)aDelegate
{
    return [self initWithDelegate:aDelegate groups:nil andSpamFilter:nil];
}

- (void)loadPostings:(ISOSubscriptionMgr *)theSubscriptionMgr
{
    ISONewsGroup	*currentGroup;
    BOOL			groupOK;
    NSAutoreleasePool	*aPool;
	int				oldPostingCount;
	
	gracefullyKilled = NO;
	aPool = [[NSAutoreleasePool alloc] init];
	loadedPostings = nil;
	postingsLoaded = 0;
	workInProgress = YES;
    loadedPostings = [[NSMutableArray arrayWithCapacity:0] retain];
	if (activeGroup == nil) {
		currentGroup = [theSubscriptionMgr selectedGroup];
	} else {
		currentGroup = activeGroup;
	}
	oldPostingCount = [currentGroup postingCountFlat];
	if ((theSubscriptionMgr && [[theSubscriptionMgr theSubscription] usesGlobalSPAMFilter]) ||
		([currentGroup subscription] && [[currentGroup subscription] usesGlobalSPAMFilter]) ) {
		[spamFilters addObjectsFromArray:[[ISOPreferences sharedInstance] prefsGlobalSPAMFilters]];
	}
	if (currentGroup) {
		activeGroup = currentGroup;
		groupOK = YES;
		if (delegate && [delegate respondsToSelector:@selector(postingLoader:willBeginGroup:)]) {
			groupOK = [delegate postingLoader:self willBeginGroup:currentGroup];
		}
		if (groupOK) {
			[self loadGroup:currentGroup intoArray:loadedPostings withSubscriptionMgr:theSubscriptionMgr];
		}
	}
	workInProgress = NO;
	if (delegate && [delegate respondsToSelector:@selector(postingLoader:didFinishLoadingPostingHeaders:)]) {
		[delegate postingLoader:self didFinishLoadingPostingHeaders:YES];
	}
	if (loadTarget && [loadTarget respondsToSelector:loadAction]) {
		[loadTarget performSelector:loadAction withObject:self];
	}
	if (([currentGroup postingCountFlat] > oldPostingCount) && (newPostingAlert)) {
		if ([[ISOPreferences sharedInstance] prefsShouldNewPostingArrivedAlert]) {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISONewPostingArrivedAlertSound];
		}
	}
	if (!gracefullyKilled && theJob) {
		[theJob jobFinished:self];
	}
	activeGroup = nil;
	[spamFilters removeAllObjects];
	[aPool release];
    return ;
}

- (BOOL)completePostingHeaders:(ISONewsPosting *)aPosting
{
    id					oldDelegate;
    ISONewsGroup		*aGroup;
    BOOL				result;
    NSAutoreleasePool	*aPool;
	
	gracefullyKilled = NO;
	aPool = [[NSAutoreleasePool alloc] init];
	
    aGroup = [aPosting mainGroup];
	postingBeingLoaded = aPosting;
    result = NO;
    if (aGroup) {
		workInProgress = YES;
        aServerMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[[aGroup newsServer] serverName]];
        if (aServerMgr) {
			[aServerMgr setIsBeingUsed:YES];
            oldDelegate = [aServerMgr delegate];
            [aServerMgr setDelegate:self];
            [aServerMgr setSPAMFilter:spamFilters];
            if ([aServerMgr connect:self]) {
                result = [aServerMgr completePostingHeaders:aPosting];
                [aServerMgr disconnect:self];
            }
            [aServerMgr setDelegate:oldDelegate];
			[aServerMgr setIsBeingUsed:NO];
        }
    }
	if (loadTarget && [loadTarget respondsToSelector:loadAction]) {
		[loadTarget performSelector:loadAction withObject:self];
	}
	if (!gracefullyKilled && theJob) {
		[theJob jobFinished:self];
	}
	workInProgress = NO;
	postingBeingLoaded = nil;
	[aPool release];
    return result;
}

- (BOOL)loadPostingBody:(ISONewsPosting *)aPosting
{
    id					oldDelegate;
    ISONewsGroup		*aGroup;
    BOOL				result;
    NSAutoreleasePool	*aPool;
	
	gracefullyKilled = NO;
	aPool = [[NSAutoreleasePool alloc] init];
	
    aGroup = [aPosting mainGroup];
	postingBeingLoaded = aPosting;
    result = NO;
    if (aGroup && [aGroup newsServer] && [[aGroup newsServer] serverName]) {
		workInProgress = YES;
        aServerMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[[aGroup newsServer] serverName]];
        if (aServerMgr) {
			[aServerMgr setIsBeingUsed:YES];
            oldDelegate = [aServerMgr delegate];
            [aServerMgr setDelegate:self];
            [aServerMgr setSPAMFilter:spamFilters];
            if ([aServerMgr connect:self]) {
                result = [aServerMgr retrievePostingBody:aPosting];
                [aServerMgr disconnect:self];
            }
            [aServerMgr setDelegate:oldDelegate];
			[aServerMgr setIsBeingUsed:NO];
        }
    }
	if (loadTarget && [loadTarget respondsToSelector:loadAction]) {
		[loadTarget performSelector:loadAction withObject:self];
	}
	if (!gracefullyKilled && theJob) {
		[theJob jobFinished:self];
	}
	workInProgress = NO;
	postingBeingLoaded = nil;
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOPostingLoaded" object:aPosting]];
	[aPool release];
    return result;
}

- loadGroup:(ISONewsGroup *)aGroup intoArray:(NSMutableArray *)anArray withSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr
{
    id	oldDelegate;
    int	maxGroupsToLoad;
	
	if ([[ISOPreferences sharedInstance] prefsLimitHeadersDownloaded]) {
		maxGroupsToLoad = [[ISOPreferences sharedInstance] prefsNumberOfMaxHeadersToDownload];
	} else {
		maxGroupsToLoad = 0;
	}
	activeGroup = aGroup;
    aServerMgr = [[[ISOPreferences sharedInstance] newsServerMgrForServer:[[aGroup newsServer] serverName]] retain];
    if (aServerMgr) {
		[aServerMgr setIsBeingUsed:YES];
        oldDelegate = [aServerMgr delegate];
        [aServerMgr setDelegate:self];
        [aServerMgr setSPAMFilter:spamFilters];
        if ([aServerMgr connect:self]) {
            [aServerMgr retrieveHeadersForGroup:aGroup maximum:maxGroupsToLoad withSubscription:theSubscriptionMgr? [theSubscriptionMgr theSubscription]:[activeGroup subscription]];
            [aServerMgr disconnect:self];
			if (theSubscriptionMgr) {
				[theSubscriptionMgr subscriptionDataChanged];
			} else {
				[[activeGroup subscription] setSubscriptionEdited:YES];
			}
        }
		[aServerMgr setIsBeingUsed:NO];
        [aServerMgr release];
    }
    return self;
}

- (BOOL)loadOverviewFmtWithSubscriptionMgr:(ISOSubscriptionMgr *)theSubscriptionMgr andGroup:(ISONewsGroup *)aGroup
{
    NSArray		*overviewFmt;
    id			oldDelegate;
	BOOL		retval;
    
	retval = NO;
    aServerMgr = [[[ISOPreferences sharedInstance] newsServerMgrForServer:[[aGroup newsServer] serverName]] retain];
    if (aServerMgr) {
		[aServerMgr setIsBeingUsed:YES];
        oldDelegate = [aServerMgr delegate];
        [aServerMgr setDelegate:self];
        [aServerMgr setSPAMFilter:spamFilters];
        if ([aServerMgr connect:self]) {
            overviewFmt = [aServerMgr retrieveOverviewFmt];
			retval = [[theSubscriptionMgr theSubscription] setOverviewFmtFromArray:overviewFmt];
        }
		[aServerMgr setIsBeingUsed:NO];
        [aServerMgr release];
    }
    return retval;
}

- (void)setLoadTarget:(id)aTarget
{
	loadTarget = aTarget;
}


- (void)setLoadAction:(SEL)anAction
{
	loadAction = anAction;
}


- (BOOL)gracefullyKillOperations
{
	gracefullyKilled = YES;
	return YES;
}

- (void)setJob:(id)aJob
{
	theJob = aJob;
}

- (id)job
{
	return theJob;
}

- (void)dealloc
{
	[ISOActiveLogger logWithDebuglevel:20 :@"ISOPostingLoader dealloc'd"];
//    [delegate release];
//    [groups release];
	[spamFilters release];

    [super dealloc];
}

/* ISONewsServerMgr Delegate Methods */
- (int)newsServerMgr:(id)newsServerMgr readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
    if (delegate && [delegate respondsToSelector:@selector(postingLoader:readsPosting:atLine:)]) {
        return [delegate postingLoader:self readsPosting:aPosting atLine:aLine];
    } else {
        return 0;
    }
}

- (BOOL)newsServerMgr:(id)newsServerMgr willBeginGroup:(ISONewsGroup *)aGroup
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
    if (delegate && [delegate respondsToSelector:@selector(postingLoader:willBeginGroup:)]) {
        return [delegate postingLoader:self willBeginGroup:aGroup];
    } else {
        return YES;
    }
}

- (int)newsServerMgr:(id)newsServerMgr numberOfPostingsToLoad:(int)maxPostings inGroup:(ISONewsGroup *)aGroup
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
    if (delegate && [delegate respondsToSelector:@selector(postingLoader:numberOfPostingsToLoad:)]) {
        return [delegate postingLoader:self numberOfPostingsToLoad:maxPostings];
	} else {
        return maxPostings;
    }
}

- (BOOL)newsServerMgr:(id)newsServerMgr willReadPostingHeader:(ISONewsPosting *)aPosting
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
    return YES;
}

- (BOOL)newsServerMgr:(id)newsServerMgr didReadPostingHeader:(ISONewsPosting *)aPosting
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
	if (aPosting && activeGroup) {
		[activeGroup addPosting:aPosting];
	}
    if (delegate && [delegate respondsToSelector:@selector(postingLoader:didLoadPostingHeader:)]) {
        return [delegate postingLoader:self didLoadPostingHeader:aPosting];
    } else {
        return YES;
    }
}

- (BOOL)newsServerMgr:(id)newsServerMgr willReadPosting:(ISONewsPosting *)aPosting
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
    return YES;
}

- (BOOL)newsServerMgr:(id)newsServerMgr didReadPosting:(ISONewsPosting *)aPosting
{
	if (gracefullyKilled) {
		[newsServerMgr gracefullyKillOperations];
	}
     if (delegate && [delegate respondsToSelector:@selector(postingLoader:didLoadPosting:)]) {
        return [delegate postingLoader:self didLoadPosting:aPosting];
    } else {
        return YES;
    }
   return YES;
}

/* ...................
*/
- (int)numberOfPostingHeadersLoadedSoFar
{
	return postingsLoaded;
}

- (ISONewsPosting *)postingHeaderAtIndex:(int)index
{
	if (index >= [loadedPostings count]) {
		return [aServerMgr postingHeaderAtIndex:index - [loadedPostings count]];
	} else {
		return [loadedPostings objectAtIndex:index];
	}
}

- (BOOL)isWorkInProgress
{
	return workInProgress;
}

- (id)postingBeingLoaded
{
	return postingBeingLoaded;
}

- (void)setActiveGroup:(ISONewsGroup *)aGroup
{
	activeGroup = aGroup;
}

- (ISONewsGroup *)activeGroup
{
	return activeGroup;
}

- (void)setNewPostingAlert:(BOOL)flag
{
	newPostingAlert = flag;
}
@end
