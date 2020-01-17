//
//  ISOSubscriptionWindowMgr.m
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOController.h"
#import "ISOSubscriptionWindowMgr.h"
#import "ISOSubscriptionMgr.h"
#import "ISOSPAMFilterMgr.h"
#import "ISOPreferences.h"
#import "ISOSentPostingsMgr.h"
#import "NSTextView_Extensions.h"
#import "NSOutlineView_UIExtensions.h"
#import "NSString_Extensions.h"
#import "ISOJobMgr.h"
#import "ISOJobViewMgr.h"
#import "ISOJobViewCell.h"
#import "ISODragImageView.h"
#import "ISOBeep.h"
#import "ISOOfflineMgr.h"
#import "ISOReaderWindow.h"
#import "ISOFriendsFavController.h"
#import "ISOLogger.h"
#import "ISOSubjectsMgr.h"
#import "ISOFriendsMgr.h"
#import "ISOGraphicalTVMgr.h"
#import "ISOViewOptionsMgr.h"
#import "ISOSubsDrawerMgr.h"
#import "ISOReaderPanel.h"
#import "ImageAndTextCell.h"
#import "debugging.h"
#import "Functions.h"
#import "ISOPostingCanceler.h"
#import "ISOPostingNumberResetter.h"
#import "ISOResourceMgr.h"
#import "ISOOnePostingDisplayMgr.h"
#import "ISOSinglePostingLoader.h"

#import <uudeview.h>

@implementation ISOSubscriptionWindowMgr
static NSCharacterSet	*registeredKeys = nil;

- initWithWindowNibName:(NSString *)nibName
{
	initializingTable = YES;
    self = [super initWithWindowNibName:nibName];
	[NSBundle loadNibNamed:nibName owner:self];
	dontAskForConnectionAnymore = NO;
	postingHeaderLoader = nil;
	postingLoader = nil;
	postingCount = 0;
	lineCount = 0;
	activePosting = nil;
	[postingDisplayMgr setPosting:activePosting];
	activeGroup = nil;
	lastSortCriteria = K_SORTC_SUBJECT;
	sortReverse = NO;
	searchSearchStartPosting = nil;
	followUpsArrivedOnLastCheck = 0;
	followUpsArrived = [[NSMutableArray array] retain];
	if (!registeredKeys) {
		registeredKeys = [NSCharacterSet characterSetWithCharactersInString:@"sSfFkKhHgGtTpPvVmMoOrR10dDbBaAjJzZ/\x7f."];
		[registeredKeys retain];
	}
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesListFontChanged:) name:@"ISOListFontChanged" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(groupPostingsChangedRemotely:) name:@"ISOGroupPostingsChanged" object:nil];
	removeExpiredArticlesInGroup = YES;
	expandingAllThreads = NO;
	timer = nil;
	timerMutex = [[NSLock alloc] init];
	displayLock = [[NSLock alloc] init];
	needsDisplayRefresh = NO;
    return self;
}

- (void)dealloc
{
	if ([timerMutex tryLock]) {
		if (timer) {
			[timer invalidate];
			[timer release];
			[ISOActiveLogger logWithDebuglevel:1 :@"REMOVE TIMER in dealloc 1"];
		}
		timer = nil;
		[timerMutex unlock];
	} else if ([timer isValid]) {
		[timer invalidate];
		[timer release];
		[ISOActiveLogger logWithDebuglevel:1 :@"REMOVE TIMER in dealloc 2"];
		timer = nil;
	}
	[timerMutex release];
	timerMutex = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[followUpsArrived release];
	followUpsArrived = nil;
	
	[markMenu release];
	markMenu = nil;
	
	[encodingMenu release];
	encodingMenu = nil;
	
	[groupsMenu release];
	groupsMenu = nil;
	
	[filterGroupMenu release];
	filterGroupMenu = nil;
	
	[filterGroupField release];
	filterGroupField = nil;
	
	[ISOActiveLogger logWithDebuglevel:1 :@"ISOSubscriptionWindowMgr dealloc called"];
	
	[displayLock release];
	displayLock = nil;
    
	[super dealloc];
}

- setSubscriptionMgr:(id)aSubscriptionMgr
{
	[super setSubscriptionMgr:aSubscriptionMgr];
	[serverMgr setSubscriptionMgr:aSubscriptionMgr];
	lastSortCriteria = [[theSubscriptionMgr theSubscription] sortOrder];
	sortReverse = [[theSubscriptionMgr theSubscription] sortReverse];
	if (lastSortCriteria == 0) {
		lastSortCriteria = K_SORTC_SUBJECT;
	}
	[drawerMgr setSubscriptionMgr:aSubscriptionMgr];
	[drawerMgr setSubscriptionWindowMgr:self];
	[postingDisplayMgr setSubscriptionMgr:theSubscriptionMgr];
	return self;
}

