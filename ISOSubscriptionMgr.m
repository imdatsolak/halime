//
//  ISOSubscriptionMgr.m
//  Halime
//
//  Created by iso on Thu Apr 26 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOSubscriptionMgr.h"
#import "ISOBeep.h"
#import "ISOPreferences.h"
#import "ISOJobViewMgr.h"
#import "ISOJobViewCell.h"
#import "ISOJobMgr.h"
#import "ISOSPAMFilterMgr.h"
#import "ISOOfflineMgr.h"
#import "ISOViewOptionsMgr.h"
#import "ISOLogger.h"
#import "EncodingPopupMaker.h"
#import "ISOSplitPostingWindowMgr.h"
#import "NSPopUpButton_Extensions.h"

#define MAC_ISOHalimeDocToolbarIdentifier	@"ISOHalimeDocToolbarIdentifier"
#define MAC_NEWPOSTING		@"NewPosting"
#define MAC_FOLLOWUP		@"FollowUp"
#define MAC_REPLY			@"ReplyToSender"
#define MAC_MARKAS			@"MarkAs"
#define MAC_CHECKNEW		@"CheckForNewPostings"
#define MAC_REMOVEREAD		@"RemoveReadPostings"
#define MAC_CATCHUP			@"CatchUp"
#define MAC_SAVESELECTED	@"SaveSelectedMessages"
#define MAC_AUTOEXTRACT		@"AutoExtractBinaries"
#define MAC_FORWARD			@"ForwardAsMail"
#define MAC_FILTERFRIENDS	@"FilterForFriends"
#define MAC_FILTERSUBJECTS	@"FilterForSubjects"
#define MAC_ADDGROUPS		@"AddRemoveGroups"
#define MAC_SHOWHIDEDRAWER	@"ShowHideDrawer"
#define MAC_GOONOFFLINE		@"GoOnOrOffline"
#define MAC_ADDTOOFFLINE	@"AddToOfflineMgr"
#define MAC_FOCUSONTHREAD	@"FocusUnfocusOnThread"
#define MAC_DISPLAYFLAT		@"DisplayFlatOrThreaded"
#define MAC_FILTERFRIENDS	@"FilterForFriends"
#define MAC_FILTERSUBJECTS	@"FilterForSubjects"
#define MAC_REMOVEITEMS		@"RemoveItems"
#define MAC_HIDEREAD		@"HideShowRead"
#define MAC_ENCODING		@"CharacterEncoding"
#define MAC_GROUPS			@"Groups"
#define MAC_FILTERVIEW		@"FilterView"
#define MAC_SHOWHIDETABS	@"ShowHideTabs"
#define MAC_SHOWHIDEGTV		@"ShowHideGTV"

@implementation ISOSubscriptionMgr
- init
{
	self = [super init];
    theSubscription = [[ISOSubscription alloc] initNew];
	updateTimer = nil;
	followUpsArrivedOnLastCheck = 0;
	followUpsArrived = [[NSMutableArray array] retain];
	groupsBeingLoaded = [[NSMutableArray array] retain];
	selectedEncoding = MAC_ISOUNKNOWNENCODINGINT;
	groupsPopupButton = nil;
	saveInSeparateThread = YES;
	runningInSeparateThread = NO;
    return self;
}

- initFromFile:(NSString *)filename
{
	self = [super init];
    if (![self readFromFile:filename ofType:nil]) {
        [self dealloc];
        return nil;
    } else {
		return self;
	}
}

- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType
{
	return [super initWithContentsOfFile:fileName ofType:docType];
}
	 
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
    ISOSubscription *aSubscription = [[ISOSubscription alloc] initFromFile:fileName];
	
    if (aSubscription) {
        [theSubscription release];
        theSubscription = aSubscription;
        return YES;
    } else {
        return NO;
    }
}

- (void)dealloc
{
	[ISOActiveLogger logWithDebuglevel:1 :@"ISOSubscriptionMgr dealloc called"];
	if (updateTimer) {
		if ([updateTimer isValid]) {
			[updateTimer invalidate];
		}
	}
	[theSubscription release];
	[subscriptionWindowMgr release];
	[splitPostingWindowMgr release];
	[followUpsArrived release];
	[groupsBeingLoaded release];
    [super dealloc];
}

- (BOOL)isDocumentEdited
{
    return [theSubscription isSubscriptionEdited];
}
/*
- (IBAction)saveDocument:(id)sender
{
	if (saveInSeparateThread && !runningInSeparateThread) {
		runningInSeparateThread = YES;
		[NSThread detachNewThreadSelector:@selector(saveDocument:) toTarget:super withObject:sender];
	} else {
		[super saveDocument:sender];
		runningInSeparateThread = NO;
	}
}
*/
- (BOOL)writeToFile:(NSString *)fileName ofType:(NSString *)type
{
    [theSubscription setSubscriptionPath:fileName];
	if ([theSubscription saveSubscription]) {
		[self subscriptionDataSaved];
		return YES;
	} else {
		return NO;
	}
}

- (ISOSubscription *)theSubscription
{
	return theSubscription;
}

- (void)makeWindowControllers
{
    subscriptionWindowMgr = [[[ISOSubscriptionWindowMgr alloc] initWithWindowNibName:@"ISOSubscriptionWindow"] setSubscriptionMgr:self];
    [self addWindowController:subscriptionWindowMgr];
	[subscriptionWindowMgr setShouldCloseDocument:YES];
	splitPostingWindowMgr = [[[ISOSplitPostingWindowMgr alloc] initWithWindowNibName:@"ISOSplitPostingWindow"] setSubscriptionMgr:self];
    [self addWindowController:splitPostingWindowMgr];
	[self setupToolbar];
}

- (void)unhideWindow
{
	[subscriptionWindowMgr unhideWindow];
}

- (void)showWindows
{
	[subscriptionWindowMgr showWindow:self];
	if ([[ISOPreferences sharedInstance] prefsAutoCheckSubscription] && ![[ISOPreferences sharedInstance] isOffline]) {
		[self autocheckForNewPostings];
	}
	updateTimer = nil;
}

/* Own Classes */
- (void)subscriptionChanged:sender
{
    if (sender != subscriptionWindowMgr) {
        [subscriptionWindowMgr subscriptionChanged:sender];
    }
	[self subscriptionDataChanged];
}

