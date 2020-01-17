
#import <Cocoa/Cocoa.h>
#import "ISOController.h"
#import "ISOSubscriptionMgr.h"
#import "ISOPreferences.h"
#import "ISONewsServer.h"
#import "ISONewsServerMgr.h"
#import "ISOResourceMgr.h"
#import "ISOJobMgr.h"
#import "ISOOfflineMgr.h"
#import "ISOOutPostingMgr.h"
#import "ISOGraphicalTVMgr.h"
#import "ISOViewOptionsMgr.h"
#import "ISOLogger.h"
#import "version.h"
#import <NSExceptionHandler.h>
#import <uudeview.h>

#define K_INITIALDEBUGLEVEL	0

id gMainController;

@implementation ISOController
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	int choice = NSAlertDefaultReturn;

	isOffline = NO;
	gMainController = self;
	mainRunLoop = [NSRunLoop currentRunLoop];
	[[ISOLogger sharedLogger] setDebuglevel:K_INITIALDEBUGLEVEL];
	[ISOActiveLogger logWithDebuglevel:0 :@"************************ NEW HALIME INSTANCE STARTED ************************"];
	NSLog(@"<- PID");
	[ISOResourceMgr createResourceFilesIfNeeded];
	if (![self loadServers:self]) {
	    choice = NSRunAlertPanel(NSLocalizedString(@"Loading Servers", @"Title of alert panel which comes up when we couldnt load the Server data."), 
			NSLocalizedString(@"Could not load the server data. The reason might be that you haven't yet setup a server list, including maybe other preferences, too.", @"Message in the alert panel which shows the error."), 
			NSLocalizedString(@"Preferences...", @"Choice (on a button) given to user which allows him/her to go to the Preferences panel."), 
			nil,
			NSLocalizedString(@"Ignore", @"Choice (on a button) given to user which allows him/her to ignore this message."));
			if (choice == NSAlertDefaultReturn) {
				[[ISOPreferences sharedInstance] showPanel:self];
			}
	}
	[[NSDocumentController sharedDocumentController] setShouldCreateUI:YES];
	if ([[ISOPreferences sharedInstance] prefsAutoloadSubscription]) {
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:[[ISOPreferences sharedInstance] prefsAutoloadSubscriptionFilename] display:YES];
	}
	[[ISOJobMgr sharedJobMgr] detachAsSeparateThread];
	[[ISOPreferences sharedInstance] setController:self];
	[self goOffline:[[ISOPreferences sharedInstance] isOffline]];
	[[ISOOutPostingMgr sharedOutPostingMgr] ping];
	if ([[ISOPreferences sharedInstance] prefsCheckForUpdates] && !isOffline) {
		[NSThread detachNewThreadSelector:@selector(checkUpdate) toTarget:self withObject:nil];
	}
	[removeSelectionMenu setKeyEquivalent:@"\x08"];
	[removeSelectionMenu setKeyEquivalentModifierMask:NSCommandKeyMask];

	[removeReadArticlesMenu setKeyEquivalent:@"\x08"];
	[removeReadArticlesMenu setKeyEquivalentModifierMask:NSCommandKeyMask | NSAlternateKeyMask];
	[[nonThreadedDisplayMenu menu] setAutoenablesItems:YES];
	[[newPostingMenu menu] setAutoenablesItems:YES];
	[[markGroupReadMenu menu] setAutoenablesItems:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    return NSTerminateNow;
}


- (void)applicationWillTerminate:(NSNotification *)notification
{
    [ISOPreferences saveDefaults];
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
	[[ISOLogger sharedLogger] logWithDebuglevel:25 :@"application:openFile:[%@]", filename];
	return ([[NSDocumentController sharedDocumentController] openDocumentWithContentsOfFile:filename display:YES] != nil);
	return YES;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
	[[ISOLogger sharedLogger] logWithDebuglevel:25 :@"applicationOpenUntitledFile"];
	return YES;
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	return NO;
}

- (NSRunLoop *)mainRunLoop
{
	return mainRunLoop;
}

- (id)_currentDocument
{
    return [[NSDocumentController sharedDocumentController] currentDocument];
}