- setupTableColumnHeaders
{
	NSFont			*aFont = [[ISOPreferences sharedInstance] prefsListviewFont];
	NSArray			*anArray;
	NSTableColumn	*aTableColumn;
	int				i, count;	
	NSTableHeaderCell	*aCell;
	
	if ([postingsTable font] != aFont) {
		[postingsTable setFont:aFont];
		[postingsTable setRowHeight:[aFont defaultLineHeightForFont] * 0.95];
	}
	anArray = [postingsTable tableColumns];
	count = [anArray count];
	for (i=0;i<count;i++) {
		aTableColumn = [anArray objectAtIndex:i];
        if ([(NSString *)[aTableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) {
			[[aTableColumn headerCell] setStringValue:NSLocalizedString(@"Sender", @"")];
			aCell = [aTableColumn dataCell];
			if ([aCell font] != aFont) {
				[aCell setFont:aFont];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			[[aTableColumn headerCell] setStringValue:NSLocalizedString(@"Subject", @"")];
			aCell = [aTableColumn dataCell];
			if ([aCell font] != aFont) {
				[aCell setFont:aFont];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			[[aTableColumn headerCell] setStringValue:NSLocalizedString(@"Date", @"")];
			aCell = [aTableColumn dataCell];
			if ([aCell font] != aFont) {
				[aCell setFont:aFont];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			[[aTableColumn headerCell] setStringValue:NSLocalizedString(@"Size", @"")];
			aCell = [aTableColumn dataCell];
			if ([aCell font] != aFont) {
				[aCell setFont:aFont];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_FLAG"] == NSOrderedSame) {
            [[aTableColumn headerCell] setImage:[NSImage imageNamed:@"flagged_header"]];
			[aTableColumn setDataCell:[[[ImageAndTextCell alloc] initImageCell:nil] autorelease]];
			[[aTableColumn dataCell] setDrawsBackground:YES];
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_LOADED"] == NSOrderedSame) {
            [[aTableColumn headerCell] setImage:[NSImage imageNamed:@"loaded"]];
			[aTableColumn setDataCell:[[[ImageAndTextCell alloc] initImageCell:nil] autorelease]];
			[[aTableColumn dataCell] setDrawsBackground:YES];
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_STATUS"] == NSOrderedSame) {
            [[aTableColumn headerCell] setImage:[NSImage imageNamed:@"status_header"]];
			[aTableColumn setDataCell:[[[ImageAndTextCell alloc] initImageCell:nil] autorelease]];
			[[aTableColumn dataCell] setDrawsBackground:YES];
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_ATTACHMENTS"] == NSOrderedSame) {
            [[aTableColumn headerCell] setImage:[NSImage imageNamed:@"attachment"]];
			[aTableColumn setDataCell:[[[ImageAndTextCell alloc] initImageCell:nil] autorelease]];
			[[aTableColumn dataCell] setDrawsBackground:YES];
        } else if ([(NSString *)[aTableColumn identifier] compare:@"OUTLINE_COLUMN"] == NSOrderedSame) {
			[postingsTable setOutlineTableColumn:aTableColumn];
            [[aTableColumn headerCell] setStringValue:@""];
		}
	}
	[postingsTable setIndentationMarkerFollowsCell:NO];
	[postingsTable setIndentationPerLevel:0.0];
	[postingsTable setIntercellSpacing:NSMakeSize(1.0, 3.0)];
//	[postingsTable setDrawsGrid:YES];
	return self;
}

- (void)unhideWindow
{
    [super showWindow:self];
}

- (void)awakeFromNib
{
    [tabView selectFirstTabViewItem:self];
	[((NSTabView *)tabView) setDelegate:postingDisplayMgr];
    
	[((ISOOnePostingDisplayMgr *)postingDisplayMgr) setOwner:self];
	[((NSSplitView *)splitView) setDelegate:nil];
	[[postingsTable window] setFrameUsingName:[NSString stringWithFormat:@"ISOReaderWindow %@", [[theSubscriptionMgr theSubscription] subscriptionName]]];
	[[postingsTable window] setFrameAutosaveName:[NSString stringWithFormat:@"ISOReaderWindow %@", [[theSubscriptionMgr theSubscription] subscriptionName]]];
    
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ISOGroupDrawerWasOpen"]) {
		[drawerMgr showHideDrawer];
	}
	[((ISOGraphicalTVMgr *)graphicalThreadViewMgr) setOwner:self];
	[graphicalThreadViewMgr changeImageSizeTo:[[theSubscriptionMgr theSubscription] gtvIconSize]];
	[markMenu retain];
	[encodingMenu retain];
	[groupsMenu retain];
	[filterGroupMenu retain];
	[filterGroupField retain];
}

- (void)showWindow:sender
{
	float splitViewVertSize = [[theSubscriptionMgr theSubscription] splitViewVertPosition];

    [super showWindow:self];
	[self _updatePostingDisplay];
	[groupsTable reloadData];
	[self newsgroupSelected:groupsTable];
	[((NSSplitView *)splitView) setDelegate:self];
	[[theSubscriptionMgr theSubscription] setSubscriptionEdited:NO];
	[self setSubscriptionEdited:NO];
	if (splitViewVertSize >= 50.0) {
		NSRect	aFrame = [postingsTableScrollView frame];
		aFrame.size.height = splitViewVertSize;
		[[postingsTableScrollView superview] setNeedsDisplayInRect:aFrame];
		[postingsTableScrollView setFrameSize:aFrame.size];
		[[postingsTableScrollView superview] display];
	}
	[((ISOReaderWindow *)[postingsTable window]) registerCharacterSetAsKeys:registeredKeys];
	[((ISOReaderPanel *)[[theSubscriptionMgr splitPostingWindowMgr] window]) registerCharacterSetAsKeys:registeredKeys];
	[self initializeTableColumns];
	if (![[theSubscriptionMgr theSubscription] areTabsShown]) {
		[tabView setDrawsBackground:NO];
		[tabView setTabViewType:NSNoTabsNoBorder];
	}
	if ([[theSubscriptionMgr theSubscription] gtvIsShown]) {
		[self toggleGraphicalTV];
	}
	if ([[theSubscriptionMgr theSubscription] showUnreadOnly]) {
		//
		// [self toggleHideRead];
	}
	if ([[theSubscriptionMgr theSubscription] isTabViewDisconnected]) {
		[self disconnectTabViewFromSplitview];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == groupsTable) {
		return [[[theSubscriptionMgr theSubscription] groups] count];
    } else {
        return [postingDisplayMgr numberOfRowsInTableView:aTableView];
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (aTableView == groupsTable) {
		return [self groupsTableValueForTableColumn:aTableColumn row:rowIndex];
    } else {
        return [postingDisplayMgr tableView:aTableView objectValueForTableColumn:aTableColumn row:rowIndex];
    }
}

- (id)groupsTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	ISONewsGroup	*aGroup;
	
	if (rowIndex >= 0) {
		aGroup = [[theSubscriptionMgr theSubscription] groupAtIndex:rowIndex];
		if (aGroup) {
			if ([(NSString *)[aTableColumn identifier] compare:@"G_GROUPNAME"] == NSOrderedSame) {
				return [aGroup abbreviatedGroupName];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"G_ARTICLES"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[aGroup totalPostingCount]];
			} else if ([(NSString *)[aTableColumn identifier] compare:@"G_UNREAD"] == NSOrderedSame) {
				return [NSNumber numberWithInt:[aGroup totalUnreadPostingCount]];
			}
		}
	}
	return nil;
}

/* End of Table Methods */
/* POSTING Loading */
- (BOOL)loadPostings:sender
{
	if (postingHeaderLoader && [postingHeaderLoader isWorkInProgress]) {
		return YES;
	}
    if ([[[theSubscriptionMgr theSubscription] groups] count] && ([groupsTable numberOfSelectedRows] > 0)) {
		if (postingHeaderLoader && ![postingHeaderLoader isWorkInProgress]) {
			[postingHeaderLoader release];
			postingHeaderLoader = nil;
		}
		followUpsArrivedOnLastCheck = 0;
		[followUpsArrived removeAllObjects];
        postingHeaderLoader = [[ISOPostingLoader alloc] initWithDelegate:self
								groups:[[theSubscriptionMgr theSubscription] groups]
								andSpamFilter:[[theSubscriptionMgr theSubscription] filters]];

		if ([[theSubscriptionMgr theSubscription] overviewFmtIsLoaded] || [postingHeaderLoader loadOverviewFmtWithSubscriptionMgr:theSubscriptionMgr andGroup:activeGroup]) {

			[activeGroup setDisplayView:nil];
			[activeGroup setDisplayWhileLoading:NO];


			[postingHeaderLoader setLoadTarget:self];
			[postingHeaderLoader setLoadAction:@selector(finishedLoadingHeaders:)];
			[((ISOPostingLoader *)postingHeaderLoader) setActiveGroup:activeGroup];
			[progressIndicator setIndeterminate:YES];
			[progressIndicator animate:self];
			[progressMessageField setStringValue:NSLocalizedString(@"Loading Headers...", @"")];
			[[ISOJobMgr sharedJobMgr]
				addConnectionJob:NSLocalizedString(@"Load Headers", @"")
				forSubscriptionMgr:theSubscriptionMgr
				withSelector:@selector(loadPostings:)
				receiver:postingHeaderLoader
				userObject:theSubscriptionMgr
				forOwner:self];
		} else {
			[postingHeaderLoader release];
			postingHeaderLoader = nil;
			NSRunAlertPanel(NSLocalizedString(@"Could not load overview", @""),
				NSLocalizedString(@"An error occured while loading headers: I could not load the overview format from the news server. The reason might be that this is a very, very, very old NNTP server. I am sorry, that I don't support old servers!", @""),
				NSLocalizedString(@"Merde", @""),
				nil,
				nil);
			return NO;
		}
    }
    return YES;
}

- (void)_postingLoadFinished:aTimer
{
	id postingToShow = [aTimer userInfo];
	if (activePosting == postingToShow) {
		[activePosting setDisplayEncoding:[theSubscriptionMgr selectedEncoding]];
		[postingDisplayMgr showPosting];
		if ([activePosting isBodyLoaded]) {
			[self markSelectedPostingRead];
//			[activePosting setIsRead:YES];
			[drawerMgr updateGroupsDisplay];
		}
		if ([activePosting isPostingInvalid]) {
			NSString *identifier = [[tabView selectedTabViewItem] identifier];
			if (([identifier compare:@"TEXT"] != NSOrderedSame) && ([identifier compare:@"RAWSOURCE"] != NSOrderedSame)) {
				NSBeginAlertSheet(NSLocalizedString(@"Load Error", @""),
					NSLocalizedString(@"Damn", @""),
					nil,
					nil,
					[self window],
					nil, nil, nil, nil,
					NSLocalizedString(@"The posting couldn't be loaded. For details see text-tab.", @"")
				);
			}
		}
		[postingsTable reloadItem:activePosting reloadChildren:NO];
		[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
		[progressMessageField display];
		[progressIndicator setMaxValue:1.0];
		[progressIndicator setDoubleValue:0.0];
		if ([graphicalThreadViewMgr isShowingGTV]) {
			if (activePosting && ([activePosting highestParent] != activePosting) || ([activePosting hasSubPostings]) && ([graphicalThreadViewMgr owner] == self)) {
				[graphicalThreadViewMgr redisplayPosting:activePosting];
			}
		}
	}
	[theSubscriptionMgr subscriptionDataChanged];
}

- (void)postingLoadFinished:sender
{
	NSTimer *aTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(_postingLoadFinished:) userInfo:[sender postingBeingLoaded] repeats:NO];
	[[gMainController mainRunLoop] addTimer:aTimer forMode:NSDefaultRunLoopMode];
}

- (void)_postingSelected:(id)sender forceLoad:(BOOL)forceLoad
{
    int					rowIndex;
    ISONewsPosting		*thePosting;
    BOOL				isLoaded;
	int 				choice;
	int					prfLoad;
	id					oldActivePosting;
    
	timer = nil;
	[activePosting setIsSelected:NO];
	oldActivePosting = activePosting;
	activePosting = nil;
	[postingDisplayMgr setPosting:activePosting];
	[postingDisplayMgr clearDisplay];
	activePosting = oldActivePosting;
	[postingDisplayMgr setPosting:activePosting];
	if ([postingsTable numberOfSelectedRows] == 1) {
		rowIndex = [postingsTable selectedRow];
		prfLoad = [[ISOPreferences sharedInstance] prefsPostingClickedAction];
		if (rowIndex >= 0) {
			thePosting = [postingsTable itemAtRow:rowIndex];
			if (thePosting) {
				activePosting = thePosting;
				/* Now that we have the selected posting secured, we can see if a redisplay is needed and if so we will just redisplay the postings table... */
				if (needsDisplayRefresh) {
					needsDisplayRefresh = NO;
					[self _updatePostingDisplay];
				}
				[postingDisplayMgr setPosting:activePosting];
				isLoaded = [thePosting isBodyLoaded];
				if (forceLoad || ((!isLoaded && (prfLoad != PREFS_PostingClickedDontLoad) && ![[ISOPreferences sharedInstance] isOffline])) ) {
					choice = NSAlertDefaultReturn;
					[thePosting setIsOffline:NO];
					if (prfLoad == PREFS_PostingClickedLoad) {
						dontAskForConnectionAnymore = YES;
					}
					if (!dontAskForConnectionAnymore) {
						choice = NSRunAlertPanel(NSLocalizedString(@"Show Posting", @"Title of alert panel which comes up when don't have the posting loaded."), 
						NSLocalizedString(@"The posting you would like to read is not loaded. Would you like me to connect to the NNTP-Server and try to load it for you?", @"Message in the alert panel which shows the error."), 
						NSLocalizedString(@"Load Message", @"Choice (on a button) given to user which allows him/her to ignore this message."), 
						NSLocalizedString(@"Always Load", @"I.e. don't ask me anymore for this subscription and session."),
						NSLocalizedString(@"Cancel", @"Choice (on a button) given to user which allows him/her to go to the Preferences panel."));
					} else {
						choice = NSAlertAlternateReturn;
					}
	
					if ((choice == NSAlertDefaultReturn) || (choice == NSAlertAlternateReturn)) {
						[self loadBodyOfPosting:thePosting];
						if (choice == NSAlertAlternateReturn) {
							dontAskForConnectionAnymore = YES;
						}
					}
				} else if (prfLoad == PREFS_PostingClickedDontLoad) {
				} else if (isLoaded) {
					[postingDisplayMgr showPosting];
					[theSubscriptionMgr subscriptionDataChanged];
					[self markSelectedPostingRead];
					// [thePosting setIsRead:YES];
					[drawerMgr updateGroupsDisplay];
				} else if ([[ISOPreferences sharedInstance] isOffline]) {
					[thePosting setIsOffline:YES];
					[postingDisplayMgr showPosting];
				}
				if ([tabView window] != [self window]) {
					NSString *title = [NSString stringWithFormat:@"%@ [%@]", [activePosting decodedSubject], [activeGroup abbreviatedGroupName]];
					[[tabView window] setTitle:title];
				}
			}
			[activePosting setIsSelected:YES];
		} else {
			activePosting = nil;
			[postingDisplayMgr setPosting:activePosting];
		}
		if ([graphicalThreadViewMgr isShowingGTV]) {
			if (activePosting && ([activePosting highestParent] != activePosting) || ([activePosting hasSubPostings])) {
				[graphicalThreadViewMgr setThread:[NSArray arrayWithObjects:[activePosting highestParent], nil] ofOwner:self];
				[graphicalThreadViewMgr setTarget:self];
				[graphicalThreadViewMgr setAction:@selector(gtvPostingSelected:)];
			} else {
				[graphicalThreadViewMgr setThread:nil ofOwner:self];
				[graphicalThreadViewMgr setTarget:nil];
				[graphicalThreadViewMgr setAction:nil];
			}
		}
	} else {
		activePosting = nil;
		[postingDisplayMgr setPosting:activePosting];
	}
}

- (void)_timedLoad
{
	if (timerMutex) {
		[timerMutex lock];
		if (timer) {
			[timer release]; // decrement linkCount for our "retain" in "postingSelected"
			[ISOActiveLogger logWithDebuglevel:1 :@"REMOVE TIMER in timedLoad"];
		}
		timer = nil;
		[timerMutex unlock];
		[self _postingSelected:self forceLoad:NO];
	} // otherwise, we have already been deallocated...
}


- (void)postingSelected
{
	if ([timerMutex tryLock]) {
		if (timer) {
			if ([timer isValid]) {
				[timer invalidate];
				[ISOActiveLogger logWithDebuglevel:1 :@"REMOVE TIMER in postingSelected"];
			}
			[timer release];
		}
		timer = nil;
		[timerMutex unlock];
		[postingDisplayMgr clearDisplay];
		timer = [NSTimer scheduledTimerWithTimeInterval:0.3
							target:self
							selector:@selector(_timedLoad)
							userInfo:nil
							repeats:NO];
		[ISOActiveLogger logWithDebuglevel:1 :@"ADD TIMER"];
		[timer retain];
	}
}


- (BOOL)loadBodyOfPosting:(ISONewsPosting *)aPosting
{
    BOOL	result = NO;
    
	if ([[[theSubscriptionMgr theSubscription] groups] count]) {
		postingLoader = [[[ISOPostingLoader alloc] initWithDelegate:self] autorelease];

		[postingLoader setLoadTarget:self];
		[postingLoader setLoadAction:@selector(postingLoadFinished:)];

		[progressIndicator setMaxValue:[[aPosting linesHeader] intValue]];
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setDoubleValue:0];
		[progressMessageField setStringValue:NSLocalizedString(@"Loading Posting...", @"")];
		[[ISOJobMgr sharedJobMgr]
				addNormalJob:[NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"L", @""), [aPosting decodedSubject]]
				forSubscriptionMgr:theSubscriptionMgr
				withSelector:@selector(loadPostingBody:)
				receiver:postingLoader
				userObject:aPosting
				forOwner:self];

	}
	return result;
}


- (void)newsgroupSelected:sender
{
    int	rowIndex;
	int	prfsGrpLoad;
	int	choice;
	NSString	*windowFilename = [[postingsTable window] representedFilename];
	BOOL	isUnthreadedDisplay = NO;
	BOOL	isHidingRead = [[theSubscriptionMgr theSubscription] showUnreadOnly];
	
	/* First cleanup screen */
	activePosting = nil;
	[postingDisplayMgr setPosting:activePosting];
	[postingDisplayMgr clearDisplay];
	[postingsTable deselectAll:self];
	
	isUnthreadedDisplay = [[theSubscriptionMgr theSubscription] isUnthreadedDisplay];
	if (!windowFilename) {
		windowFilename = [[postingsTable window] title];
	}
	prfsGrpLoad = [[ISOPreferences sharedInstance] prefsGroupClickedAction];
    
    rowIndex = [groupsTable selectedRow];
//	if (activeGroup) {
//		isHidingRead = [activeGroup isHidingRead];
//	}
	[activeGroup setDisplayView:nil];
	[activeGroup setDisplayWhileLoading:NO];
	activeGroup = nil;
	if (rowIndex >= 0) {
		activeGroup = [[theSubscriptionMgr theSubscription] groupAtIndex:rowIndex];
	}
	[[theSubscriptionMgr theSubscription] setActiveGroup:activeGroup];
	if (activeGroup) {
		NSString *title = [NSString stringWithFormat:@"%@: %@", [windowFilename lastPathComponent], [activeGroup groupName]];
		[[postingsTable window] setTitle:title];
		[activeGroup setIsUnthreadedDisplay:isUnthreadedDisplay];
		if (isHidingRead) {
			[activeGroup hideRead];
		} else {
			[activeGroup unhideRead];
		}
		[[theSubscriptionMgr theSubscription] setShowUnreadOnly:isHidingRead];
		if (prfsGrpLoad == PREFS_GroupClickedCheck) {
			choice = NSAlertDefaultReturn;
		} else if ((prfsGrpLoad == PREFS_GroupClickedDontCheck) || ([[ISOPreferences sharedInstance] isOffline])) {
			choice = NSAlertOtherReturn;
		} else {
			choice = NSRunAlertPanel(NSLocalizedString(@"Select Group", @"Title of alert panel which comes up when don't have the postings loaded."), 
					NSLocalizedString(@"There are no postings in this group. Do you want me to check on the server for any (new) postings in this group?", @"Message in the alert panel which shows the error."), 
					NSLocalizedString(@"Check Server", @"Choice (on a button) given to user which allows him/her to ignore this message."), 
					nil,
					NSLocalizedString(@"Cancel", @"Choice (on a button) given to user which allows him/her to go to the Preferences panel."));
		}
		if (choice == NSAlertDefaultReturn) {
			[theSubscriptionMgr checkForNewPostings];
		} else {
			[self reSortArticles];
		}
	}
	[self _updatePostingDisplay];
	if ([[ISOPreferences sharedInstance] prefsDefaultThreadDisplay] == PREFS_ThreadSmartDisplay) {
		[self expandThreadsSmart];
	}
	if (activeGroup) {
		[theSubscriptionMgr reflectGroupSelection:[activeGroup groupName]];
	}
	[postingsTable scrollRowToVisible:0];
}

/* END TabView Actions */

- (void)subscriptionChanged:sender
{
    if ([postingsTable window] == [NSApp mainWindow]) {
		[self _updatePostingDisplay];
		[groupsTable reloadData];
		[groupsTable display];
    }
}


/* ISOPostingLoader Delegate Methods */
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader willBeginGroup:(ISONewsGroup *)aGroup
{
	ISOJobViewCell *pi = [[ISOJobViewMgr sharedJobViewMgr] progressIndicatorForJob:[aPostingLoader job]];
	if (pi) {
		[pi setIndeterminate:YES];
		[pi animate:self];
	}
    return YES;
}

- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPostingHeader:(ISONewsPosting *)aPosting
{
	ISOJobViewCell *pi = [[ISOJobViewMgr sharedJobViewMgr] progressIndicatorForJob:[aPostingLoader job]];
	if (pi) {
		[pi setIndeterminate:YES];
		[pi animate:self];
	}
	[progressIndicator animate:self];
	if ([aPosting isAFollowUp]) {
		[followUpsArrived addObject:aPosting];
		followUpsArrivedOnLastCheck++;
	}
    return YES;
}

- (void)reSortArticles
{

	NSArray			*anArray;
	NSTableColumn	*aTableColumn;
	int				i, count;
	
	anArray = [postingsTable tableColumns];
	count = [anArray count];
	[[theSubscriptionMgr theSubscription] setSortOrder:lastSortCriteria];
	[[theSubscriptionMgr theSubscription] setSortReverse:sortReverse];

	switch (lastSortCriteria) {
		case K_SORTC_SUBJECT:
			[activeGroup sortPostingsBySubjectAscending:!sortReverse];
			break;
		case K_SORTC_SENDER:
			[activeGroup sortPostingsBySenderAscending:!sortReverse];
			break;
		case K_SORTC_DATE: 
			[activeGroup sortPostingsByDateAscending:!sortReverse];
			break;
		case K_SORTC_SIZE:
			[activeGroup sortPostingsBySizeAscending:!sortReverse];
			break;
		default:
			[activeGroup sortPostingsBySubjectAscending:!sortReverse];
			break;
	}

	for (i=0;i<count;i++) {
		NSTableHeaderCell	*headerCell;
		aTableColumn = [anArray objectAtIndex:i];
		headerCell = [aTableColumn headerCell];
        if ([(NSString *)[aTableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SENDER) {
				[postingsTable setIndicatorImage:[NSImage imageNamed:(sortReverse? @"uparrow":@"downarrow")] inTableColumn:aTableColumn];
				[postingsTable setHighlightedTableColumn:aTableColumn];
			} else {
				[postingsTable setIndicatorImage:nil inTableColumn:aTableColumn];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SUBJECT) {
				[postingsTable setIndicatorImage:[NSImage imageNamed:(sortReverse? @"uparrow":@"downarrow")] inTableColumn:aTableColumn];
				[postingsTable setHighlightedTableColumn:aTableColumn];
			} else {
				[postingsTable setIndicatorImage:nil inTableColumn:aTableColumn];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_DATE) {
				[postingsTable setIndicatorImage:[NSImage imageNamed:(sortReverse? @"uparrow":@"downarrow")] inTableColumn:aTableColumn];
				[postingsTable setHighlightedTableColumn:aTableColumn];
			} else {
				[postingsTable setIndicatorImage:nil inTableColumn:aTableColumn];
			}
        } else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SIZE) {
				[postingsTable setIndicatorImage:[NSImage imageNamed:(sortReverse? @"uparrow":@"downarrow")] inTableColumn:aTableColumn];
				[postingsTable setHighlightedTableColumn:aTableColumn];
			} else {
				[postingsTable setIndicatorImage:nil inTableColumn:aTableColumn];
			}
		}
	}

}

- (void)finishedLoadingHeaders:(id)aPostingHeaderLoader
{
	NSSound	*aSound = nil;
	ISONewsGroup	*theGroup = [aPostingHeaderLoader activeGroup];
	[postingHeaderLoader release];
	postingHeaderLoader = nil;

	[progressIndicator animate:self];
	if ([[ISOPreferences sharedInstance] prefsReloadParentPosting]) {
		[theGroup checkForParentPostings];
	}
	[progressIndicator animate:self];
	[theGroup reApplyFilters];
		[progressIndicator animate:self];
	if (theGroup == activeGroup) {
		[self reSortArticles];
	}
	if ([progressIndicator isIndeterminate]) {
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setDoubleValue:0.0];
		[progressMessageField setStringValue:NSLocalizedString(@"Ready.", @"")];
		[progressMessageField display];
	}
	[theGroup setDisplayView:nil];
	[theGroup setDisplayWhileLoading:NO];

	[theSubscriptionMgr subscriptionDataChanged];
	if (theGroup == activeGroup) {
		[self _updatePostingDisplayPreservingSelection:NO];
		[groupsTable reloadData];
		[groupsTable display];
		if ((followUpsArrivedOnLastCheck>0) && [[ISOPreferences sharedInstance] prefsAlertOnFollowUp]) {
			if ([[ISOPreferences sharedInstance] prefsAlertOnFollowUpWithSound]) {
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
				[self expandAndShowItems:followUpsArrived];
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
					[self expandAndShowItems:followUpsArrived];
				}
			}
		}
		if ([[ISOPreferences sharedInstance] prefsDefaultThreadDisplay] == PREFS_ThreadSmartDisplay) {
			[self expandThreadsSmart];
		}
	}
	[followUpsArrived removeAllObjects];
}