- subscriptionDataChanged
{
	[theSubscription setSubscriptionEdited:YES];
	[subscriptionWindowMgr setSubscriptionEdited:YES];
	return self;
}

- subscriptionDataSaved
{
	[theSubscription setSubscriptionEdited:NO];
	[subscriptionWindowMgr setSubscriptionEdited:NO];
	return self;
}

/* Posting Stuff */
- (void)newPosting
{
	[[[ISOPostingWindowMgr alloc] initNewPostingInGroup:[subscriptionWindowMgr activeGroup]] showWindow];
}

- (void)followUp
{
	if ([subscriptionWindowMgr activePosting]) {
		NSString *selectionString = [subscriptionWindowMgr selectedBodyPart];
		if (selectionString) {
			[[[ISOPostingWindowMgr alloc] initFollowUpTo:[subscriptionWindowMgr activePosting] inGroup:[subscriptionWindowMgr activeGroup] selectionText:selectionString] showWindow];
		} else {
			[[[ISOPostingWindowMgr alloc] initFollowUpTo:[subscriptionWindowMgr activePosting] inGroup:[subscriptionWindowMgr activeGroup]] showWindow];
		}
	} else {
		[ISOBeep beep:@"No Posting selected to Follow up..."];
	}
}

- (void)replyAuthor
{
	if ([subscriptionWindowMgr activePosting]) {
		NSString *selectionString = [subscriptionWindowMgr selectedBodyPart];
		if (selectionString) {
			[[[ISOPostingWindowMgr alloc] initReplyTo:[subscriptionWindowMgr activePosting] inGroup:[subscriptionWindowMgr activeGroup] selectionText:selectionString] showWindow];
		} else {
			[[[ISOPostingWindowMgr alloc] initReplyTo:[subscriptionWindowMgr activePosting] inGroup:[subscriptionWindowMgr activeGroup]] showWindow];
		}
	} else {
		[ISOBeep beep:@"No Posting selected to Reply To..."];
	}
}

- (void)forward
{
	[ISOBeep beep:@"'Forward' not yet implemented!"];
}

- (void)markPostingRead
{
	[subscriptionWindowMgr markSelectedPostingRead];
}

- (void)markPostingUnread
{
	[subscriptionWindowMgr markSelectedPostingUnread];
}

- (void)addSenderToFriends
{
	[subscriptionWindowMgr addSenderToFriendsList:self];
}

- (void)addSubjectToFavorites
{
	[subscriptionWindowMgr addSubjectToFavorites:self];
}

- (void)markThreadRead
{
	[subscriptionWindowMgr markThreadRead];
}

- (void)markThreadUnread
{
	[subscriptionWindowMgr markThreadUnread];
}

/* SUBSCRIPTION SPECIFIC MENUS */
- (void)markGroupRead
{
	[subscriptionWindowMgr markGroupRead];
}

- (void)markGroupUnread
{
	[subscriptionWindowMgr markGroupUnread];
}


- (void)markSubscriptionRead
{
	[subscriptionWindowMgr markSubscriptionRead];
}

- (void)markSubscriptionUnread
{
	[subscriptionWindowMgr markSubscriptionUnread];
}

