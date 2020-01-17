#import <Cocoa/Cocoa.h>
#import "ISONewsServerMgr.h"

extern id gMainController;

@interface ISOController : NSObject
{
	id	newPostingMenu;
	id	followUpMenu;
	id	replyAuthorMenu;
	id	forwardMenu;
	id	markPostingReadMenu;
	id	markPostingUnreadMenu;
	id	markThreadReadMenu;
	id	markThreadUnreadMenu;
	id	addSenderToFriendsMenu;
	id	addSubjectToFavoritesMenu;
	id	markGroupReadMenu;
	id	markGroupUnreadMenu;
	id	markSubscriptionUnreadMenu;
	id	markSubscriptionReadMenu;
	id	checkForNewPostingsMenu;
	id	checkFNPSubscriptionMenu;
	id	offlineReadingGroupMenu;
	id	offlineReadingSubscriptionMenu;
	id	goOnOrOfflineMenu;
	id	filterForFavoritesMenu;
	id	manageFavoritesMenu;
	id	filterForFriendsMenu;
	id	manageFriendsListMenu;
	id	saveSelectedMessagesMenu;
	id	extractBinariesOfSelectionMenu;
	id	removeInvalidArticlesMenu;
	id	removeReadArticlesMenu;
	id	catchUpMenu;
	id	catchUpSubscriptionMenu;
	id	showHideGroupsDrawerMenu;
	id	showSPAMFilterMenu;
	id	addGroupsMenu;
	id	toggleToolbarMenu;
	id	customizeToolbarMenu;
	id	setViewOptionsMenu;
	id	reApplySPAMFiltersMenu;
	id	findMenu;
	id	findNextMenu;
	id	findPreviousMenu;
	id	expandMenu;
	id	collapseMenu;
	id	expandThreadsMenu;
	id	collapseThreadsMenu;
	id	expandThreadsSmartMenu;
	
	id	killThreadMenu;
	id	killParentThreadMenu;
	id	showHideJobsMenu;
	id	removeFlaggedMenu;
	id	downloadFlaggedMenu;
	id	downloadFlaggedAndGoOfflineMenu;
	id	flagSelectionMenu;
	id	unflagSelectionMenu;
	
	id	focusOnThreadMenu;
	id	nonThreadedDisplayMenu;
	
	id	removeSelectionMenu;
	id	addSelectionToDownloadsMenu;
	id	graphicalTVMenu;
	
	BOOL	isOffline;

	id	hideReadMenu;
	id	toggleTabTitlesMenu;
	id	expireInGroupMenu;
	id	expireInSubscriptionMenu;
	id	toggleFullHeadersMenu;
	id	splitListAndContentMenu;
	id	cancelMessageMenu;
	id	resetLastMessageNumberMenu;
	id	loadPostingMenu;
	id	loadSinglePostingMenu;
	id	lockPostingsMenu;
	
	id	debugLevelField;
	
	id	mainRunLoop;
}

/* NSApplication delegate methods */
- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename;
- (BOOL)applicationOpenUntitledFile:(NSApplication *)app;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app;
- (void)applicationDidBecomeActive:(NSNotification *)aNotification;

- (NSRunLoop *)mainRunLoop;

/* Action methods */
- (BOOL)loadServers:(id)sender;
- (void)checkUpdate;
- (BOOL)updateServers:(id)sender;
- (ISONewsServerMgr *)serverMgrForServerNamed:(NSString *)serverName withPort:(int)port;

/* **** */
- (void)newPosting:sender;
- (void)followUp:sender;
- (void)replyAuthor:sender;
- (void)forward:sender;
- (void)markPostingRead:sender;
- (void)markPostingUnread:sender;
- (void)markThreadRead:sender;
- (void)markThreadUnread:sender;
- (void)addSenderToFriends:sender;
- (void)addSubjectToFavorites:sender;

/* SUBSCRIPTION SPECIFIC MENUS */

- (void)markGroupRead:sender;
- (void)markGroupUnread:sender;
- (void)markSubscriptionRead:sender;
- (void)markSubscriptionUnread:sender;
- (void)checkForNewPostings:sender;
- (void)goOnOrOffline:sender;
- (void)goOffline:(BOOL)flag;
- (void)filterForFavoriteSubjects:sender;
- (void)manageFavoriteSubjects:sender;
- (void)filterForFriends:sender;
- (void)manageFriendsList:sender;
- (void)saveSelectedMessages:sender;
- (void)extractBinariesOfSelection:sender;

- (void)removeAllInvalidArticles:sender;
- (void)removeReadArticles:sender;
- (void)catchUp:sender;
- (void)catchUpSubscription:sender;
- (void)showHideGroupsDrawer:sender;
- (void)showSPAMFilterList:sender;
- (void)addGroups:sender;
- (void)reApplySPAMFilters:sender;
- (void)showSearchPanel:sender;
- (void)searchNext:sender;
- (void)searchPrevious:sender;
- (void)showHideJobsPanel:sender;

- (void)expandThread:sender;
- (void)collapseThread:sender;
- (void)expandAllThreads:sender;
- (void)collapsAllThreads:sender;
- (void)expandThreadsSmart:sender;

- (void)killThread:sender;
- (void)killParentThread:sender;

- (void)removeFlagged:sender;
- (void)downloadFlagged:sender;
- (void)downloadFlaggedAndGoOffline:sender;
- (void)flagSelection:sender;
- (void)unflagSelection:sender;

- (void)removeSelection:sender;
- (void)addSelectionToDownloads:sender;

- (void)showOfflineMgr:sender;
- (void)toggleThreadedDisplay:sender;
- (void)toggleThreadFocus:sender;
- (void)toggleHideRead:sender;
- (void)toggleGraphicalTV:sender;
- (void)toggleTabTitles:sender;
- (void)checkForNewPostingsInSubscription:sender;
- (void)offlineInGroup:sender;
- (void)offlineInSubscription:sender;
- (void)showViewOptions:sender;
- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (BOOL)isOffline;
- (void)changeDebuglevel:sender;
- (void)expireLocallyInGroup:sender;
- (void)expireLocallyInSubscription:sender;
- (void)toggleFullHeaders:sender;
- (void)splitListAndContent:sender;
- (void)cancelMessage:sender;
- (void)resetLastMessageNumber:sender;
- (void)loadPosting:sender;
- (void)loadSinglePosting:sender;
- (void)lockUnlockPostings:sender;
@end