- (int)postingLoader:(ISOPostingLoader *)aPostingLoader readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine
{
	ISOJobViewCell *pi = [[ISOJobViewMgr sharedJobViewMgr] progressIndicatorForJob:[aPostingLoader job]];
	if (pi) {
		if ([pi maxValue] < 2.0) {
			[pi setIndeterminate:NO];
			[pi setMinValue:0.0];
			if ([[aPosting linesHeader] doubleValue]>0.0) {
				[pi setMaxValue:[[aPosting linesHeader] doubleValue]];
			} else {
				[pi setMaxValue:100.0];
			}
		}
#ifdef MAC_SLOWDOWN_FOR_TESTING
		[pi incrementBy:1];
#else
		if ((aLine % 10) == 0) {
			[pi incrementBy:10];
		}
#endif
	}
#ifdef MAC_SLOWDOWN_FOR_TESTING
		[progressIndicator incrementBy:1];
#else
	if (((aLine % 10) == 0) && ([aPostingLoader postingBeingLoaded] == activePosting)) {
		[progressIndicator incrementBy:10];
	}
#endif
	return 0;
}

- (ISONewsPosting *)activePosting
{
	return activePosting;
}

- (void)_reflectDisplayChanges
{
	[theSubscriptionMgr subscriptionDataChanged];
	[groupsTable reloadData];
	[groupsTable display];
	[self _updatePostingDisplayPreservingSelection:NO];
	[self postingSelected];
}

/* ................. */
- (void)markSelectedPostingRead
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markPosting:aPosting read:YES];
	}
	[self _updatePostingDisplay];
	[drawerMgr updateGroupsDisplay];
}

- (void)markSelectedPostingUnread
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markPosting:aPosting read:NO];
	}
	[self _updatePostingDisplay];
	[drawerMgr updateGroupsDisplay];
}

- (void)markThreadRead
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markThread:aPosting asRead:YES];
	}
	[self _updatePostingDisplay];
	[drawerMgr updateGroupsDisplay];
}

- (void)markThreadUnread
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markThread:aPosting asRead:NO];
	}
	[self _updatePostingDisplay];
	[drawerMgr updateGroupsDisplay];
}

- (void)_markSubscriptionRead:(BOOL)flag
{
	double			piM, piC;
	NSString		*pmfS;
	BOOL			piD;
	int				numberOfGroups, i;
	ISOSubscription	*aSubs = [theSubscriptionMgr theSubscription];
	
	numberOfGroups = [[aSubs groups] count];
	if (numberOfGroups > 0) {
		piC = [progressIndicator doubleValue];
		piM = [progressIndicator maxValue];
		pmfS = [progressMessageField stringValue];
		piD = [progressIndicator isIndeterminate];
	
		[progressIndicator setIndeterminate:NO];
		[progressIndicator setMaxValue:numberOfGroups];
		[progressIndicator setUsesThreadedAnimation:NO];
		if (flag) {
			[progressMessageField setStringValue:NSLocalizedString(@"Marking as read...", @"")];
		} else {
			[progressMessageField setStringValue:NSLocalizedString(@"Marking as unread...", @"")];
		}
		[progressMessageField displayIfNeeded];

		for (i=0; i<numberOfGroups; i++) {
			if (flag) {
				[[aSubs groupAtIndex:i] markPostingsRead];
			} else {
				[[aSubs groupAtIndex:i] markPostingsUnread];
			}
			[progressIndicator incrementBy:1];
		}

		[progressIndicator setMaxValue:piM];
		[progressIndicator setDoubleValue:piC];
		[progressIndicator setIndeterminate:piD];
		[progressMessageField setStringValue:pmfS];
		[progressMessageField displayIfNeeded];

	}
	[drawerMgr updateGroupsDisplay];
}

- (void)markSubscriptionRead
{
	int	choice;
	if (![[ISOPreferences sharedInstance] noMarkSubscriptionWarnings]) {
		choice = NSRunAlertPanel(NSLocalizedString(@"Mark Subscription Read", @""),
			NSLocalizedString(@"Are you sure you want to mark all the postings in this subscription as read?", @""),
			NSLocalizedString(@"Mark Read", @""),
			nil,
			NSLocalizedString(@"Cancel", @"")
		);
	} else {
		choice = NSAlertDefaultReturn;
	}
	if (choice == NSAlertDefaultReturn) {
		[self _markSubscriptionRead:YES];
		[theSubscriptionMgr subscriptionDataChanged];
		[self _updatePostingDisplay];
		[groupsTable reloadData];
	}
}

- (void)markSubscriptionUnread
{
	int	choice;
	if (![[ISOPreferences sharedInstance] noMarkSubscriptionWarnings]) {
		choice = NSRunAlertPanel(NSLocalizedString(@"Mark Subscription Unread", @""),
			NSLocalizedString(@"Are you sure you want to mark all the postings in this subscription as unread?", @""),
			NSLocalizedString(@"Mark Unread", @""),
			nil,
			NSLocalizedString(@"Cancel", @"")
		);
	} else {
		choice = NSAlertDefaultReturn;
	}
	if (choice == NSAlertDefaultReturn) {
		[self _markSubscriptionRead:NO];
		[self _reflectDisplayChanges];
	}
}


- (void)markGroupRead
{
	if (activeGroup) {
		[activeGroup markPostingsRead];
		[self _reflectDisplayChanges];
	}
	[drawerMgr updateGroupsDisplay];
}

- (void)markGroupUnread
{
	if (activeGroup) {
		[activeGroup markPostingsUnread];
		[self _reflectDisplayChanges];
	}
	[drawerMgr updateGroupsDisplay];
}


- (void)_removePostingsInvalid:(BOOL)invFlag read:(BOOL)readFlag all:(BOOL)allFlag
{
	if (invFlag) {
		[activeGroup removeInvalidPostings];
	}
	if (readFlag) {
		[activeGroup removeReadPostings];
	}
	if (allFlag) {
		[activeGroup removeAllPostings];
	}
	if (activePosting && ![activeGroup hasPosting:activePosting]) {
		activePosting = nil;
		[postingDisplayMgr setPosting:activePosting];
	}
	[postingsTable deselectAll:self];
	[self reSortArticles];
	[drawerMgr updateGroupsDisplay];
}

- (void)removeAllInvalidArticles
{
	[self _removePostingsInvalid:YES read:NO all:NO];
	[self _reflectDisplayChanges];
}

- (void)removeReadArticles
{
	[self _removePostingsInvalid:NO read:YES all:NO];
	[self _reflectDisplayChanges];
}

- (void)catchUp
{
	int choice;
	if (![[ISOPreferences sharedInstance] noCatchUpWarnings]) {
		choice = NSRunAlertPanel(NSLocalizedString(@"Catch Up", @""),
			NSLocalizedString(@"You want to delete all postings in this group. Are you sure you know what you are doing?", @""),
			NSLocalizedString(@"Yes, delete", @""),
			NSLocalizedString(@"I dunno...", @""),
			NSLocalizedString(@"Cancel", @"")
			);
	} else {
		choice = NSAlertDefaultReturn;
	}
	if (choice == NSAlertDefaultReturn) {
		[self _removePostingsInvalid:NO read:NO all:YES];
		[self _reflectDisplayChanges];
	}
}