- (void)finishedLoadingPostingHeaders:(id)sender
{
	NSSound			*aSound = nil;
	ISONewsGroup	*activeGroup = [sender activeGroup];
	
	if ([[ISOPreferences sharedInstance] prefsReloadParentPosting]) {
		[activeGroup checkForParentPostings];
	}
	[activeGroup reApplyFilters];
	if (activeGroup == [subscriptionWindowMgr activeGroup]) {
		[subscriptionWindowMgr reSortArticles];
		if (![[ISOPreferences sharedInstance] prefsCheckForAllGroups]) {
			[subscriptionWindowMgr _updatePostingDisplay];
		} else {
			[subscriptionWindowMgr setNeedsDisplayRefresh:YES];
		}
	}
	if ((followUpsArrivedOnLastCheck>0) && [[ISOPreferences sharedInstance] prefsAlertOnFollowUp]) {
		if (([[ISOPreferences sharedInstance] prefsAlertOnFollowUpWithSound]) || (activeGroup != [subscriptionWindowMgr activeGroup])) {
			NSString *soundName = [[ISOPreferences sharedInstance] prefsFollowUpAlertSound];
			if (soundName && [soundName length]) {
				aSound = [[NSSound alloc] initWithContentsOfFile:soundName byReference:YES];
			}
			if (!aSound) {
				NSBeep();
			} else {
				[aSound setDelegate:self];
				if (![aSound play]) {
					NSBeep();
				}
			}
			if ([[NSApplication sharedApplication] isHidden]) {
				[[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
			}
		} else {
			NSString	*msg;
			int			retval;
			if (followUpsArrivedOnLastCheck == 1) {
				msg = NSLocalizedString(@"In the last batch fetched from the news server there was at least one follow-up to one of your postings. This follow-up is shown in a different color in the list of the postings.", @"");
			} else {
				msg = NSLocalizedString(@"In the last batch fetched from the news server there were %d follow-ups to at least one of your postings. This follow-ups are shown in a different color in the list of the postings.", @"");
			}
			retval = NSRunAlertPanel(NSLocalizedString(@"New Follow-Ups arrived", @""),
				msg,
				NSLocalizedString(@"OK", @""),
				NSLocalizedString(@"Show Follow-Ups", @""),
				nil, followUpsArrivedOnLastCheck);
			if (retval == NSAlertAlternateReturn) {
				[subscriptionWindowMgr expandAndShowItems:followUpsArrived];
			}
		}
	}
	[followUpsArrived removeAllObjects];
	followUpsArrivedOnLastCheck = 0;
	[groupsBeingLoaded removeObject:activeGroup];
}

- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPostingHeader:(ISONewsPosting *)aPosting
{
	ISOJobViewMgr	*aMgr;
	ISOJobViewCell	*pi = nil;
	ISOJob			*currentJob;

	currentJob = [aPostingLoader job];
	aMgr = [ISOJobViewMgr sharedJobViewMgr];
	NS_DURING
		pi = [aMgr progressIndicatorForJob:currentJob];
	NS_HANDLER
		NSLog(@"What the fuck is going wrong here?");
		Debugger();
	NS_ENDHANDLER
	if (pi) {
		[pi setIndeterminate:YES];
		[pi animate:self];
	}
	if ([aPosting isAFollowUp]) {
		[followUpsArrived addObject:aPosting];
		followUpsArrivedOnLastCheck++;
	}
    return YES;
}


- (void)scheduleCheckAllGroups
{
	if ([groupsBeingLoaded count] > 0) {
		return;
	} else if (![[ISOPreferences sharedInstance] isOffline]) {
		int i, count;
		NSArray	*groups = [theSubscription groups];
		
		[followUpsArrived removeAllObjects];
		followUpsArrivedOnLastCheck = 0;
		count = [groups count];
		[[ISOJobViewMgr sharedJobViewMgr] automaticShow];
		for (i=0;i<count;i++) {
			ISONewsGroup 		*aGroup = [groups objectAtIndex:i];
			ISOPostingLoader	*postingHeaderLoader;
			
			if (aGroup) {
				[groupsBeingLoaded addObject:aGroup];
			}
			postingHeaderLoader = [[ISOPostingLoader alloc] initWithDelegate:self
								groups:groups
								andSpamFilter:[theSubscription filters]];
			[postingHeaderLoader autorelease];
			if ([theSubscription overviewFmtIsLoaded] || [postingHeaderLoader loadOverviewFmtWithSubscriptionMgr:self andGroup:aGroup]) {
				[aGroup setDisplayView:nil];
				[aGroup setDisplayWhileLoading:NO];
				[postingHeaderLoader setLoadTarget:self];
				[postingHeaderLoader setLoadAction:@selector(finishedLoadingPostingHeaders:)];
				[postingHeaderLoader setActiveGroup:aGroup];
				[[ISOJobMgr sharedJobMgr]
					addConnectionJob:[NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"LH", @""), [aGroup abbreviatedGroupName]]
					forSubscriptionMgr:self
					withSelector:@selector(loadPostings:)
					receiver:postingHeaderLoader
					userObject:self
					forOwner:self];
			}
		}
	}
}


- (void)autocheckForNewPostings
{
	if ([[ISOPreferences sharedInstance] prefsAutoCheckSubscription] && ![[ISOPreferences sharedInstance] isOffline]) {
		if ([[ISOPreferences sharedInstance] prefsCheckForAllGroups]) {
			[self scheduleCheckAllGroups];
		} else {
			[self checkForNewPostings];
		}
		updateTimer = [NSTimer scheduledTimerWithTimeInterval:[[ISOPreferences sharedInstance] prefsAutoCheckSubscriptionInterval] * 60 target:self selector:@selector(autocheckForNewPostings) userInfo:nil repeats:NO];
	} else {
		if (![[ISOPreferences sharedInstance] isOffline]) {
			[subscriptionWindowMgr checkForNewPostings];
		} else {
			[ISOBeep beep:@"You are offline. You need to go online to check for any new postings."];
		}
		updateTimer = nil;
	}
}

- (void)checkForNewPostings
{
/*
	if (updateTimer) {
		if ([updateTimer isValid]) {
			[updateTimer invalidate];
		}
		updateTimer = nil;
	}
*/
	if (![[ISOPreferences sharedInstance] isOffline]) {
		[subscriptionWindowMgr checkForNewPostings];
	} else {
		[ISOBeep beep:@"You are offline. You need to go online to check for any new postings."];
	}
}

- (void)filterForFavoriteSubjects
{
	[subscriptionWindowMgr filterForFavoriteSubjects];
}

- (void)manageFavoriteSubjects
{
	[subscriptionWindowMgr manageFavorites];
}

- (void)filterForFriends
{
	[subscriptionWindowMgr filterForFriends];
}

- (void)manageFriendsList
{
	[subscriptionWindowMgr manageFriends];
}

- (void)saveSelectedMessages
{
	[ISOBeep beep:@"'Save Selected Messages' not yet implemented!"];
}

- (void)extractBinariesOfSelection
{
	[subscriptionWindowMgr extractBinariesOfSelection];
}

- (void)removeAllInvalidArticles
{
	[subscriptionWindowMgr removeAllInvalidArticles];
}

- (void)removeReadArticles
{
	[subscriptionWindowMgr removeReadArticles];
}

- (void)catchUp
{
	[subscriptionWindowMgr catchUp];
}

- (void)catchUpSubscription
{
	[subscriptionWindowMgr catchUpSubscription];
}

- (void)showHideGroupsDrawer
{
	[subscriptionWindowMgr showHideGroupsDrawer];
}

- (void)showSPAMFilterList
{
	[subscriptionWindowMgr showSPAMFilterList];
}

- (void)addGroups
{
	[subscriptionWindowMgr addGroups];
}

- (void)showSearchPanel
{
	[subscriptionWindowMgr showSearchPanel];
}

- (void)searchNext
{
	[subscriptionWindowMgr searchNext];
}

- (void)searchPrevious
{
	[subscriptionWindowMgr searchPrevious];
}


- (void)subscriptionWindowWillClose
{
	if (updateTimer) {
		[updateTimer invalidate];
		updateTimer = nil;
	}
	[self removeWindowController:splitPostingWindowMgr];
	[splitPostingWindowMgr release];
	splitPostingWindowMgr = nil;
}

- (ISONewsGroup *)selectedGroup
{
	return [subscriptionWindowMgr selectedGroup];
}


- (BOOL)hasGroupSelected
{
	return ([self selectedGroup] != nil);
}

- (int)numberOfSelectedPostings
{
	return [subscriptionWindowMgr numberOfSelectedPostings];
}

- (BOOL)hasPostingSelected
{
	return [subscriptionWindowMgr isAnyPostingSelected];
}

- (void)expandThread
{
	[subscriptionWindowMgr expandThread];
}

- (void)collapseThread
{
	[subscriptionWindowMgr collapseThread];
}

- (void)expandAllThreads
{
	[subscriptionWindowMgr expandAllThreads];
}

- (void)collapsAllThreads
{
	[subscriptionWindowMgr collapsAllThreads];
}

- (void)expandThreadsSmart
{
	[subscriptionWindowMgr expandThreadsSmart];
}

- (void)killThread
{
	ISONewsPosting 	*aPosting = [subscriptionWindowMgr activePosting];
	ISONewsGroup	*aGroup = [subscriptionWindowMgr activeGroup];
	NSMutableDictionary	*aDict;
	
	aDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:K_SPAMREFERENCESMENU], @"SPAMFILTERWHAT",
				[NSNumber numberWithInt:K_SPAMCONTAINSOPERATOR], @"SPAMFILTEROPERATOR",
				[aPosting messageIDHeader], @"SPAMFILTERVALUE",
				[NSNumber numberWithInt:K_SPAMIGNOREACTION], @"SPAMFILTERACTION",
				nil];
	[theSubscription addFilter:aDict];
	
	[aGroup removeThread:aPosting];
	[subscriptionWindowMgr postingSelected];
	[subscriptionWindowMgr subscriptionChanged:self];
	// + we have to add a filter for it into the spam-filters
}