- (void)_makeAWindowActive
{
	if ([[NSApplication sharedApplication] mainWindow] == nil) {
		if ([[NSDocumentController sharedDocumentController] documents]) {
			if ([[[NSDocumentController sharedDocumentController] documents] count]) {
				[[[[NSDocumentController sharedDocumentController] documents] objectAtIndex:0] showWindows];
			}
		}
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	[self performSelector:@selector(_makeAWindowActive) withObject:nil afterDelay:0.5];
}

- (BOOL)loadServers:(id)sender
{
	return [[ISOPreferences sharedInstance] serverCount] >0;
}

- (void)checkUpdate
{
	NSAutoreleasePool	*aPool;
	NSURL				*url;
	NSString			*string;
	
	aPool = [[NSAutoreleasePool alloc] init];
	if ([[ISOPreferences sharedInstance] prefsCheckForUpdates] && !isOffline) {
		url = [NSURL URLWithString:@"http://halime.imdat.de/lastversion.txt"];
		string = [NSString stringWithContentsOfURL:url];
		if (string) {
			if ([string intValue] > K_CURRENTVERSION) {
				NSRunAlertPanel(NSLocalizedString(@"New Version Released", @""), 
						NSLocalizedString(@"It seems there is a new version of Halime, just released and available on the Halime webserver: http://halime.imdat.de/. You might want to check it out (you can switch off this check in the Preferences).", @""),
						NSLocalizedString(@"Okay, I'll check", @""),
						nil,
						nil);
			}
		}
	}
	[aPool release];
}

- (BOOL)updateServers:(id)sender
{
	return YES;
}

- (ISONewsServerMgr *)serverMgrForServerNamed:(NSString *)serverName withPort:(int)port
{
	return nil;
}


- (void)newPosting:sender
{
    [[self _currentDocument] newPosting];
}

- (void)followUp:sender
{
    [[self _currentDocument] followUp];
}

- (void)replyAuthor:sender
{
    [[self _currentDocument] replyAuthor];
}

- (void)forward:sender
{
    [[self _currentDocument] forward];
}

- (void)markPostingRead:sender
{
    [[self _currentDocument] markPostingRead];
}

- (void)markPostingUnread:sender
{
    [[self _currentDocument] markPostingUnread];
}

- (void)markThreadRead:sender
{
    [[self _currentDocument] markThreadRead];
}

- (void)markThreadUnread:sender
{
    [[self _currentDocument] markThreadUnread];
}

- (void)addSenderToFriends:sender
{
    [[self _currentDocument] addSenderToFriends];
}

- (void)addSubjectToFavorites:sender
{
    [[self _currentDocument] addSubjectToFavorites];
}

/* SUBSCRIPTION SPECIFIC MENUS */
- (void)markGroupRead:sender
{
    [[self _currentDocument] markGroupRead];
}

- (void)markGroupUnread:sender
{
    [[self _currentDocument] markGroupUnread];
}

- (void)markSubscriptionRead:sender
{
    [[self _currentDocument] markSubscriptionRead];
}

- (void)markSubscriptionUnread:sender
{
    [[self _currentDocument] markSubscriptionUnread];
}

- (void)checkForNewPostings:sender
{
    [[self _currentDocument] checkForNewPostings];
}

- (void)goOnOrOffline:sender
{
	isOffline = !isOffline;
	[[ISOPreferences sharedInstance] setIsOffline:isOffline];
}

- (void)goOffline:(BOOL)flag
{
	isOffline = flag;
	[[ISOJobMgr sharedJobMgr] setIsOffline:isOffline];
	if (isOffline) {
		[goOnOrOfflineMenu setTitle:NSLocalizedString(@"Go Online", @"")];
	} else {
		[goOnOrOfflineMenu setTitle:NSLocalizedString(@"Go Offline", @"")];
	}
}

- (void)filterForFavoriteSubjects:sender
{
    [[self _currentDocument] filterForFavoriteSubjects];
}

- (void)manageFavoriteSubjects:sender
{
	[[self _currentDocument] manageFavoriteSubjects];
}

- (void)filterForFriends:sender
{
    [[self _currentDocument] filterForFriends];
}

- (void)manageFriendsList:sender
{
	[[self _currentDocument] manageFriendsList];
}

- (void)saveSelectedMessages:sender
{
    [[self _currentDocument] saveSelectedMessages];
}

- (void)extractBinariesOfSelection:sender
{
    [[self _currentDocument] extractBinariesOfSelection];
}

- (void)removeAllInvalidArticles:sender
{
    [[self _currentDocument] removeAllInvalidArticles];
}

- (void)removeReadArticles:sender
{
    [[self _currentDocument] removeReadArticles];
}

- (void)catchUp:sender
{
    [[self _currentDocument] catchUp];
}

- (void)catchUpSubscription:sender
{
    [[self _currentDocument] catchUpSubscription];
}

- (void)showHideGroupsDrawer:sender
{
    [[self _currentDocument] showHideGroupsDrawer];
}

- (void)showSPAMFilterList:sender
{
    [[self _currentDocument] showSPAMFilterList];
}

- (void)addGroups:sender
{
    [[self _currentDocument] addGroups];
}

- (void)reApplySPAMFilters:sender
{
}

- (void)showSearchPanel:sender
{
    [[self _currentDocument] showSearchPanel];
}

- (void)searchNext:sender
{
    [[self _currentDocument] searchNext];
}

- (void)searchPrevious:sender
{
    [[self _currentDocument] searchPrevious];
}

- (void)showHideJobsPanel:sender
{
	[[ISOJobViewMgr sharedJobViewMgr] toggleDisplay];
}

- (void)expandThread:sender
{
    [[self _currentDocument] expandThread];
}

- (void)collapseThread:sender
{
    [[self _currentDocument] collapseThread];
}

- (void)expandAllThreads:sender
{
    [[self _currentDocument] expandAllThreads];
}

- (void)collapsAllThreads:sender
{
    [[self _currentDocument] collapsAllThreads];
}

- (void)expandThreadsSmart:sender
{
    [[self _currentDocument] expandThreadsSmart];
}

- (void)killThread:sender
{
    [[self _currentDocument] killThread];
}

- (void)killParentThread:sender
{
    [[self _currentDocument] killParentThread];
}

- (void)removeFlagged:sender
{
    [[self _currentDocument] removeFlagged];
}

- (void)downloadFlagged:sender
{
    [[self _currentDocument] downloadFlagged];
}

- (void)downloadFlaggedAndGoOffline:sender
{
    [[self _currentDocument] downloadFlaggedAndGoOffline];
}

- (void)flagSelection:sender
{
    [[self _currentDocument] flagSelection];
}

- (void)unflagSelection:sender
{
    [[self _currentDocument] unflagSelection];
}

- (void)removeSelection:sender
{
    [[self _currentDocument] removeSelection];
}

- (void)addSelectionToDownloads:sender
{
    [[self _currentDocument] addSelectionToDownloads];
}

- (void)showOfflineMgr:sender
{
	[[ISOOfflineMgr sharedOfflineMgr] showSendReceiveWindow];
}

- (void)toggleThreadedDisplay:sender
{
    [[self _currentDocument] toggleThreadedDisplay];
}

- (void)toggleThreadFocus:sender
{
    [[self _currentDocument] toggleThreadFocus];
}

- (void)toggleHideRead:sender
{
    [[self _currentDocument] toggleHideRead];
}

- (void)toggleGraphicalTV:sender
{
    [[self _currentDocument] toggleGraphicalTV];
}

- (void)toggleTabTitles:sender
{
    [[self _currentDocument] toggleTabviewTabs:sender];
}

- (void)checkForNewPostingsInSubscription:sender
{
    [[self _currentDocument] checkForNewPostingsInSubscription:sender];
}

- (void)offlineInGroup:sender
{
    [[self _currentDocument] offlineInGroup:sender];
}

- (void)offlineInSubscription:sender
{
    [[self _currentDocument] offlineInSubscription:sender];
}

- (void)showViewOptions:sender
{
	[[ISOViewOptionsMgr sharedViewOptionsMgr] showWindow];
}

- (void)loadPosting:sender
{
    [[self _currentDocument] loadPosting:sender];
}

- (BOOL)isOffline
{
	return isOffline;
}

/* MENU VALIDATION */
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if (item == newPostingMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == toggleTabTitlesMenu) {
		if ([[self _currentDocument] isShowingTabviewTabs]) {
			[toggleTabTitlesMenu setTitle:NSLocalizedString(@"Hide Tab Titles", @"")];
		} else {
			[toggleTabTitlesMenu setTitle:NSLocalizedString(@"Show Tab Titles", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == hideReadMenu) {
		if ([[self _currentDocument] isHidingRead]) {
			[hideReadMenu setTitle:NSLocalizedString(@"Unhide Read Postings", @"")];
		} else {
			[hideReadMenu setTitle:NSLocalizedString(@"Hide Read Postings", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == setViewOptionsMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == followUpMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] == 1);
	} else if (item == replyAuthorMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] == 1);
	} else if (item == forwardMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] == 1);
	} else if (item == markPostingReadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == markPostingUnreadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == markThreadReadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == markThreadUnreadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == addSenderToFriendsMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == addSubjectToFavoritesMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == markGroupReadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == markGroupUnreadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == markSubscriptionUnreadMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == markSubscriptionReadMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == checkForNewPostingsMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == goOnOrOfflineMenu) {
		return YES;
	} else if (item == filterForFavoritesMenu) {
		if ([[self _currentDocument] isFilteredForSubjects]) {
			[filterForFavoritesMenu setTitle:NSLocalizedString(@"Remove Filtering for Favorites", @"")];
		} else {
			[filterForFavoritesMenu setTitle:NSLocalizedString(@"Filter for Favorites", @"")];
		}
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == manageFavoritesMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == filterForFriendsMenu) {
		if ([[self _currentDocument] isFilteredForSenders]) {
			[filterForFriendsMenu setTitle:NSLocalizedString(@"Remove Filtering for Friends", @"")];
		} else {
			[filterForFriendsMenu setTitle:NSLocalizedString(@"Filter for Friends", @"")];
		}
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == manageFriendsListMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == saveSelectedMessagesMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == focusOnThreadMenu) {
		if ([[self _currentDocument] isFocusingOnThread]) {
			[focusOnThreadMenu setTitle:NSLocalizedString(@"Unfocus Thread", @"")];
			return ([self _currentDocument] != nil);
		} else {
			[focusOnThreadMenu setTitle:NSLocalizedString(@"Focus on Thread", @"")];
			return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
		}
	} else if (item == nonThreadedDisplayMenu) {
		if ([[self _currentDocument] isUnthreadedDisplay]) {
			[nonThreadedDisplayMenu setTitle:NSLocalizedString(@"Show Threaded", @"")];
		} else {
			[nonThreadedDisplayMenu setTitle:NSLocalizedString(@"Show Unthreaded/Flat", @"")];
		}
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == extractBinariesOfSelectionMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == removeInvalidArticlesMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == removeReadArticlesMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == catchUpMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == catchUpSubscriptionMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == showHideGroupsDrawerMenu) {
		if ([[self _currentDocument] isShowingDrawer]) {
			[showHideGroupsDrawerMenu setTitle:NSLocalizedString(@"Hide Groups Drawer", @"")];
		} else {
			[showHideGroupsDrawerMenu setTitle:NSLocalizedString(@"Show Groups Drawer", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == showSPAMFilterMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == addGroupsMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == toggleToolbarMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == customizeToolbarMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == reApplySPAMFiltersMenu) {
		return NO;
	} else if (item == findMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == findNextMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == findPreviousMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == expandMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == collapseMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == expandThreadsMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == collapseThreadsMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == expandThreadsSmartMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == killThreadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasPostingSelected]);
	} else if (item == killParentThreadMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasPostingSelected]);
	} else if (item == removeFlaggedMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == downloadFlaggedMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == downloadFlaggedAndGoOfflineMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == flagSelectionMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == unflagSelectionMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == removeSelectionMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == addSelectionToDownloadsMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == checkFNPSubscriptionMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == offlineReadingGroupMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == offlineReadingSubscriptionMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == expireInGroupMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == expireInSubscriptionMenu) {
		return ([self _currentDocument] != nil);
	} else if (item == toggleFullHeadersMenu) {
		if ([[self _currentDocument] isShowingFullHeaders]) {
			[toggleFullHeadersMenu setTitle:NSLocalizedString(@"Show Filtered Headers", @"")];
		} else {
			[toggleFullHeadersMenu setTitle:NSLocalizedString(@"Show Full Headers", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == splitListAndContentMenu) {
		if ([[self _currentDocument] isSplitListAndContent]) {
			[splitListAndContentMenu setTitle:NSLocalizedString(@"Join List and Content", @"")];
		} else {
			[splitListAndContentMenu setTitle:NSLocalizedString(@"Split List and Content", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == cancelMessageMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] == 1);
	} else if (item == graphicalTVMenu) {
		if ([[self _currentDocument] isShowingGTV]) {
			[graphicalTVMenu setTitle:NSLocalizedString(@"Hide Graphical Thread View", @"")];
		} else {
			[graphicalTVMenu setTitle:NSLocalizedString(@"Show Graphical Thread View", @"")];
		}
		return ([self _currentDocument] != nil);
	} else if (item == resetLastMessageNumberMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == loadPostingMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else if (item == loadSinglePostingMenu) {
		return ([self _currentDocument] != nil) && ([[self _currentDocument] hasGroupSelected]);
	} else if (item == lockPostingsMenu) {
		if ([[self _currentDocument] isAnyPostingLocked]) {
			[lockPostingsMenu setTitle:NSLocalizedString(@"Unlock Selected Postings", @"")];
		} else {
			[lockPostingsMenu setTitle:NSLocalizedString(@"Lock Selected Postings", @"")];
		}
		return ([self _currentDocument] != nil) && ([[self _currentDocument] numberOfSelectedPostings] > 0);
	} else {
        return YES;
    }
}

- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)anItem
{
	return [self validateMenuItem:anItem];
}

- (void)changeDebuglevel:sender
{
	[ISOActiveLogger setDebuglevel:[debugLevelField intValue]];
}

- (void)expireLocallyInGroup:sender
{
    [[self _currentDocument] expireLocallyInGroup:sender];
}

- (void)expireLocallyInSubscription:sender
{
    [[self _currentDocument] expireLocallyInSubscription:sender];
}

- (void)toggleFullHeaders:sender
{
    [[self _currentDocument] toggleFullHeaders:sender];
}

- (void)splitListAndContent:sender
{
    [[self _currentDocument] splitListAndContent:sender];
}


- (void)cancelMessage:sender
{
    [[self _currentDocument] cancelMessage];
}

- (void)resetLastMessageNumber:sender
{
    [[self _currentDocument] resetLastMessageNumber];
}

- (void)loadSinglePosting:sender
{
    [[self _currentDocument] loadSinglePosting];
}

- (void)lockUnlockPostings:sender
{
    [[self _currentDocument] lockUnlockPostings];
}

@end


/*
@implementation Controller (ScriptingSupport)

// Scripting support.

- (NSArray *)orderedDocuments
{
    NSArray *orderedWindows = [NSApp valueForKey:@"orderedWindows"];
    unsigned i, c = [orderedWindows count];
    NSMutableArray *orderedDocs = [NSMutableArray array];
    id curDelegate;
    
    for (i=0; i<c; i++) {
        curDelegate = [[orderedWindows objectAtIndex:i] delegate];
        
        if ((curDelegate != nil) && [curDelegate isKindOfClass:[ISOSubscriptionMgr class]]) {
            [orderedDocs addObject:curDelegate];
        }
    }
    return orderedDocs;
}

- (BOOL)application:(NSApplication *)sender delegateHandlesKey:(NSString *)key
{
    return [key isEqualToString:@"orderedDocuments"];
}

- (void)insertInOrderedDocuments:(ISOSubscriptionMgr *)doc atIndex:(int)index
{
    [doc retain];	// Keep it around...
    [[doc firstTextView] setSelectedRange:NSMakeRange(0, 0)];
    [doc setDocumentName:nil];
    [doc setDocumentEdited:NO];
    [doc setPotentialSaveDirectory:[Document openSavePanelDirectory]];
    [[doc window] makeKeyAndOrderFront:nil];
}

@end
*/