- (void)_catchUpAll
{
	NSMutableArray	*groupsToCheck = [NSMutableArray array];
	int				i, count;

	[groupsToCheck addObjectsFromArray:[[theSubscriptionMgr theSubscription] groups]];
	count = [groupsToCheck count];
	for (i=0;i<count;i++) {
		ISONewsGroup	*thisGroup = [groupsToCheck objectAtIndex:i];
		[thisGroup removeAllPostings];
		if ((thisGroup == activeGroup) && activePosting && ![activeGroup hasPosting:activePosting]) {
			activePosting = nil;
			[postingDisplayMgr setPosting:nil];
		}
	}
	[postingsTable deselectAll:self];
	[self reSortArticles];
	[drawerMgr updateGroupsDisplay];
}

- (void)catchUpSubscription
{
	int choice;
	if (![[ISOPreferences sharedInstance] noCatchUpWarnings]) {
		choice = NSRunAlertPanel(NSLocalizedString(@"Catch Up Subscription", @""),
			NSLocalizedString(@"You want to delete all postings in all groups in this subscription. Are you sure you know what you are doing?", @""),
			NSLocalizedString(@"Yes, delete", @""),
			NSLocalizedString(@"I dunno...", @""),
			NSLocalizedString(@"Cancel", @"")
			);
	} else {
		choice = NSAlertDefaultReturn;
	}
	if (choice == NSAlertDefaultReturn) {
		[self _catchUpAll];
		[self _reflectDisplayChanges];
	}
}

- (void)checkForNewPostings
{
	[self loadPostings:self];
	[self _updatePostingDisplayPreservingSelection:NO];
}

- (void)_updatePostingDisplayPreservingSelection:(BOOL)flag
{
	NSMutableString	*aString;

	if (flag) {
		[postingsTable reloadDataPreservingSelection];
	} else {
		[postingsTable reloadData];
	}
//	[postingsTable displayIfNeeded];
	
	aString = [NSMutableString stringWithFormat:@"%d/%d", [activeGroup unreadPostingCountFlat], [activeGroup postingCountFlat]];
	[postingsCountField setStringValue:aString];
}

- (void)_updatePostingDisplay
{
	[self _updatePostingDisplayPreservingSelection:YES];
}

- (void)showHideGroupsDrawer
{
	[drawerMgr showHideDrawer];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == [[theSubscriptionMgr splitPostingWindowMgr] window]) {
		[self toggleSplittingWindow];
	} else {
		[postingsTable setDataSource:nil];
		[((NSOutlineView *)postingsTable) setDelegate:nil];
		[groupsTable setDataSource:nil];
		[((NSOutlineView *)groupsTable) setDelegate:nil];
		if (postingHeaderLoader && ![postingHeaderLoader isWorkInProgress]) {
			[postingHeaderLoader gracefullyKillOperations];
			sleep(1);
			[postingHeaderLoader release];
			postingHeaderLoader = nil;
		}
		[[ISOJobMgr sharedJobMgr] removeJobsOfOwner:theSubscriptionMgr];
		[[ISOJobMgr sharedJobMgr] removeJobsOfOwner:self];
		[[postingsTable window] saveFrameUsingName:[NSString stringWithFormat:@"ISOReaderWindow %@", [[theSubscriptionMgr theSubscription] subscriptionName]]];
		if ([graphicalThreadViewMgr owner] == self) {
			[graphicalThreadViewMgr setThread:nil ofOwner:nil];
			[graphicalThreadViewMgr setTarget:nil];
			[graphicalThreadViewMgr setAction:nil];
		}
		[[theSubscriptionMgr splitPostingWindowMgr] close];
		[theSubscriptionMgr subscriptionWindowWillClose];
		theSubscriptionMgr = nil;
		activePosting = nil;
		[postingDisplayMgr setPosting:activePosting];
		activeGroup = nil;
	}
}

/* .............. */
- (void)addGroupsButtonClicked:sender
{
	[serverMgr setSubscriptionMgr:theSubscriptionMgr];
	[serverMgr runSheetForWindow:[postingsTable window]];
}

- (void)showSPAMFilterList
{
	[filterMgr setSubscriptionMgr:theSubscriptionMgr];
	[filterMgr runSheetForWindow:[postingsTable window]];
}

- (void)addGroups
{
	[self addGroupsButtonClicked:self];
}

- (BOOL)isAnyPostingSelected
{
	return ([self numberOfSelectedPostings]>0);
}

- (int)numberOfSelectedPostings
{
	return [postingsTable numberOfSelectedRows];
}

- (ISONewsGroup *)selectedGroup
{
	return activeGroup;
}

/* TABLE TITLE SORTING */

- (void)outlineView:(NSOutlineView *)outlineView didClickOutlineColumn:(NSTableColumn *)tableColumn
{
	[self tableView:outlineView didClickTableColumn:tableColumn];
}

- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn
{
	if (tableView == postingsTable) {
        if ([(NSString *)[tableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SENDER) {
				sortReverse = !sortReverse;
			} else {
				sortReverse = NO;
			}
			lastSortCriteria = K_SORTC_SENDER;
			[self reSortArticles];
			[self _updatePostingDisplay];
        } else if ([(NSString *)[tableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SUBJECT) {
				sortReverse = !sortReverse;
			} else {
				sortReverse = NO;
			}
			lastSortCriteria = K_SORTC_SUBJECT;
			[self reSortArticles];
			[self _updatePostingDisplay];
        } else if ([(NSString *)[tableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_DATE) {
				sortReverse = !sortReverse;
			} else {
				sortReverse = NO;
			}
			lastSortCriteria = K_SORTC_DATE;
			[self reSortArticles];
			[self _updatePostingDisplay];
        } else if ([(NSString *)[tableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if (lastSortCriteria == K_SORTC_SIZE) {
				sortReverse = !sortReverse;
			} else {
				sortReverse = NO;
			}
			lastSortCriteria = K_SORTC_SIZE;
			[self reSortArticles];
			[self _updatePostingDisplay];
        }
	}
}


/* OUTLINE VIEW SUPPORT */
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if ([activeGroup isUnthreadedDisplay]) {
		return [activeGroup postingCountFlat];
	} else {
		return (item == nil) ? [activeGroup postingCount] : [item subPostingCount];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([activeGroup isUnthreadedDisplay]) {
		return NO;
	} else {
		return (item == nil) ? YES : ([item subPostingCount] > 0);
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (item == nil) {
		[[activeGroup postingAtIndex:index] setDisplayEncoding:[theSubscriptionMgr selectedEncoding]];
	} else {
		[[item postingAtIndex:index] setDisplayEncoding:[theSubscriptionMgr selectedEncoding]];
	}
    return (item == nil) ? [activeGroup postingAtIndex:index] : [item postingAtIndex:index];
}

- (NSString *)_makeDisplayableDate:(NSString *)originalDate
{
	BOOL relativeDate = [theSubscriptionMgr viewOptionValueForKey:VOM_PLCDateRelativeDates];
	BOOL shortDate = ([theSubscriptionMgr viewOptionValueForKey:VOM_PLCDateLongShortDates] ==0);
	
	return ISOCreateDisplayableDateFromDateHeader(originalDate, relativeDate, shortDate);
}

- (NSString *)_retrieveNameOnlyFrom:(NSString *)aSender
{
	return ISONameOnlyFromSenderString(aSender);
}

- (id)valueForColumn:(NSTableColumn *)aTableColumn fromItem:(ISONewsPosting *)aPosting
{
	if (aPosting) {
		if ([(NSString *)[aTableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) {
			if ([theSubscriptionMgr viewOptionValueForKey:VOM_PLCFromNameOnly]) {
				return [self _retrieveNameOnlyFrom:[aPosting decodedSender]];
			} else {
				return [aPosting decodedSender];
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) {
			if ([aPosting generation] && ![activeGroup isUnthreadedDisplay]) {
				NSString	*blanks = [NSString stringWithString:@"                                                                                                                                                  "];
				NSMutableString *aString = [NSMutableString string];
				[aString appendString:[blanks substringToIndex:[aPosting generation]*3]];
				[aString appendString:[aPosting decodedSubject]];
				return aString;
			} else {
				return [aPosting decodedSubject];
			}
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) {
			return [self _makeDisplayableDate:[aPosting dateHeader]];
		} else if ([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) {
			if ([aPosting bytesHeader]) {
				return ISOHumanReadableSizeFrom([[aPosting bytesHeader] intValue]);
			} else {
				return ISOHumanReadableSizeFrom([[aPosting linesHeader] intValue] * 60);
			}
		} else {
			return @"";
		}
	} else {
		return @"???????";
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item == nil) {
		return @"???????";
	} else {
		return [self valueForColumn:tableColumn fromItem:item];
	}
}

// Delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn
{
	return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	id	selectionTable = [aNotification object];
	if (selectionTable == groupsTable) {
		[self newsgroupSelected:self];
		[self _updatePostingDisplay];
	} else {
		[postingDisplayMgr tableViewSelectionDidChange:aNotification];
	}
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == postingsTable) {
		[self postingSelected];
	}
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if (item) {
		BOOL isEvenRow = (([postingsTable rowForItem:item] % 2) == 0);
//		if (isEvenRow)  {
//			[cell setBackgroundColor:[NSColor colorWithDeviceRed:(237.0/255.0) green:(243.0/255.0) blue:(254.0/255.0) alpha:1.0]];
//		} else {
//			[cell setBackgroundColor:[NSColor whiteColor]];
//		}
		if ([(NSString *)[tableColumn identifier] compare:@"P_FLAG"] == NSOrderedSame) {
			if ([item isFlagged] && [item isLocked]) {
				[cell setImage:[NSImage imageNamed:@"flagged_locked"]];
			} else if ([item isFlagged]) {
				[cell setImage:[NSImage imageNamed:@"flagged"]];
			} else if ([item isLocked]) {
				[cell setImage:[NSImage imageNamed:@"locked"]];
			} else {
				[cell setImage:nil];
			}
		} else if ([(NSString *)[tableColumn identifier] compare:@"P_LOADED"] == NSOrderedSame) {
			if ([item isBodyLoaded]) {
				[cell setImage:[NSImage imageNamed:@"loaded"]];
			} else {
				[cell setImage:nil];
			}
        } else if ([(NSString *)[tableColumn identifier] compare:@"P_STATUS"] == NSOrderedSame) {
			if ([item isFollowedUp]) {
				[cell setImage:[NSImage imageNamed:@"followed_up"]];
			} else if ([item isForwarded]) {
				[cell setImage:[NSImage imageNamed:@"forwarded"]];
			} else if ([item isReplied]) {
				[cell setImage:[NSImage imageNamed:@"replied"]];
			} else if ([item isThreadRead]) {
				[cell setImage:nil];
			} else {
				[cell setImage:[NSImage imageNamed:@"unread"]];
			}
		} else if ([(NSString *)[tableColumn identifier] compare:@"P_ATTACHMENTS"] == NSOrderedSame) {
			BOOL hasAttachments = [item hasAttachments];
			if (hasAttachments == 1) {
				[cell setImage:[NSImage imageNamed:@"attachment"]];
			} else if (hasAttachments == -1) {
				[cell setImage:[NSImage imageNamed:@"questionmark"]];
			} else {
				[cell setImage:nil];
			}
		} else {
			if ([item isRead]) {
				[cell setTextColor:[[ISOPreferences sharedInstance] prefsReadArticleColor]];
			} else if ([item isAFollowUp]) {
				[cell setTextColor:[[ISOPreferences sharedInstance] prefsReplysColor]];
			} else {
				[cell setTextColor:[[ISOPreferences sharedInstance] prefsUnreadArticleColor]];
			}
		}
	}
}

- (void)outlineViewClicked:sender
{
	int c =	[postingsTable clickedColumn];
	int r = [postingsTable clickedRow];
	if (c>=0 &&  r == -1) { // TITLE Line clicked...
		[self outlineView:postingsTable didClickOutlineColumn:[[postingsTable tableColumns] objectAtIndex:c]];
	}
}

- (void)showSearchPanel
{
	[[NSApplication sharedApplication] beginSheet:searchPanel
			modalForWindow:[postingsTable window]
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
}

- (void)expandAndShowItem:(ISONewsPosting *)aPosting withSelecting:(BOOL)selectFlag
{
	ISONewsPosting	*highestParent = [aPosting highestParent];
	int itemRow = [postingsTable rowForItem:highestParent];
	[postingsTable expandItem:highestParent expandChildren:YES];
	if (selectFlag) {
		itemRow = [postingsTable rowForItem:aPosting];
		[postingsTable scrollRowToVisible:itemRow];
		[postingsTable selectRow:itemRow byExtendingSelection:NO];
	}
}

- (void)expandAndShowItems:(NSArray *)postingArray
{
	int i, count;
	int itemRow;
	
	count = [postingArray count];
	for (i=0;i<count;i++) {
		[self expandAndShowItem:[postingArray objectAtIndex:i] withSelecting:NO];
	}
	if ([postingArray count]) {
		itemRow = [postingsTable rowForItem:[postingArray objectAtIndex:0]];
		[postingsTable scrollRowToVisible:itemRow];
	}
}

- (void)_searchWithStartItem:(ISONewsPosting *)startSearchItem reverse:(BOOL)flag
{
	ISONewsPosting	*foundPosting;

	foundPosting = nil;
	if ([searchPopup indexOfSelectedItem] == 0) {
		foundPosting = [activeGroup searchForSubject:[searchField stringValue] 
								caseSensitive:[searchIgnoreCaseSwitch state]? NO:YES
								startingAtPosting:startSearchItem
								searchReverse:flag];
		searchSearchStartPosting = foundPosting;
	} else {
		foundPosting = [activeGroup searchForSender:[searchField stringValue] 
								caseSensitive:[searchIgnoreCaseSwitch state]? NO:YES
								startingAtPosting:startSearchItem
								searchReverse:flag];
		searchSearchStartPosting = foundPosting;
	}
	if (foundPosting) {
		[self expandAndShowItem:foundPosting withSelecting:YES];
	} else {
		NSBeep();
	}
}

- (void)searchNext
{
	[self _searchWithStartItem:searchSearchStartPosting reverse:NO];
}

- (void)searchPrevious
{
	[self _searchWithStartItem:searchSearchStartPosting reverse:YES];
}

- (void)searchOK:sender
{
	[searchPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:searchPanel];
	[self _searchWithStartItem:[searchStartFromTopSwitch state]? nil:searchSearchStartPosting reverse:NO];
}

- (void)searchCancel:sender
{
	[searchPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:searchPanel];
}

- (ISONewsGroup *)activeGroup
{
	return activeGroup;
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
	if (aBool) {
		[sound release];
	}
}

- (void)expandThread
{
	if (activePosting) {
		[postingsTable expandItem:activePosting expandChildren:YES];
	}
}

- (void)collapseThread
{
	if (activePosting) {
		if ([activePosting firstParent]) {
			[postingsTable collapseItem:[activePosting firstParent] collapseChildren:YES];
		} else {
			[postingsTable collapseItem:activePosting collapseChildren:YES];
		}
	}
}

- (void)expandAllThreads
{
	int	nRows = [postingsTable numberOfRows];
	int i;
	expandingAllThreads = YES;	// So that our auto-scroll feature doesn't kick in
	for (i=nRows-1; i>=0; i--) {
		if (![postingsTable isItemExpanded:[postingsTable itemAtRow:i]]) {
			[postingsTable expandItem:[postingsTable itemAtRow:i] expandChildren:YES];
		}
	}
	expandingAllThreads = NO;
}

- (void)collapsAllThreads
{
	int		nRows = [postingsTable numberOfRows];
	int 	i;
	BOOL	finished = NO;
	
	i = 0;
	while (i<nRows && !finished) {
		id	anItem = [postingsTable itemAtRow:i];
		if (anItem) {
			if ([postingsTable isItemExpanded:anItem]) {
				[postingsTable collapseItem:anItem collapseChildren:YES];
			}
		} else {
			finished = YES;
		}
		i++;
	}
}

- (void)expandThreadsSmart
{	
	NSArray	*topLevelPostings = [activeGroup postings];
	int		i, count;
	
	count = [topLevelPostings count];
	for (i=count-1;i>=0;i--) {
		ISONewsPosting	*aPosting = [topLevelPostings objectAtIndex:i];
		if ([aPosting unreadSubpostingsCountFlat] > 0) {
			[postingsTable expandItem:aPosting expandChildren:YES];
		}
	}
}
- (void)window:(id)window rightArrowPressed:(NSEvent *)theEvent
{
	[self expandThread];
}

- (void)window:(id)window leftArrowPressed:(NSEvent *)theEvent
{
	[self collapseThread];
}

- (void)window:(id)window spaceBarPressed:(NSEvent *)theEvent
{
	id	scroller = [textScrollView verticalScroller];

	if (([((NSString *)[[tabView selectedTabViewItem] identifier]) compare:@"TEXT"] != NSOrderedSame) || ([scroller floatValue] >= 1.0) || ([scroller knobProportion] <= 0.0)) {
		ISONewsPosting *nextPosting = [activeGroup nextUnreadPostingRelativeToPosting:activePosting];
		if (nextPosting) {
			[postingDisplayMgr clearDisplay];
			[self expandAndShowItem:nextPosting withSelecting:YES];
		} else {
			[ISOBeep beep:@"You are already at the end of the postings list, i.e. there are no more unread postings, just believe me. So you can't go further down and I don't really like the idea of wrapping to the top."];
		}
	} else {
		float 	position = [scroller floatValue];
		float	knobProp = [scroller knobProportion];
		position += knobProp + (knobProp / 2.2);
		if (position > 1.0) {
			position = 1.0;
		}
		[scroller setFloatValue:position knobProportion:knobProp];
		[scroller sendAction:[scroller action] to:[scroller target]];
	}
}

- (void)window:(id)window plusKeyPressed:(NSEvent *)theEvent
{
	if ([[ISOPreferences sharedInstance] prefsOpenThreadOnNavigation]) {
		int	rowIndex = [postingsTable selectedRow]+1;
		if (rowIndex < [postingsTable numberOfRows]) {
			ISONewsPosting *item = [postingsTable itemAtRow:rowIndex];
			[postingDisplayMgr clearDisplay];
			[postingsTable expandItem:item expandChildren:YES];
			[postingsTable selectRow:rowIndex byExtendingSelection:NO];
			[postingsTable scrollRowToVisible:rowIndex];
		} else {
			[ISOBeep beep:@"You are already at the end of the postings list. You can't go further down (where do you want to go?)"];
		}
	} else {
		[ISOBeep beep:@"You didn't allow 'Open Thread on Navitation' in the Preferences. You need to do so in order to use the '+' and '-' keys."];
	}
}

- (void)window:(id)window minusKeyPressed:(NSEvent *)theEvent
{
	if ([[ISOPreferences sharedInstance] prefsOpenThreadOnNavigation]) {
		int	rowIndex = [postingsTable selectedRow]-1;
		ISONewsPosting	*oldRowItem = [postingsTable itemAtRow:[postingsTable selectedRow]];
		if (rowIndex >= 0) {
			ISONewsPosting *item = [postingsTable itemAtRow:rowIndex];
			[postingDisplayMgr clearDisplay];
			[postingsTable expandItem:item expandChildren:YES];
			rowIndex = [postingsTable rowForItem:oldRowItem];
			rowIndex--;
			if (rowIndex >= 0) {
				[postingsTable selectRow:rowIndex byExtendingSelection:NO];
				[postingsTable scrollRowToVisible:rowIndex];
			}
		} else {
			[ISOBeep beep:@"You are already at the beginning of the postings list. You can't go further up."];
		}
	} else {
		[ISOBeep beep:@"You didn't allow 'Open Thread on Navitation' in the Preferences. You need to do so in order to use the '+' and '-' keys."];
	}
}

- (void)flagSelection
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markThread:aPosting asFlagged:YES];
	}
	[self _updatePostingDisplayPreservingSelection:NO];
}

- (void)unflagSelection
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;

	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[activeGroup markThread:aPosting asFlagged:NO];
	}
	[self _updatePostingDisplayPreservingSelection:NO];
}


- (void)removeSelection
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSArray			*allObjects;  // because we have to start from the end
	int 			i, count;
	ISONewsPosting	*aPosting;
	
	allObjects = [enumerator allObjects];
	count = [allObjects count];
	for (i=count-1; i>=0; i--) {
		aRowId = [allObjects objectAtIndex:i];
		aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		if ([activeGroup removePosting:aPosting]) {
			if (aPosting == activePosting) {
				activePosting = nil;
				[postingDisplayMgr setPosting:activePosting];
			}
		}
	}
	activePosting = nil;
	[postingDisplayMgr setPosting:activePosting];
	[self reSortArticles];
	[self _reflectDisplayChanges];
	[postingsTable deselectAll:self];
}

- (void)addSelectionToDownloadsWithSubThreads:(BOOL )withSubThreads
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSArray			*allObjects;  // because we have to start from the end
	int 			i, count;
	ISONewsPosting	*aPosting;
	BOOL			added = NO;
	
	allObjects = [enumerator allObjects];
	count = [allObjects count];
	for (i=count-1; i>=0; i--) {
		aRowId = [allObjects objectAtIndex:i];
		aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		if (withSubThreads) {
			NSArray *anArray = [aPosting subPostingsFlat];
			if ([anArray count]>0) {
				[[ISOOfflineMgr sharedOfflineMgr] addToDownloadsFromArray:anArray];
			}
		} else {
			[[ISOOfflineMgr sharedOfflineMgr] addToDownloads:aPosting];
		}
		added = YES;
	}
	if (added) {
		[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindow];
		[[ISOOfflineMgr sharedOfflineMgr] setDownloadIncoming:YES];
		[[ISOOfflineMgr sharedOfflineMgr] setUploadOutgoing:YES];
		[[ISOOfflineMgr sharedOfflineMgr] setExtractBinaries:NO];
	} else {
		[ISOBeep beep:@"There was no selection to add to the downloads"];
	}
}

- (void)addSelectionToDownloads
{
	[self addSelectionToDownloadsWithSubThreads:NO];
}

- (void)followUpPosting:sender
{
	[theSubscriptionMgr followUp];
}

- (void)replyAuthor:sender
{
	[theSubscriptionMgr replyAuthor];
}

- (void)markRead:sender
{
	[self markSelectedPostingRead];
}

- (void)markUnread:sender
{
	[self markSelectedPostingUnread];
}

- (void)flagSelection:sender
{
	[self flagSelection];
}

- (void)unflagSelection:sender
{
	[self unflagSelection];
}

- (void)saveSelection:sender
{
	[ISOBeep beep:@"'Save Selection' not yet implemented!"];
}

- (void)downloadSelection:sender
{
	[self addSelectionToDownloads];
}

- (void)downloadSelectionWithThreads:sender
{
	[self addSelectionToDownloadsWithSubThreads:YES];
}

- (void)removeSelection:sender
{
	[self removeSelection];
}

/* **************************** */
- (void)addSenderToFriendsList:sender
{
	if ([self numberOfSelectedPostings]==1) {
		[friendsFavController addToFriends:[activePosting decodedSender] inWindow:[postingsTable window]];
	} else {
		[ISOBeep beep:@"You can add one friend at a time. Please choose a single posting and try again."];
	}
}

- (void)addSubjectToFavorites:sender
{
	if ([self numberOfSelectedPostings]==1) {
		[friendsFavController addToSubjects:[activePosting decodedSubject] inWindow:[postingsTable window]];
	} else {
		[ISOBeep beep:@"You can add one subject at a time. Please choose a single posting and try again."];
	}
}

- (void)addSPAMFilterWithSubject:sender
{
	[filterMgr setSubscriptionMgr:theSubscriptionMgr];
	if ([self numberOfSelectedPostings]==1) {
		NSString	*subject = [activePosting decodedSubject];
		[filterMgr addSPAMFilterWithSubject:subject inWindow:[postingsTable window]];
	} else {
		[ISOBeep beep:@"You can add one SPAM filter at a time. Please choose a single posting and try again."];
	}
}

- (void)addSPAMFilterWithSender:sender
{
	[filterMgr setSubscriptionMgr:theSubscriptionMgr];
	if ([self numberOfSelectedPostings]==1) {
		NSString	*sender = [activePosting decodedSender];
		[filterMgr addSPAMFilterWithSender:sender inWindow:[postingsTable window]];
	} else {
		[ISOBeep beep:@"You can add one SPAM filter at a time. Please choose a single posting and try again."];
	}
}

- (void)manageFavorites
{
	[friendsFavController runSheetForFriends:NO inWindow:[postingsTable window]];
}

- (void)manageFriends
{
	[friendsFavController runSheetForFriends:YES inWindow:[postingsTable window]];
}

- (void)filterForFavoriteSubjects
{
	if ([activeGroup isFilteredForSubjects]) {
		[activeGroup removeSubjectsFilter];
	} else {
		[activeGroup filterForSubjects:[[ISOSubjectsMgr sharedSubjectsMgr] subjects]];
	}
	[self reSortArticles];
	[self _updatePostingDisplay];
}

- (void)filterForFriends
{
	if ([activeGroup isFilteredForSenders]) {
		[activeGroup removeSendersFilter];
	} else {
		[activeGroup filterForSenders:[[ISOFriendsMgr sharedFriendsMgr] friends]];
	}
	[self reSortArticles];
	[self _updatePostingDisplay];
}

- (void)toggleThreadedDisplay
{
	BOOL newThreadingStatus = ![activeGroup isUnthreadedDisplay];
	[activeGroup setIsUnthreadedDisplay:newThreadingStatus];
	[self reSortArticles];
	[self _updatePostingDisplay];
	[theSubscriptionMgr subscriptionDataChanged];
	[[theSubscriptionMgr theSubscription] setIsUnthreadedDisplay:newThreadingStatus];
}

- (void)toggleThreadFocus
{
	if ([activeGroup isFocusingOnThread]) {
		[activeGroup unfocusOnThread];
		[self _updatePostingDisplay];
	} else {
		if (activePosting) {
			ISONewsPosting	*highestParent = [activePosting highestParent];
			int				row;
			
			[activeGroup focusOnThread:activePosting];
			[self _updatePostingDisplay];
			[postingsTable expandItem:highestParent expandChildren:YES];
			[postingsTable reloadItem:highestParent reloadChildren:YES];
			row = [postingsTable rowForItem:activePosting];
			[postingsTable selectRow:row byExtendingSelection:NO];
		} else {
			[ISOBeep beep:@"For now, you can only focus on one thread at the same time!"];
		}
	}
}

- (void)toggleHideRead
{
	if ([activeGroup isHidingRead]) {
		[activeGroup unhideRead];
		[[theSubscriptionMgr theSubscription] setShowUnreadOnly:NO];
		[theSubscriptionMgr subscriptionDataChanged];
	} else {
		[activeGroup hideRead];
		[[theSubscriptionMgr theSubscription] setShowUnreadOnly:YES];
		[theSubscriptionMgr subscriptionDataChanged];
	}
	[self reSortArticles];
	[self _updatePostingDisplay];
}

- (void)gtvPostingSelected:sender
{	
	ISONewsPosting	*selectedPosting = [graphicalThreadViewMgr selectedPosting];
	if (selectedPosting) {
		ISONewsPosting	*highestParent = [selectedPosting highestParent];
		if (activePosting) {
			[activePosting setIsSelected:NO];
			[graphicalThreadViewMgr redisplayPosting:activePosting];
		}
		[selectedPosting setIsSelected:YES];

		[postingsTable expandItem:highestParent expandChildren:YES];
		[postingsTable reloadItem:highestParent reloadChildren:YES];
		[((NSOutlineView *)postingsTable) selectItem:selectedPosting];
		[graphicalThreadViewMgr redisplayPosting:selectedPosting];
	} else {
		NSBeep();
	}
}

- (void)toggleGraphicalTV
{
	[graphicalThreadViewMgr toggleDrawer];
	if ([graphicalThreadViewMgr isShowingGTV]) {
		if (([activePosting highestParent] != activePosting) || ([activePosting hasSubPostings])) {
			[graphicalThreadViewMgr setThread:[NSArray arrayWithObjects:[activePosting highestParent], nil] ofOwner:self];
			[graphicalThreadViewMgr setTarget:self];
			[graphicalThreadViewMgr setAction:@selector(gtvPostingSelected:)];
		} else {
			[graphicalThreadViewMgr setThread:nil ofOwner:self];
			[graphicalThreadViewMgr setTarget:nil];
			[graphicalThreadViewMgr setAction:nil];
		}
	}
	[[theSubscriptionMgr theSubscription] setGTVIsShown:[graphicalThreadViewMgr isShowingGTV]];
	[theSubscriptionMgr subscriptionDataChanged];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	return ([self numberOfSelectedPostings]>0);
}

- (BOOL)isShowingDrawer
{
	return [drawerMgr isShowingDrawer];
}

- (void)nextGroup
{
	int	numGroups = [[[theSubscriptionMgr theSubscription] groups] count];
	int	rowToSelect;
	int	selectedRow = [groupsTable selectedRow];
	if (selectedRow == numGroups-1) {
		rowToSelect = 0;
	} else {
		rowToSelect = selectedRow + 1;
	}
	[groupsTable scrollRowToVisible:rowToSelect];
	[groupsTable selectRow:rowToSelect byExtendingSelection:NO];
}

- (void)previousGroup
{
	int	numGroups = [[[theSubscriptionMgr theSubscription] groups] count];
	int	rowToSelect;
	int	selectedRow = [groupsTable selectedRow];
	if (selectedRow == 0) {
		rowToSelect = numGroups - 1;
	} else {
		rowToSelect = selectedRow - 1;
	}
	[groupsTable scrollRowToVisible:rowToSelect];
	[groupsTable selectRow:rowToSelect byExtendingSelection:NO];
}

- (void)nextPosting
{
	int	rowIndex = [postingsTable selectedRow]+1;
	if (rowIndex >= [postingsTable numberOfRows]) {
		rowIndex = 0;
	}
	if (rowIndex < [postingsTable numberOfRows]) {
		[postingsTable selectRow:rowIndex byExtendingSelection:NO];
		[postingsTable scrollRowToVisible:rowIndex];
	}
}

- (void)previousPosting
{
	int	rowIndex = [postingsTable selectedRow]-1;
	if (rowIndex < 0) {
		rowIndex = [postingsTable numberOfRows]-1;
	}
	if (rowIndex >= 0) {
		[postingsTable selectRow:rowIndex byExtendingSelection:NO];
		[postingsTable scrollRowToVisible:rowIndex];
	}
}


- (void)window:(id)sender otherKeyPressed:(NSString *)aKey
{
	if ([aKey caseInsensitiveCompare:@"F"] == NSOrderedSame) {
		[self filterForFriends];
	} else if ([aKey caseInsensitiveCompare:@"S"] == NSOrderedSame) {
		[self filterForFavoriteSubjects];
	} else if ([aKey caseInsensitiveCompare:@"Z"] == NSOrderedSame) {
		[self toggleThreadFocus];
	} else if ([aKey caseInsensitiveCompare:@"H"] == NSOrderedSame) {
		[self toggleHideRead];
	} else if ([aKey compare:@"g"] == NSOrderedSame) {
		[self nextGroup];
	} else if ([aKey compare:@"G"] == NSOrderedSame) {
		[self previousGroup];
	} else if ([aKey caseInsensitiveCompare:@"T"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:0];
	} else if ([aKey caseInsensitiveCompare:@"P"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:1];
	} else if ([aKey caseInsensitiveCompare:@"V"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:2];
	} else if ([aKey caseInsensitiveCompare:@"M"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:3];
	} else if ([aKey caseInsensitiveCompare:@"O"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:4];
	} else if ([aKey caseInsensitiveCompare:@"R"] == NSOrderedSame) {
		[tabView selectTabViewItemAtIndex:5];
	} else if ([aKey compare:@"1"] == NSOrderedSame) {
		[postingsTable selectRow:0 byExtendingSelection:NO];
		[postingsTable scrollRowToVisible:0];
	} else if ([aKey compare:@"0"] == NSOrderedSame) {
		[self catchUp];
	} else if ([aKey compare:@"/"] == NSOrderedSame) {
		[self showSearchPanel];
	} else if ([aKey caseInsensitiveCompare:@"D"] == NSOrderedSame) {
		[postingDisplayMgr autoSaveDependingOnCurrentView];
	} else if ([aKey caseInsensitiveCompare:@"J"] == NSOrderedSame) {
		[self nextPosting];
	} else if ([aKey caseInsensitiveCompare:@"K"] == NSOrderedSame) {
		[self previousPosting];
	} else if ([aKey hasPrefix:@"\x7f"]) {	// Backspace/Delete
		[self removeSelection];
	} else if ([aKey caseInsensitiveCompare:@"."] == NSOrderedSame) {
		[self markGroupRead];
		[self catchUp];
		[self nextGroup];
	} else if ([aKey caseInsensitiveCompare:@"B"] == NSOrderedSame) {
	} else if ([aKey caseInsensitiveCompare:@"A"] == NSOrderedSame) {
	}
}

- (void)preferencesListFontChanged:(NSNotification *)notification
{
	NSFont			*aFont = [[ISOPreferences sharedInstance] prefsListviewFont];
	NSArray			*anArray;
	NSTableColumn	*aTableColumn;
	int				i, count;	
	NSTextFieldCell	*aCell;

	if ([postingsTable font] != aFont) {
		[postingsTable setFont:aFont];
		[postingsTable setRowHeight:[aFont defaultLineHeightForFont] * 0.95];
		anArray = [postingsTable tableColumns];
		count = [anArray count];
		for (i=0;i<count;i++) {
			aTableColumn = [anArray objectAtIndex:i];
			if (([(NSString *)[aTableColumn identifier] compare:@"P_SENDER"] == NSOrderedSame) ||
				([(NSString *)[aTableColumn identifier] compare:@"P_SUBJECT"] == NSOrderedSame) ||
				([(NSString *)[aTableColumn identifier] compare:@"P_DATE"] == NSOrderedSame) ||
				([(NSString *)[aTableColumn identifier] compare:@"P_SIZE"] == NSOrderedSame) ){
				aCell = [aTableColumn dataCell];
				if ([aCell font] != aFont) {
					[aCell setFont:aFont];
				}
			}
		}
		[postingsTable displayIfNeeded];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	if ([aNotification object] == [self window]) {
		[[ISOViewOptionsMgr sharedViewOptionsMgr] activeWindowChanged];
	}
}

- (void)encodingChanged
{
	if (activePosting) {
		[postingDisplayMgr encodingChangedTo:[theSubscriptionMgr selectedEncoding]];
	}
}

- (void)connectTabViewToSplitview
{
	[tabView removeFromSuperview];
	[splitView addSubview:tabView];
	[splitView adjustSubviews];
	[[[theSubscriptionMgr splitPostingWindowMgr] window] orderOut:self];
}

- (void)disconnectTabViewFromSplitview
{
	NSRect aRect;

	[tabView removeFromSuperview];
	[[theSubscriptionMgr splitPostingWindowMgr] showWindow:self];
	aRect = [[[[theSubscriptionMgr splitPostingWindowMgr] window] contentView] frame];
	aRect.origin.x = aRect.origin.y = 0;
	[tabView setFrame:aRect];
	[tabView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[[[[theSubscriptionMgr splitPostingWindowMgr] window] contentView] addSubview:tabView];
	[[[[theSubscriptionMgr splitPostingWindowMgr] window] contentView] setAutoresizesSubviews:YES];
}

- (void)toggleSplittingWindow
{
	if ([tabView superview] != [[[theSubscriptionMgr splitPostingWindowMgr] window] contentView]) {
		[self disconnectTabViewFromSplitview];
		[[theSubscriptionMgr theSubscription] setTabViewDisconnected:YES];
	} else {
		[self connectTabViewToSplitview];
		[[theSubscriptionMgr theSubscription] setTabViewDisconnected:NO];
	}
}

- (BOOL)windowShouldClose:(id)sender
{
	return YES;
}

-(void)_addTableColumn:(NSString *)identifier minW:(float)minW maxW:(float)maxW curW:(float)curW editable:(BOOL)editable resizable:(BOOL)resizable ha:(NSTextAlignment)ha ca:(NSTextAlignment)ca
{
	NSMutableArray		*displayedColumns = [[theSubscriptionMgr theSubscription] displayedColumns];
	NSTableColumn		*columnToAdd = [[[NSTableColumn alloc] initWithIdentifier:identifier] autorelease];
	NSMutableDictionary	*oneColumn;
	BOOL				columnFound = NO;
	int					i, count;

	[ISOActiveLogger logWithDebuglevel:4 :@"Adding column: %@", identifier];
	[columnToAdd setMinWidth:minW];
	[columnToAdd setMaxWidth:maxW];
	[columnToAdd setWidth:curW];
	[columnToAdd setEditable:editable];
	[columnToAdd setResizable:resizable];
	[[columnToAdd headerCell] setAlignment:ha];
	[[columnToAdd dataCell] setAlignment:ca];
	[postingsTable addTableColumn:columnToAdd];

	count = [displayedColumns count];
	for (i=0;i<count;i++) {
		oneColumn = [displayedColumns objectAtIndex:i];
		if ([((NSString *)[oneColumn objectForKey:@"Identifier"]) compare:identifier] == NSOrderedSame) {
			columnFound = YES;
			break;
		}
	}
	if (!columnFound) {
		oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
						identifier, @"Identifier",
						[NSNumber numberWithFloat:minW], @"MinWidth",
						[NSNumber numberWithFloat:maxW], @"MaxWidth",
						[NSNumber numberWithFloat:curW], @"CurWidth",
						[NSNumber numberWithBool:editable], @"IsEditable",
						[NSNumber numberWithBool:resizable], @"IsResizable",
						[NSNumber numberWithInt:ha], @"HeaderAlignment",
						[NSNumber numberWithInt:ca], @"ContentAlignment",
						nil];
		[[theSubscriptionMgr theSubscription] addDisplayedColumn:oneColumn];
	} else { // Move the column to the end...
//		[[theSubscriptionMgr theSubscription] moveColumnWithIdentifier:identifier toPosition:count-1];
	}
}

- (void)_addRemoveTableColumn:(NSString *)colIdentifier add:(BOOL)add
{
	NSTableColumn	*existingColumn = [postingsTable tableColumnWithIdentifier:colIdentifier];
	
	if (add && existingColumn) {
		return; // It is already there
	} else if (!add && existingColumn) {
		[postingsTable removeTableColumn:existingColumn];
		[postingsTable sizeLastColumnToFit];
		[[theSubscriptionMgr theSubscription] removeDisplayedColumnWithIdentifier:colIdentifier];
		[theSubscriptionMgr subscriptionDataChanged];
	} else if (add) {
		if ([colIdentifier compare:@"P_LOADED"] == NSOrderedSame) {
			[self _addTableColumn:@"P_LOADED" minW:12 maxW:16 curW:16 editable:NO resizable:NO ha:NSCenterTextAlignment ca:NSCenterTextAlignment];
		} else if ([colIdentifier compare:@"P_STATUS"] == NSOrderedSame) {
			[self _addTableColumn:@"P_STATUS" minW:12 maxW:16 curW:16 editable:NO resizable:NO ha:NSCenterTextAlignment ca:NSCenterTextAlignment];
		} else if ([colIdentifier compare:@"P_FLAG"] == NSOrderedSame) {
			[self _addTableColumn:@"P_FLAG" minW:12 maxW:16 curW:16 editable:NO resizable:NO ha:NSCenterTextAlignment ca:NSCenterTextAlignment];
		} else if ([colIdentifier compare:@"P_SUBJECT"] == NSOrderedSame) {
			[self _addTableColumn:@"P_SUBJECT" minW:40 maxW:1000 curW:268 editable:NO resizable:YES ha:NSLeftTextAlignment ca:NSLeftTextAlignment];
		} else if ([colIdentifier compare:@"P_SENDER"] == NSOrderedSame) {
			[self _addTableColumn:@"P_SENDER" minW:40 maxW:1000 curW:107 editable:NO resizable:YES ha:NSLeftTextAlignment ca:NSLeftTextAlignment];
		} else if ([colIdentifier compare:@"P_DATE"] == NSOrderedSame) {
			[self _addTableColumn:@"P_DATE" minW:40 maxW:1000 curW:86 editable:NO resizable:YES ha:NSLeftTextAlignment ca:NSLeftTextAlignment];
		} else if ([colIdentifier compare:@"P_SIZE"] == NSOrderedSame) {
			[self _addTableColumn:@"P_SIZE" minW:26 maxW:1000 curW:43 editable:NO resizable:YES ha:NSLeftTextAlignment ca:NSRightTextAlignment];
		} else if ([colIdentifier compare:@"P_ATTACHMENTS"] == NSOrderedSame) {
			[self _addTableColumn:@"P_ATTACHMENTS" minW:12 maxW:16 curW:16 editable:NO resizable:NO ha:NSCenterTextAlignment ca:NSCenterTextAlignment];
		}
		[self setupTableColumnHeaders];
	}

}

- (void)_createDefaultColumnDisplay:(NSMutableArray *)displayedColumns
{
	NSMutableDictionary	*oneColumn;
	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"OUTLINE_COLUMN", @"Identifier",
					[NSNumber numberWithFloat:12], @"MinWidth",
					[NSNumber numberWithFloat:16], @"MaxWidth",
					[NSNumber numberWithFloat:16], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:NO], @"IsResizable",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];


	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_LOADED", @"Identifier",
					[NSNumber numberWithFloat:12], @"MinWidth",
					[NSNumber numberWithFloat:16], @"MaxWidth",
					[NSNumber numberWithFloat:16], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:NO], @"IsResizable",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_STATUS", @"Identifier",
					[NSNumber numberWithFloat:12], @"MinWidth",
					[NSNumber numberWithFloat:16], @"MaxWidth",
					[NSNumber numberWithFloat:16], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:NO], @"IsResizable",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_FLAG", @"Identifier",
					[NSNumber numberWithFloat:12], @"MinWidth",
					[NSNumber numberWithFloat:16], @"MaxWidth",
					[NSNumber numberWithFloat:16], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:NO], @"IsResizable",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_ATTACHMENTS", @"Identifier",
					[NSNumber numberWithFloat:12], @"MinWidth",
					[NSNumber numberWithFloat:16], @"MaxWidth",
					[NSNumber numberWithFloat:16], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:NO], @"IsResizable",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_SUBJECT", @"Identifier",
					[NSNumber numberWithFloat:40], @"MinWidth",
					[NSNumber numberWithFloat:1000], @"MaxWidth",
					[NSNumber numberWithFloat:268], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:YES], @"IsResizable",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_SENDER", @"Identifier",
					[NSNumber numberWithFloat:40], @"MinWidth",
					[NSNumber numberWithFloat:1000], @"MaxWidth",
					[NSNumber numberWithFloat:107], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:YES], @"IsResizable",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_DATE", @"Identifier",
					[NSNumber numberWithFloat:40], @"MinWidth",
					[NSNumber numberWithFloat:1000], @"MaxWidth",
					[NSNumber numberWithFloat:86], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:YES], @"IsResizable",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

	oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					@"P_SIZE", @"Identifier",
					[NSNumber numberWithFloat:26], @"MinWidth",
					[NSNumber numberWithFloat:43], @"MaxWidth",
					[NSNumber numberWithFloat:43], @"CurWidth",
					[NSNumber numberWithBool:NO], @"IsEditable",
					[NSNumber numberWithBool:YES], @"IsResizable",
					[NSNumber numberWithInt:NSLeftTextAlignment], @"HeaderAlignment",
					[NSNumber numberWithInt:NSRightTextAlignment], @"ContentAlignment",
					nil];
	[displayedColumns addObject:oneColumn];

}