- (void)killParentThread
{
	ISONewsPosting 	*aPosting = [subscriptionWindowMgr activePosting];
	ISONewsGroup	*aGroup = [subscriptionWindowMgr activeGroup];
	ISONewsPosting	*highest = [aPosting highestParent];
	NSMutableDictionary	*aDict;
	
	aDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:K_SPAMREFERENCESMENU], @"SPAMFILTERWHAT",
				[NSNumber numberWithInt:K_SPAMCONTAINSOPERATOR], @"SPAMFILTEROPERATOR",
				[aPosting referencesHeader], @"SPAMFILTERVALUE",
				[NSNumber numberWithInt:K_SPAMIGNOREACTION], @"SPAMFILTERACTION",
				nil];
	[theSubscription addFilter:aDict];
	aDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:K_SPAMREFERENCESMENU], @"SPAMFILTERWHAT",
				[NSNumber numberWithInt:K_SPAMCONTAINSOPERATOR], @"SPAMFILTEROPERATOR",
				[highest messageIDHeader], @"SPAMFILTERVALUE",
				[NSNumber numberWithInt:K_SPAMIGNOREACTION], @"SPAMFILTERACTION",
				nil];
	[theSubscription addFilter:aDict];
	[aGroup removeThread:highest];
	[subscriptionWindowMgr postingSelected];
	[subscriptionWindowMgr subscriptionChanged:self];
}

- (void)removeFlagged
{
	[ISOBeep beep:@"'Remove Flagged' not yet implemented"];
}

- (BOOL)_addFlaggedToOfflineMgr
{
	int				i, count;
	NSArray			*allGroups;
	ISOOfflineMgr	*offlineMgr = [ISOOfflineMgr sharedOfflineMgr];
	BOOL			found = NO;
	
	allGroups = [theSubscription groups];
	count = [allGroups count];
	for (i=0;i<count;i++) {
		int		j, jCount;
		NSArray	*postingsFlat = [[allGroups objectAtIndex:i] postingsFlat];
		jCount = [postingsFlat count];
		for (j=0;j<jCount;j++) {
			if ([[postingsFlat objectAtIndex:j] isFlagged] && ![[postingsFlat objectAtIndex:j] isBodyLoaded]) {
				[offlineMgr addToDownloads:[postingsFlat objectAtIndex:j]];
				found = YES;
			}
		}
	}
	return found;
}

- (void)downloadFlagged
{
	ISOOfflineMgr	*offlineMgr = [ISOOfflineMgr sharedOfflineMgr];
	if ([self _addFlaggedToOfflineMgr]) {
		[offlineMgr setSPAMFilter:[theSubscription filters]];
		[offlineMgr showSendReceiveWindow];
	} else {
		[ISOBeep beep:@"You have not flagged any message in the current subscription to be downloaded. Please flag some messages and try again."];
	}
}

- (void)downloadFlaggedAndGoOffline
{
	ISOOfflineMgr	*offlineMgr = [ISOOfflineMgr sharedOfflineMgr];
	if ([self _addFlaggedToOfflineMgr]) {
		[offlineMgr setSPAMFilter:[theSubscription filters]];
		[offlineMgr showSendReceiveWindow];
		[offlineMgr sendReceiveAndGoOffline:self];
	} else {
		[ISOBeep beep:@"You have not flagged any message in the current subscription to be downloaded. Please flag some messages and try again."];
	}
}

- (void)flagSelection
{
    [subscriptionWindowMgr flagSelection];
}

- (void)unflagSelection
{
    [subscriptionWindowMgr unflagSelection];
}

- (void)removeSelection
{
    [subscriptionWindowMgr removeSelection];
}

- (void)addSelectionToDownloads
{
    [subscriptionWindowMgr addSelectionToDownloads];
}

- (void)toggleHideRead
{
    [subscriptionWindowMgr toggleHideRead];
}

- (void)toggleOffline
{
	BOOL	isOffline = [[ISOPreferences sharedInstance] isOffline];
	
	isOffline = !isOffline;
	[[ISOPreferences sharedInstance] setIsOffline:isOffline];
}

/* **************************** TOOLBAR SUPPORT ************************************* */
- (void)updateGroupsMenuInToolbarItem:(NSToolbarItem *)toolbarItem retainPopup:(BOOL)retainPopup
{
	NSArray			*groups = [theSubscription groups];
	int				i, count;
	NSPopUpButton	*aPopupButton;

	aPopupButton = [subscriptionWindowMgr groupsMenu];
	[aPopupButton removeAllItems];
	
	count = [groups count];
	for (i=0;i<count;i++) {
		[aPopupButton addItemWithTitle:NSLocalizedString([[groups objectAtIndex:i] groupName], @"")];
		[[aPopupButton lastItem] setTarget:self];
		[[aPopupButton lastItem] setAction:@selector(groupChanged:)];
		[[aPopupButton lastItem] setTag:i];
	}
	[aPopupButton setFont:[NSFont systemFontOfSize:11.0]];

	if (toolbarItem) {
		[toolbarItem setView:aPopupButton];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];
	}
	groupsPopupButton = [subscriptionWindowMgr groupsMenu];
}