- (void)initializeTableColumns
{
	int					i, count, outlineColumnPosition = -1;
	NSMutableArray		*displayedColumns = [[theSubscriptionMgr theSubscription] displayedColumns];
	int					minW, maxW, curW;
	BOOL				editable, resizable;
	NSTextAlignment		ha, ca;
	NSString			*oneKey;
	NSDictionary		*oneColumn;

	initializingTable = YES;
	[postingsTable setAutosaveTableColumns:NO];
	if ([displayedColumns count] == 0) {
		[self _createDefaultColumnDisplay:displayedColumns];
		[theSubscriptionMgr subscriptionDataChanged];
	} else {
		BOOL outlineColumnFound = NO;
		count = [displayedColumns count];
		for (i=0;i<count;i++) {
			oneColumn = [displayedColumns objectAtIndex:i];
			oneKey = [oneColumn objectForKey:@"Identifier"];
			if ([oneKey compare:@"OUTLINE_COLUMN"] == NSOrderedSame) {
				outlineColumnFound = YES;
				break;
			}
		}
		if (!outlineColumnFound) {
			NSMutableDictionary	*oneColumn;
			oneColumn = [NSMutableDictionary dictionaryWithObjectsAndKeys:
							@"OUTLINE_COLUMN", @"Identifier",
							[NSNumber numberWithFloat:12], @"MinWidth",
							[NSNumber numberWithFloat:16], @"MaxWidth",
							[NSNumber numberWithFloat:16], @"CurWidth",
							[NSNumber numberWithBool:NO], @"IsEditable",
							[NSNumber numberWithBool:NO], @"IsResizable",
							[NSNumber numberWithInt:NSCenterTextAlignment], @"HeaderAlignment",
							[NSNumber numberWithInt:NSCenterTextAlignment], @"ContentAlignment",
							nil];
			[displayedColumns insertObject:oneColumn atIndex:0];
		}
		[theSubscriptionMgr subscriptionDataChanged];
	}
	count = [displayedColumns count];
	for (i=0;i<count;i++) {
		oneColumn = [displayedColumns objectAtIndex:i];
		oneKey = [oneColumn objectForKey:@"Identifier"];
		if ([oneKey compare:@"OUTLINE_COLUMN"] != NSOrderedSame) {
			if ([postingsTable tableColumnWithIdentifier:oneKey]) {
				[postingsTable removeTableColumn:[postingsTable tableColumnWithIdentifier:oneKey]];
			}
			minW = [[oneColumn objectForKey:@"MinWidth"] floatValue];
			maxW = [[oneColumn objectForKey:@"MaxWidth"] floatValue];
			curW = [[oneColumn objectForKey:@"CurWidth"] floatValue];
			editable = NO;
			resizable = [[oneColumn objectForKey:@"IsResizable"] boolValue];
			ha = [[oneColumn objectForKey:@"HeaderAlignment"] intValue];
			ca = [[oneColumn objectForKey:@"ContentAlignment"] intValue];
			[self _addTableColumn:oneKey minW:minW 
										maxW:maxW 
										curW:curW 
										editable:editable 
										resizable:resizable 
										ha:ha 
										ca:ca];

		} else {
			outlineColumnPosition = i;
		}
	}
	if (outlineColumnPosition > 0) {
		[postingsTable moveColumn:outlineColumnPosition toColumn:0];
	}
	[self setupTableColumnHeaders];
	[postingsTable setFrame:NSMakeRect(0,0,[postingsTableScrollView contentSize].width, [postingsTableScrollView contentSize].height)];
	[postingsTable tile];
	initializingTable = NO;
}

- (void)viewOption:(NSString *)viewOption changedTo:(int)value
{
	if ([viewOption compare:VOM_PLCFrom] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_SENDER" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCDate] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_DATE" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCSubject] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_SUBJECT" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCLines] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_SIZE" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCRead] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_STATUS" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCLoaded] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_LOADED" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCFlag] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_FLAG" add:(value==1)];
	} else if ([viewOption compare:VOM_PLCAttachments] == NSOrderedSame) {
		[self _addRemoveTableColumn:@"P_ATTACHMENTS" add:(value==1)];
	}
}

- (void)groupChangedTo:(NSString *)groupName
{
	NSArray	*groups = [[theSubscriptionMgr theSubscription] groups];
	BOOL	found = NO;
	int		i, count;
	
	count = [groups count];
	i=0;
	while (i<count && !found) {
		if ([[[groups objectAtIndex:i] groupName] compare:groupName] == NSOrderedSame) {
			[groupsTable selectRow:i byExtendingSelection:NO];
			found = YES;
		}
		i++;
	}
}


/* ****** */
- (id)markMenu
{
	return markMenu;
}

- (id)encodingMenu
{
	return encodingMenu;
}

- (id)groupsMenu
{
	return groupsMenu;
}

- (id)filterGroup
{
	return filterGroup;
}

- (id)filterGroupMenu
{
	return filterGroupMenu;
}

- (id)filterGroupField
{
	return filterGroupField;
}

- (void)filterForToolbarSelection:sender
{
	int			isFromFilter = ([[filterGroupMenu selectedItem] tag] == 0);
	NSString	*filterText = [NSString stringWithString:[filterGroupField stringValue]];
	if (activeGroup) {
		[activeGroup cleanFiltersAndWait];
		if ([filterText length]) {
			if (isFromFilter) {
				[activeGroup filterForSenders:[NSArray arrayWithObjects:filterText, nil]];
			} else {
				[activeGroup filterForSubjects:[NSArray arrayWithObjects:filterText, nil]];
			}
		} else {
			[activeGroup reApplyFilters];
		}
		[self _updatePostingDisplay];
	} else {
		[ISOBeep beep:@"There is no group to filter postings in. Please choose a group and try again."];
	}
}


- (void)outlineViewColumnDidMove:(NSNotification *)notification
{
	if ([notification object] == postingsTable) {
		NSNumber		*newPosition;
		NSTableColumn	*aColumn;
		
		newPosition = [[notification userInfo] objectForKey:@"NSNewColumn"];
		aColumn = [[[notification object] tableColumns] objectAtIndex:[newPosition intValue]];
		
		if (aColumn) {
			[[theSubscriptionMgr theSubscription] moveColumnWithIdentifier:[aColumn identifier] toPosition:[newPosition intValue]];
			[theSubscriptionMgr subscriptionDataChanged];
		}
	}
}

- (void)outlineViewColumnDidResize:(NSNotification *)notification
{
	if (([notification object] == postingsTable) && (!initializingTable)) {
		NSArray			*anArray;
		NSTableColumn	*aTableColumn;
		int				i, count;	
		
		anArray = [postingsTable tableColumns];
		count = [anArray count];
		for (i=0;i<count;i++) {
			aTableColumn = [anArray objectAtIndex:i];
			[[theSubscriptionMgr theSubscription] setWidth:[aTableColumn width] ofColumnWithIdentifier:[aTableColumn identifier]];
		}
		[theSubscriptionMgr subscriptionDataChanged];
	}
}

- (void)toggleTabviewTabs
{
	if ([tabView tabViewType] == NSNoTabsNoBorder) {
		[tabView setTabViewType:NSTopTabsBezelBorder];
		[[theSubscriptionMgr theSubscription] setTabsAreShown:YES];
	} else {
		[tabView setDrawsBackground:NO];
		[tabView setTabViewType:NSNoTabsNoBorder];
		[[theSubscriptionMgr theSubscription] setTabsAreShown:NO];
	}
}