- (void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: MAC_ISOHalimeDocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
	[[subscriptionWindowMgr window] setToolbar: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:MAC_NEWPOSTING, MAC_FOLLOWUP, MAC_REPLY, MAC_MARKAS, MAC_CHECKNEW,
						MAC_REMOVEREAD, MAC_CATCHUP, MAC_SAVESELECTED, MAC_AUTOEXTRACT, MAC_FORWARD,
						MAC_FILTERFRIENDS, MAC_FILTERSUBJECTS, MAC_ADDGROUPS, MAC_SHOWHIDEDRAWER, 
						MAC_GOONOFFLINE, MAC_ADDTOOFFLINE, MAC_FOCUSONTHREAD, MAC_DISPLAYFLAT, MAC_SHOWHIDEGTV,
						MAC_REMOVEITEMS, MAC_HIDEREAD, MAC_ENCODING, MAC_GROUPS, MAC_FILTERVIEW, MAC_SHOWHIDETABS,
						NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
						NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, 
						nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:MAC_NEWPOSTING, MAC_FOLLOWUP, MAC_MARKAS,
						NSToolbarSeparatorItemIdentifier, 
						MAC_SHOWHIDEDRAWER, MAC_CHECKNEW, MAC_REMOVEREAD, MAC_CATCHUP, MAC_HIDEREAD, nil];
}

- (void)_setToolbarItem:(NSToolbarItem *)anItem label:(NSString *)aLabel paletteLabel:(NSString *)paletteLabel toolTip:(NSString *)toolTip image:(NSString *)imageName target:(id)target action:(SEL)action
{
	[anItem setLabel: aLabel];
	[anItem setPaletteLabel: paletteLabel];
	[anItem setToolTip: toolTip];
	[anItem setImage: [NSImage imageNamed: imageName]];
	[anItem setTarget: target];
	[anItem setAction: action];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem	*toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	NSPopUpButton	*aPopupButton;
	
    if ([itemIdent isEqual: MAC_HIDEREAD]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Hide Read", @"")
				paletteLabel:NSLocalizedString(@"Hide Read", @"")
				toolTip: NSLocalizedString(@"Hide/Show read articles", @"")
				image:@"HideRead"
				target:self
				action:@selector(toggleHideRead)];
    } else if ([itemIdent isEqual: MAC_SHOWHIDETABS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Tabview Tabs", @"")
				paletteLabel:NSLocalizedString(@"Toggle Tabview Tabs", @"")
				toolTip: NSLocalizedString(@"Hide/Show the tabs of the tabview", @"")
				image:@"ShowHideTabs"
				target:self
				action:@selector(toggleTabviewTabs:)];
    } else if ([itemIdent isEqual: MAC_REMOVEITEMS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Remove Items", @"")
				paletteLabel:NSLocalizedString(@"Remove Items", @"")
				toolTip: NSLocalizedString(@"Remove/Delete selected items", @"")
				image:@"RemoveItems"
				target:self
				action:@selector(removeSelection)];
    } else if ([itemIdent isEqual: MAC_DISPLAYFLAT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Display Flat", @"")
				paletteLabel:NSLocalizedString(@"Display Flat", @"")
				toolTip: NSLocalizedString(@"Display posting list flat (non-threaded)", @"")
				image:@"DisplayFlat"
				target:self
				action:@selector(toggleThreadedDisplay)];
    } else if ([itemIdent isEqual: MAC_SHOWHIDEGTV]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Show GTV Drawer", @"")
				paletteLabel:NSLocalizedString(@"Show GTV Drawer", @"")
				toolTip: NSLocalizedString(@"Show Graphical Thread View (GTV) drawer", @"")
				image:@"ShowGTVDrawer"
				target:self
				action:@selector(toggleGraphicalTV)];
    } else if ([itemIdent isEqual: MAC_FOCUSONTHREAD]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Focus on Thread", @"")
				paletteLabel:NSLocalizedString(@"Focus on Thread", @"")
				toolTip: NSLocalizedString(@"Focus/Unfocus on thread (hide/show other postings)", @"")
				image:@"FocusOnThread"
				target:self
				action:@selector(toggleThreadFocus)];
    } else if ([itemIdent isEqual: MAC_ADDTOOFFLINE]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Add to Downloads", @"")
				paletteLabel:NSLocalizedString(@"Add to Downloads", @"")
				toolTip: NSLocalizedString(@"Add selection to downloads in offline manager", @"")
				image:@"AddToOffline"
				target:self
				action:@selector(addSelectionToDownloads)];
    } else if ([itemIdent isEqual: MAC_GOONOFFLINE]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Go Offline", @"")
				paletteLabel:NSLocalizedString(@"Go Offline", @"")
				toolTip: NSLocalizedString(@"Switch into offline mode", @"")
				image:@"GoOffline"
				target:self
				action:@selector(toggleOffline)];
    } else if ([itemIdent isEqual: MAC_NEWPOSTING]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"New Posting", @"")
				paletteLabel:NSLocalizedString(@"New Posting", @"")
				toolTip: NSLocalizedString(@"Create a new posting", @"")
				image:MAC_NEWPOSTING
				target:self
				action:@selector(newPosting)];
	} else if ([itemIdent isEqual: MAC_FOLLOWUP]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Follow Up", @"")
				paletteLabel:NSLocalizedString(@"Follow Up", @"")
				toolTip: NSLocalizedString(@"Follow Up/Answer a posting", @"")
				image:MAC_FOLLOWUP
				target:self
				action:@selector(followUp)];
	} else if ([itemIdent isEqual: MAC_REPLY]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Reply to Author", @"")
				paletteLabel:NSLocalizedString(@"Reply to Author", @"")
				toolTip: NSLocalizedString(@"Reply to author of the selected posting via e-mail", @"")
				image:MAC_REPLY
				target:self
				action:@selector(replyAuthor)];
	} else if ([itemIdent isEqual: MAC_CHECKNEW]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Check for New", @"")
				paletteLabel:NSLocalizedString(@"Check for New", @"")
				toolTip: NSLocalizedString(@"Check for new postings on the server(s)", @"")
				image:MAC_CHECKNEW
				target:self
				action:@selector(checkForNewPostings)];
	} else if ([itemIdent isEqual: MAC_REMOVEREAD]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Remove Read", @"")
				paletteLabel:NSLocalizedString(@"Remove Read", @"")
				toolTip: NSLocalizedString(@"Remove (delete) all read articles", @"")
				image:MAC_REMOVEREAD
				target:self
				action:@selector(removeReadArticles)];
	} else if ([itemIdent isEqual: MAC_CATCHUP]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Catch Up", @"")
				paletteLabel:NSLocalizedString(@"Catch Up", @"")
				toolTip: NSLocalizedString(@"Catch Up/Remove all articles", @"")
				image:MAC_CATCHUP
				target:self
				action:@selector(catchUp)];
	} else if ([itemIdent isEqual: MAC_SAVESELECTED]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Save Selected", @"")
				paletteLabel:NSLocalizedString(@"Save Selected", @"")
				toolTip: NSLocalizedString(@"Save selected article(s) to disc", @"")
				image:MAC_SAVESELECTED
				target:self
				action:@selector(saveSelectedMessages)];
	} else if ([itemIdent isEqual: MAC_AUTOEXTRACT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Extract Binaries", @"")
				paletteLabel:NSLocalizedString(@"Extract Binaries", @"")
				toolTip: NSLocalizedString(@"Extract all binaries of selected articles", @"")
				image:MAC_AUTOEXTRACT
				target:self
				action:@selector(extractBinariesOfSelection)];
	} else if ([itemIdent isEqual: MAC_FORWARD]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Forward", @"")
				paletteLabel:NSLocalizedString(@"Forward", @"")
				toolTip: NSLocalizedString(@"Forward selected posting via e-mail to somebody else", @"")
				image:MAC_FORWARD
				target:self
				action:@selector(forward)];
	} else if ([itemIdent isEqual: MAC_FILTERFRIENDS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Filter Friends", @"")
				paletteLabel:NSLocalizedString(@"Filter Friends", @"")
				toolTip: NSLocalizedString(@"Show only postings whose sender is in the friends list", @"")
				image:@"FilterForFriends"
				target:self
				action:@selector(filterForFriends)];
	} else if ([itemIdent isEqual: MAC_FILTERSUBJECTS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Filter Subjects", @"")
				paletteLabel:NSLocalizedString(@"Filter Subjects", @"")
				toolTip: NSLocalizedString(@"Show only postings whose subjects are in the favorite subjects list", @"")
				image:@"FilterForSubjects"
				target:self
				action:@selector(filterForFavoriteSubjects)];
	} else if ([itemIdent isEqual: MAC_ADDGROUPS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Add Groups", @"")
				paletteLabel:NSLocalizedString(@"Add Groups", @"")
				toolTip: NSLocalizedString(@"Add groups to the current subscription", @"")
				image:MAC_ADDGROUPS
				target:self
				action:@selector(addGroups)];
	} else if ([itemIdent isEqual: MAC_SHOWHIDEDRAWER]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Show Drawer", @"")
				paletteLabel:NSLocalizedString(@"Show/Hide Drawer", @"")
				toolTip: NSLocalizedString(@"Show/Hide groups drawer", @"")
				image:@"ShowDrawer"
				target:self
				action:@selector(showHideGroupsDrawer)];
	} else if ([itemIdent isEqual: MAC_MARKAS]) {
		aPopupButton = [subscriptionWindowMgr markMenu];
		[aPopupButton removeAllItems];
		[aPopupButton setTitle:NSLocalizedString(@"Mark", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Mark", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"As Read", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"As Unread", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Thread As Read", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Thread As Unread", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Group As Read", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Group As Unread", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Subscription As Read", @"")];
		[aPopupButton addItemWithTitle:NSLocalizedString(@"Subscription As Unread", @"")];
		[[aPopupButton itemAtIndex:1] setTarget:self];
		[[aPopupButton itemAtIndex:1] setAction:@selector(markPostingRead)];

		[[aPopupButton itemAtIndex:2] setTarget:self];
		[[aPopupButton itemAtIndex:2] setAction:@selector(markPostingUnread)];

		[[aPopupButton itemAtIndex:3] setTarget:self];
		[[aPopupButton itemAtIndex:3] setAction:@selector(markThreadRead)];

		[[aPopupButton itemAtIndex:4] setTarget:self];
		[[aPopupButton itemAtIndex:4] setAction:@selector(markThreadUnread)];

		[[aPopupButton itemAtIndex:5] setTarget:self];
		[[aPopupButton itemAtIndex:5] setAction:@selector(markGroupRead)];
		
		[[aPopupButton itemAtIndex:6] setTarget:self];
		[[aPopupButton itemAtIndex:6] setAction:@selector(markGroupUnread)];

		[[aPopupButton itemAtIndex:7] setTarget:self];
		[[aPopupButton itemAtIndex:7] setAction:@selector(markSubscriptionRead)];
		
		[[aPopupButton itemAtIndex:8] setTarget:self];
		[[aPopupButton itemAtIndex:8] setAction:@selector(markSubscriptionUnread)];

		[aPopupButton setAutoenablesItems:NO];
		[toolbarItem setView:aPopupButton];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([aPopupButton frame]),NSHeight([aPopupButton frame]))];

		[toolbarItem setLabel:NSLocalizedString(@"Mark as", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Mark as", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Mark selected posting(s) as read/unread", @"")];
	} else if ([itemIdent isEqual: MAC_ENCODING]) {
		aPopupButton = [subscriptionWindowMgr encodingMenu];
		[aPopupButton removeAllItems];

		MakeEncodingPopup (aPopupButton, self, @selector(encodingChanged:), YES);

		[toolbarItem setView:aPopupButton];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];

		[toolbarItem setLabel:NSLocalizedString(@"Encoding", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Encoding", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Force character encoding of the selected posting", @"")];
		[aPopupButton selectItemWithTag:[[ISOPreferences sharedInstance] prefsDefaultPostingEncoding]];
	} else if ([itemIdent isEqual: MAC_GROUPS]) {
		[self updateGroupsMenuInToolbarItem:toolbarItem retainPopup:willBeInserted];
		[toolbarItem setLabel:NSLocalizedString(@"Groups", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Groups", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Switch to another group", @"")];
	} else if ([itemIdent isEqual: MAC_FILTERVIEW]) {
		[toolbarItem setView:[subscriptionWindowMgr filterGroup]];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([[subscriptionWindowMgr filterGroup] frame]), NSHeight([[subscriptionWindowMgr filterGroup] frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([[subscriptionWindowMgr filterGroup] frame]), NSHeight([[subscriptionWindowMgr filterGroup] frame]))];
		[[subscriptionWindowMgr filterGroupField] setTarget:self];
		[[subscriptionWindowMgr filterGroupField] setAction:@selector(filterForToolbarSelection:)];
		[toolbarItem setLabel:NSLocalizedString(@"Filter", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Filter", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Filter for From: or Subject:", @"")];
	} else {
		toolbarItem = nil;
    }
    return toolbarItem;