- (void)_removExpiredArticles
{
	NSMutableArray	*groupsToCheck = [NSMutableArray array];
	int				i, j, count, jCount;
	NSCalendarDate	*expiryDate;
	double			dateToCompare;
	NSMutableArray	*postingsToRemove = [NSMutableArray array];
	BOOL			wasOffline = [[ISOPreferences sharedInstance] isOffline];
	
	[[NSApplication sharedApplication] beginSheet:expireStatusWindow
			modalForWindow:[self window]
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];

	expiryDate = [[NSCalendarDate calendarDate] dateByAddingYears:0 
											months:0
											days:-[[theSubscriptionMgr theSubscription] expirePostingsAfterDays]
											hours:0
											minutes:0
											seconds:0];


	dateToCompare = [[expiryDate descriptionWithCalendarFormat:@"%Y%m%d000000"] doubleValue];
	
	if (removeExpiredArticlesInGroup) {
		[groupsToCheck addObject:activeGroup];
	} else {
		[groupsToCheck addObjectsFromArray:[[theSubscriptionMgr theSubscription] groups]];
	}
	count = [groupsToCheck count];
	for (i=0;i<count;i++) {
		ISONewsGroup	*thisGroup = [groupsToCheck objectAtIndex:i];
		NSArray			*allPostings;

		[expireStatusField setStringValue:[NSString stringWithFormat:@"%@ %@", 
				NSLocalizedString(@"Checking:", @""),
				[thisGroup groupName]]];
		[expireStatusField display];
		[expireStatusIndicator setIndeterminate:YES];
		allPostings = [thisGroup postingsFlat];
		jCount = [allPostings count];
		for (j=0;j<jCount;j++) {
			ISONewsPosting	*thisPosting = [allPostings objectAtIndex:j];
			double thisPostingDate = [[thisPosting comparableDate] doubleValue];
			if (thisPostingDate < dateToCompare) { // It IS older
				[postingsToRemove addObject:thisPosting];
			}
			[expireStatusIndicator animate:self];
			[expireStatusIndicator display];
		}
		jCount = [postingsToRemove count];
		[expireStatusIndicator setIndeterminate:NO];
		[expireStatusIndicator setDoubleValue:0.0];
		[expireStatusIndicator setMaxValue:jCount];
		[expireStatusIndicator setMinValue:0.0];
		[expireStatusField setStringValue:[NSString stringWithFormat:@"%@ %@", 
				NSLocalizedString(@"Expiring:", @""),
				[thisGroup groupName]]];
		[expireStatusField display];
		for (j=jCount-1;j>=0;j--) {
			ISONewsPosting *thisPosting = [postingsToRemove objectAtIndex:j];
			[thisGroup removeOnePostingWithoutSubpostings:thisPosting];
			[postingsToRemove removeObject:thisPosting];
			[expireStatusIndicator incrementBy:1.0];
			[expireStatusIndicator display];
		}
	}
	[expireStatusWindow orderOut:self];
	[[NSApplication sharedApplication] endSheet:expireStatusWindow];
	[self _reflectDisplayChanges];
	[[ISOPreferences sharedInstance] setIsOffline:wasOffline];
}

- (void)expireRemoveClicked:sender
{
	int	returnCode;
	
	[[theSubscriptionMgr theSubscription] setExpirePostingsAfter:[expireField intValue]];
	[expirePanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:expirePanel];
	returnCode = NSRunAlertPanel(NSLocalizedString(@"Remove Expired Postings", @""),
		NSLocalizedString(@"Are you sure you want to remove the expired postings? This action cannot be undone or interrupted. This will also switch to offline mode while expiring.", @""),
		NSLocalizedString(@"Remove", @""),
		nil,
		NSLocalizedString(@"Cancel", @"")	);
	if (returnCode == NSAlertDefaultReturn) {
		[self _removExpiredArticles];
	}
}

- (void)expireCancelClicked:sender
{
	[expirePanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:expirePanel];
}

- (void)removeExpiredArticlesInGroup
{
	removeExpiredArticlesInGroup = YES;
	[expireField setIntValue:[[theSubscriptionMgr theSubscription] expirePostingsAfterDays]];
	[expireTitleField setStringValue:NSLocalizedString(@"Remove expired articles in group", @"")];
	[[NSApplication sharedApplication] beginSheet:expirePanel
			modalForWindow:[postingsTable window]
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
}

- (void)removeExpiredArticlesInSubscription
{
	removeExpiredArticlesInGroup = NO;
	[expireField setIntValue:[[theSubscriptionMgr theSubscription] expirePostingsAfterDays]];
	[expireTitleField setStringValue:NSLocalizedString(@"Remove expired articles in subscription", @"")];
	[[NSApplication sharedApplication] beginSheet:expirePanel
			modalForWindow:[postingsTable window]
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
}

- (void)toggleFullHeadersView
{
	[postingDisplayMgr showPosting];
}


- (void)offlineInGroup
{
	if (activeGroup) {
		[[ISOOfflineMgr sharedOfflineMgr] addGroupToGroupDownloads:activeGroup];
		[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindow];
		[[ISOOfflineMgr sharedOfflineMgr] sendReceiveAndGoOffline:self];
	} else {
		[ISOBeep beep:@"Please select a group first!"];
	}
}

- (void)offlineInSubscription
{
	NSArray	*groups = [[theSubscriptionMgr theSubscription] groups];
	int		i, count;
	BOOL	added = NO;
	
	count = [groups count];
	for (i=0;i<count;i++) {
		[[ISOOfflineMgr sharedOfflineMgr] addGroupToGroupDownloads:[groups objectAtIndex:i]];
		added = YES;
	}
	if (added) {
		[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindow];
		[[ISOOfflineMgr sharedOfflineMgr] sendReceiveAndGoOffline:self];
	}
}

- (void)splitListAndContent
{
	[self toggleSplittingWindow];
}

- (void)cancelMessage
{
	if (activePosting) {
		if ([messageCanceler canCancelPosting:activePosting]) {
			[messageCanceler runSheetForWindow:[self window] withPosting:activePosting inGroup:activeGroup];
		} else {
			[ISOBeep beep:@"You can cancel only postings you have sent by yourself!"];
		}
	}
}

- (void)addSelectionToBinaryExtractor:(id)sender
{
	if (![self addSelectionToBinaryExtractor]) {
		[ISOBeep beep:@"There was no selection to add to the downloads"];
	}
}

- (BOOL)addSelectionToBinaryExtractor
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSArray			*allObjects;  // because we have to start from the end
	int 			i, count;
	ISONewsPosting	*aPosting;
	BOOL			added = NO;
	NSMutableArray	*postingsToAdd = [NSMutableArray array];
	
	allObjects = [enumerator allObjects];
	count = [allObjects count];
	for (i=count-1; i>=0; i--) {
		aRowId = [allObjects objectAtIndex:i];
		aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[postingsToAdd addObject:aPosting];
		added = YES;
	}
	if (added) {
		[[ISOOfflineMgr sharedOfflineMgr] addArrayToPostingsToExtractBinariesFrom:postingsToAdd];
	}
	return added;
}

- (void)extractBinariesOfSelection
{
	if ([self addSelectionToBinaryExtractor]) {
		[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindowSwitchingTo:OFFLINE_BINARIES];
		[[ISOOfflineMgr sharedOfflineMgr] setDownloadIncoming:NO];
		[[ISOOfflineMgr sharedOfflineMgr] setUploadOutgoing:NO];
		[[ISOOfflineMgr sharedOfflineMgr] setExtractBinaries:YES];
	} else {
		[ISOBeep beep:@"There was no selection to add to the downloads"];
	}
	
}

- (void)gtv:(id)sender imageSizeChangedTo:(int)aSize
{
	[[theSubscriptionMgr theSubscription] setGTVIconSize:aSize];
	[theSubscriptionMgr subscriptionDataChanged];
}

- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification
{
	NSRect	aFrame = [postingsTableScrollView frame];
	[[theSubscriptionMgr theSubscription] setSplitViewVertPosition:aFrame.size.height];
	[theSubscriptionMgr subscriptionDataChanged];
}

- (void)window:(id)sender controlSpacePressed:(NSEvent *)theEvent
{	
	[ISOActiveLogger logWithDebuglevel:1 :@"controlSpacePressed pressed"];
}

- (void)window:(id)sender commandBackspacePressed:(NSEvent *)theEvent
{
	[ISOActiveLogger logWithDebuglevel:1 :@"Command-Backspace pressed"];
}

- (NSString *)selectedBodyPart
{
	return [postingDisplayMgr selectedBodyPart];
}

- (void)resetLastPostingNumber
{
	[postingNumberResetter runSheetForWindow:[self window] withGroup:activeGroup andSubscriptionMgr:theSubscriptionMgr];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	if (!expandingAllThreads) {
		ISONewsPosting	*expandedItem = [[notification userInfo] objectForKey:@"NSObject"];
		if (expandedItem) {
			int	count = [expandedItem subPostingCount];
			count = MIN (count, 3);
			if (count > 0) {
				int	rowIndex = [postingsTable rowForItem:[expandedItem postingAtIndex:count-1]];
				[postingsTable scrollRowToVisible:rowIndex];	// First show the (at most) 3rd sub-posting
				rowIndex = [postingsTable rowForItem:expandedItem];
				[postingsTable scrollRowToVisible:rowIndex];	// IN case the parent scrolled out, scroll it back ;-)
			}
	
		}
	}
}

- (BOOL)isShowingGTV
{
	return [graphicalThreadViewMgr isShowingGTV];
}

- (BOOL)isSplitListAndContent
{
	return ([tabView superview] == [[[theSubscriptionMgr splitPostingWindowMgr] window] contentView]);
}

- (BOOL)isShowingTabviewTabs
{
	return ([tabView tabViewType] != NSNoTabsNoBorder);
}

- (void)groupPostingsChangedRemotely:(NSNotification *)aNotification
{
	NSLog(@"Notification arrived");
	if (activeGroup && ([((NSString *)[aNotification object]) compare:[activeGroup groupName]] == NSOrderedSame)) {
		[self newsgroupSelected:groupsTable];
	}
	[groupsTable reloadData];
	[groupsTable display];
	NSLog(@"End of Notification");
}

- (void)loadPosting
{
	[self _postingSelected:self forceLoad:YES];
}

- (void)setNeedsDisplayRefresh:(BOOL)flag
{
	if ((activePosting != nil) && flag) {
		needsDisplayRefresh = flag;
	} else if (flag) {
		needsDisplayRefresh = NO;
		[self _updatePostingDisplay];
	}
}

- (void)loadSinglePosting
{
	[singlePostingLoader runSheetForWindow:[self window] withGroup:activeGroup andSubscriptionMgr:theSubscriptionMgr windowMgr:self];
}

- (void)selectPosting:(ISONewsPosting *)aPosting
{
	if (aPosting) {
		ISONewsPosting	*highestParent = [aPosting highestParent];
		/* As the whole threading might have changed, we need to re-sort and reload the posting list */
		if (activePosting) {
			[activePosting setIsSelected:NO];
		}
		[self newsgroupSelected:groupsTable];
		[aPosting setIsSelected:YES];

		[postingsTable expandItem:highestParent expandChildren:YES];
		[postingsTable reloadItem:highestParent reloadChildren:YES];
		[((NSOutlineView *)postingsTable) selectItem:aPosting];
	} else {
		NSBeep();
	}
}

- (BOOL)isAnyPostingLocked
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	NSArray			*allObjects;  // because we have to start from the end
	int 			i, count;
	ISONewsPosting	*aPosting;
	BOOL			isAnyPostingLocked = NO;
	BOOL			isUnthreadedDisplay = [[theSubscriptionMgr theSubscription] isUnthreadedDisplay];
	
	allObjects = [enumerator allObjects];
	count = [allObjects count];
	i=0;
	while (i<count && !isAnyPostingLocked) {
		aRowId = [allObjects objectAtIndex:i];
		aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		if (isUnthreadedDisplay) {
			isAnyPostingLocked = [aPosting isLocked];
		} else {
			isAnyPostingLocked = [aPosting isDeepLocked];
		}
		i++;
	}
	return isAnyPostingLocked;
}

- (void)lockUnlockPostings
{
	NSEnumerator	*enumerator = [postingsTable selectedRowEnumerator];
	NSNumber		*aRowId;
	BOOL			lockIt = NO;
	
	if ([self isAnyPostingLocked]) {
		lockIt = NO;
	} else {
		lockIt = YES;
	}
	while ((aRowId = [enumerator nextObject])) {
		ISONewsPosting *aPosting = [postingsTable itemAtRow:[aRowId intValue]];
		[aPosting setIsLocked:lockIt];
	}
	[self _updatePostingDisplayPreservingSelection:NO];
}

- (void)markThreadRead:(id)sender
{
	[self markThreadRead];
}

- (void)markThreadUnread:(id)sender
{
	[self markThreadUnread];
}

- (void)markGroupRead:(id)sender
{
	[self markGroupRead];
}


- (void)markGroupUnread:(id)sender
{
	[self markGroupUnread];
}


@end