/*
    } else if([itemIdent isEqual: SearchDocToolbarItemIdentifier]) {
	NSMenu *submenu = nil;
	NSMenuItem *submenuItem = nil, *menuFormRep = nil;
	
	// Set up the standard properties 
	[toolbarItem setLabel: @"Search"];
	[toolbarItem setPaletteLabel: @"Search"];
	[toolbarItem setToolTip: @"Search Your Document"];
	
	// Use a custom view, a text field, for the search item 
	[toolbarItem setView: searchFieldOutlet];
	[toolbarItem setMinSize:NSMakeSize(30, NSHeight([searchFieldOutlet frame]))];
	[toolbarItem setMaxSize:NSMakeSize(400,NSHeight([searchFieldOutlet frame]))];

	// By default, in text only mode, a custom items label will be shown as disabled text, but you can provide a 
	// custom menu of your own by using <item> setMenuFormRepresentation] 
	submenu = [[[NSMenu alloc] init] autorelease];
	submenuItem = [[[NSMenuItem alloc] initWithTitle: @"Search Panel" action: @selector(searchUsingSearchPanel:) keyEquivalent: @""] autorelease];
	menuFormRep = [[[NSMenuItem alloc] init] autorelease];

	[submenu addItem: submenuItem];
	[submenuItem setTarget: self];
	[menuFormRep setSubmenu: submenu];
	[menuFormRep setTitle: [toolbarItem label]];
	[toolbarItem setMenuFormRepresentation: menuFormRep];
 */
}


- (void) toolbarWillAddItem: (NSNotification *) notif
{
/*   
	NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if([[addedItem itemIdentifier] isEqual: SearchDocToolbarItemIdentifier]) {
 	activeSearchItem = [addedItem retain];
  	[activeSearchItem setTarget: self];
 	[activeSearchItem setAction: @selector(searchUsingToolbarTextField:)];
    } else
	  if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
	[addedItem setToolTip: @"Print Your Document"];
	[addedItem setTarget: self];
    }
*/	
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif
{
	NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
    if([[removedItem itemIdentifier] isEqual: MAC_GROUPS]) {
		groupsPopupButton = nil;
	}
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
    BOOL 		enable = NO;
	NSString	*itemIdent = [toolbarItem itemIdentifier];

    if ([itemIdent isEqual: MAC_NEWPOSTING]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_FOLLOWUP]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
	} else if ([itemIdent isEqual: MAC_REPLY]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
	} else if ([itemIdent isEqual: MAC_CHECKNEW]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_REMOVEREAD]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_CATCHUP]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_SAVESELECTED]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
	} else if ([itemIdent isEqual: MAC_AUTOEXTRACT]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_FORWARD]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
    } else if ([itemIdent isEqual: MAC_SHOWHIDEGTV]) {
		if ([theSubscription gtvIsShown]) {
			[toolbarItem setLabel: NSLocalizedString(@"Hide GTV", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Hide Graphical Thread View (GTV) drawer", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"HideGTVDrawer"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Show GTV", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Show Graphical Thread View (GTV) drawer", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"ShowGTVDrawer"]];		
		}
		enable = YES;
	} else if ([itemIdent isEqual: MAC_FILTERFRIENDS]) {
		if ([self isFilteredForSenders]) {
			[toolbarItem setLabel: NSLocalizedString(@"Remove Friends Filter", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Remove the friends filter", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"RemoveFriendsFilter"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Filter Friends", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Show only postings whose sender is in the friends list", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"FilterForFriends"]];		
		}
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_FILTERSUBJECTS]) {
		if ([self isFilteredForSubjects]) {
			[toolbarItem setLabel: NSLocalizedString(@"Remove Subjects Filter", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Remove the subjects/favorites filter", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"RemoveSubjectsFilter"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Filter Subjects", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Show only postings whose subjects are in the favorite subjects list", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"FilterForSubjects"]];		
		}
		enable = ([subscriptionWindowMgr selectedGroup] != nil);
	} else if ([itemIdent isEqual: MAC_ADDGROUPS]) {
		enable = YES;
	} else if ([itemIdent isEqual: MAC_SHOWHIDEDRAWER]) {
		if ([self isShowingDrawer]) {
			[toolbarItem setLabel: NSLocalizedString(@"Hide Drawer", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Hide the groups drawer", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"HideDrawer"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Show Drawer", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Show the groups drawer", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"ShowDrawer"]];		
		}
		enable = YES;
	} else if ([itemIdent isEqual: MAC_MARKAS]) {
		enable = YES;
    } else if ([itemIdent isEqual: MAC_HIDEREAD]) {
		if ([self isHidingRead]) {
			[toolbarItem setLabel: NSLocalizedString(@"Unhide Read", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Stop hiding read articles", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"UnhideRead"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Hide Read", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Hide read articles (show unread articles only)", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"HideRead"]];		
		}
		enable = YES;
    } else if ([itemIdent isEqual: MAC_REMOVEITEMS]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
    } else if ([itemIdent isEqual: MAC_DISPLAYFLAT]) {
		if ([self isUnthreadedDisplay]) {
			[toolbarItem setLabel: NSLocalizedString(@"Display Threaded", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Display articles threaded", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"DisplayThreaded"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Display Unthreaded", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Display articles unthreaded", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"DisplayFlat"]];		
		}
		enable = YES;
    } else if ([itemIdent isEqual: MAC_FOCUSONTHREAD]) {
		if ([self isFocusingOnThread]) {
			[toolbarItem setLabel: NSLocalizedString(@"Unfocus Threaded", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Stop focusing on the current thread/show all threads", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"UnfocusThread"]];		
			enable = ([subscriptionWindowMgr selectedGroup] != nil);
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Focus Thread", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Focuses on the current thread/hide all others", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"FocusOnThread"]];		
			enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
		}
    } else if ([itemIdent isEqual: MAC_ADDTOOFFLINE]) {
		enable = ([subscriptionWindowMgr selectedGroup] != nil) && [subscriptionWindowMgr isAnyPostingSelected];
    } else if ([itemIdent isEqual: MAC_SHOWHIDETABS]) {
		enable = YES;
    } else if ([itemIdent isEqual: MAC_GOONOFFLINE]) {
		if ([[ISOPreferences sharedInstance] isOffline]) {
			[toolbarItem setLabel: NSLocalizedString(@"Go Online", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Go online (allow connections)", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"GoOnline"]];		
		} else {
			[toolbarItem setLabel: NSLocalizedString(@"Go Offline", @"")];
			[toolbarItem setToolTip: NSLocalizedString(@"Go offline (don't allow any connections unless requested explicitly)", @"")];
			[toolbarItem setImage:[NSImage imageNamed:@"GoOffline"]];
		}
		enable = YES;
	}
    return enable;
}


- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
	if (aBool) {
		[sound release];
	}
}

- (BOOL)isUnthreadedDisplay
{
	return [[subscriptionWindowMgr activeGroup] isUnthreadedDisplay];
}

- (BOOL)isFilteredForSubjects
{
	return [[subscriptionWindowMgr activeGroup] isFilteredForSubjects];
}

- (BOOL)isFilteredForSenders
{
	return [[subscriptionWindowMgr activeGroup] isFilteredForSenders];
}

- (BOOL)isFocusingOnThread
{
	return [[subscriptionWindowMgr activeGroup] isFocusingOnThread];
}

- (void)toggleThreadedDisplay
{
	[subscriptionWindowMgr toggleThreadedDisplay];
}

- (void)toggleThreadFocus
{
	[subscriptionWindowMgr toggleThreadFocus];
}

- (BOOL)isShowingDrawer
{
	return [subscriptionWindowMgr isShowingDrawer];
}

- (BOOL)isHidingRead
{
	return [[subscriptionWindowMgr activeGroup] isHidingRead];
}

- (void)toggleGraphicalTV
{
	[subscriptionWindowMgr toggleGraphicalTV];
}

- (void)encodingChanged:sender
{
	selectedEncoding = [sender tag];
	[subscriptionWindowMgr encodingChanged];
}

- (NSStringEncoding )selectedEncoding
{
	return selectedEncoding;
}

- (NSDictionary *)viewOptions
{
	return [theSubscription viewOptions];
}

- (void)setViewOption:(NSString *)viewOption value:(int)value
{
	[theSubscription setViewOption:viewOption value:value];
	[subscriptionWindowMgr viewOption:viewOption changedTo:value];
	[self subscriptionDataChanged];
}

- (int)viewOptionValueForKey:(NSString *)aKey
{
	return [theSubscription viewOptionValueForKey:aKey];
}

- (void)groupChanged:sender
{
	[subscriptionWindowMgr groupChangedTo:[groupsPopupButton titleOfSelectedItem]];
}

- (void)reflectGroupSelection:(NSString *)groupName
{
	[groupsPopupButton selectItemWithTitle:groupName];
}

- (void)updateGroupsDisplay
{
	[self updateGroupsMenuInToolbarItem:nil retainPopup:NO];
}

- (void)filterForToolbarSelection:sender
{
	[subscriptionWindowMgr filterForToolbarSelection:self];
}

- (void)toggleTabviewTabs:sender
{
	[subscriptionWindowMgr toggleTabviewTabs];
}

- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo
{
	[ISOActiveLogger logWithDebuglevel:0 :@"Here..."];
	if (([[ISOPreferences sharedInstance] prefsSaveOnCloseSubscription]) && ([self fileName]) && [self isDocumentEdited]) {
		saveInSeparateThread = NO;
		[self saveDocument:self];
		[theSubscription setSubscriptionEdited:NO];
		saveInSeparateThread = YES;
	}
	[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}

- (void)checkForNewPostingsInSubscription:sender
{
	if (![[ISOPreferences sharedInstance] isOffline]) {
		[self scheduleCheckAllGroups];
	} else {
		[ISOBeep beep:@"You are offline. You need to go online to check for any new postings."];
	}
}

- (void)offlineInGroup:sender
{
	[subscriptionWindowMgr offlineInGroup];
}

- (void)offlineInSubscription:sender
{
	[subscriptionWindowMgr offlineInSubscription];
}

- (void)expireLocallyInGroup:sender
{
	[subscriptionWindowMgr removeExpiredArticlesInGroup];
}

- (void)expireLocallyInSubscription:sender
{
	[subscriptionWindowMgr removeExpiredArticlesInSubscription];
}

- (void)toggleFullHeaders:sender
{
	[theSubscription toggleFullHeadersView];
	[subscriptionWindowMgr toggleFullHeadersView];
}

- (void)splitListAndContent:sender
{
	[subscriptionWindowMgr splitListAndContent];
}

- (void)cancelMessage
{
	[subscriptionWindowMgr cancelMessage];
}

- (id)splitPostingWindowMgr
{
	return splitPostingWindowMgr;
}

- (id)subscriptionWindowMgr
{
	return subscriptionWindowMgr;
}

- (void)resetLastMessageNumber
{
	[subscriptionWindowMgr resetLastPostingNumber];
}

- (BOOL)isShowingGTV
{
	return [subscriptionWindowMgr isShowingGTV];
}

- (BOOL)isSplitListAndContent
{
	return [subscriptionWindowMgr isSplitListAndContent];
}

- (BOOL)isShowingFullHeaders
{
	return [theSubscription shouldShowFullHeaders];
}

- (BOOL)isShowingTabviewTabs
{
	return [subscriptionWindowMgr isShowingTabviewTabs];
}

- (void)setShouldShowAbbreviatedGroupNames:(BOOL)flag
{
	[theSubscription setShouldShowAbbreviatedGroupNames:flag];
	[self subscriptionDataChanged];
}

- (BOOL)shouldShowAbbreviatedGroupNames
{
	return [theSubscription shouldShowAbbreviatedGroupNames];
}

- (void)loadPosting:sender
{
	[subscriptionWindowMgr loadPosting];
}

- (void)loadSinglePosting
{
	[subscriptionWindowMgr loadSinglePosting];
}

- (BOOL)isAnyPostingLocked
{
	return [subscriptionWindowMgr isAnyPostingLocked];
}

- (void)lockUnlockPostings
{
	[subscriptionWindowMgr lockUnlockPostings];
}

@end
