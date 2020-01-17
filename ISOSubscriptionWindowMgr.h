//
//  ISOSubscriptionWindowMgr.h
//  Halime
//
//  Created by iso on Fri Aug 17 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISOMasterSubscriptionWindowMgr.h"
#import "ISOProgressController.h"
#import "ISOPostingLoader.h"
#import "ISONewsGroup.h"

@interface ISOSubscriptionWindowMgr : ISOMasterSubscriptionWindowMgr
{
    id	postingsTable;
	id	postingsTableScrollView;
    
    
    id	groupsTable;
    id	serverNameField;
    
    id	groupsDrawer;
    
    id	tabView;
	BOOL	dontAskForConnectionAnymore;
    
	id	progressIndicator;
	id	progressMessageField;

	ISOPostingLoader *postingLoader;
	ISOPostingLoader *postingHeaderLoader;
	int	postingCount;
	int lineCount;
	ISONewsPosting	*activePosting;
	id	postingsCountField;
	
	id	serverMgr;
	id	filterMgr;
	int	panelReturnCode;
	id	activeGroup;
	int		lastSortCriteria;
	BOOL	sortReverse;
	
	id	searchPanel;
	id	searchField;
	id	searchPopup;
	id	searchIgnoreCaseSwitch;
	id	searchStartFromTopSwitch;
	id	searchSearchStartPosting;
	int followUpsArrivedOnLastCheck;
	id	followUpsArrived;
	
	id textScrollView;
	
	id friendsFavController;
	id splitView;
	
	id	markMenu;
	id	encodingMenu;
	id	groupsMenu;
	id	filterGroup;
	id	filterGroupMenu;
	id	filterGroupField;
	BOOL	initializingTable;
	id	drawerMgr;
	id	graphicalThreadViewMgr;
	
	id	expirePanel;
	id	expireField;
	id	expireTitleField;
	BOOL	removeExpiredArticlesInGroup;

	id	expireStatusIndicator;
	id	expireStatusField;
	id	expireStatusWindow;

	id	messageCanceler;
	id	postingNumberResetter;
	BOOL	expandingAllThreads;
	
	id	postingDisplayMgr;
	NSTimer	*timer;
	NSLock	*timerMutex;
	NSLock	*displayLock;
	
	BOOL needsDisplayRefresh;
	id	singlePostingLoader;
}

- initWithWindowNibName:(NSString *)nibName;
- (void)dealloc;
- setSubscriptionMgr:(id)aSubscriptionMgr;
- setupTableColumnHeaders;
- (void)unhideWindow;
- (void)awakeFromNib;
- (void)showWindow:sender;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)groupsTableValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (BOOL)loadPostings:sender;
- (void)postingLoadFinished:sender;
- (void)_postingSelected:(id)sender forceLoad:(BOOL)forceLoad;
- (void)postingSelected;
- (BOOL)loadBodyOfPosting:(ISONewsPosting *)aPosting;
- (void)newsgroupSelected:sender;
- (void)subscriptionChanged:sender;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader willBeginGroup:(ISONewsGroup *)aGroup;
- (BOOL)postingLoader:(ISOPostingLoader *)aPostingLoader didLoadPostingHeader:(ISONewsPosting *)aPosting;
- (void)reSortArticles;
- (void)finishedLoadingHeaders:(id)aPostingHeaderLoader;
- (int)postingLoader:(ISOPostingLoader *)aPostingLoader readsPosting:(ISONewsPosting *)aPosting atLine:(int)aLine;
- (ISONewsPosting *)activePosting;
- (void)_reflectDisplayChanges;
- (void)markSelectedPostingRead;
- (void)markSelectedPostingUnread;
- (void)markThreadRead;
- (void)markThreadUnread;
- (void)_markSubscriptionRead:(BOOL)flag;
- (void)markSubscriptionRead;
- (void)markSubscriptionUnread;
- (void)markGroupRead;
- (void)markGroupUnread;
- (void)_removePostingsInvalid:(BOOL)invFlag read:(BOOL)readFlag all:(BOOL)allFlag;
- (void)removeAllInvalidArticles;
- (void)removeReadArticles;
- (void)catchUp;
- (void)catchUpSubscription;
- (void)checkForNewPostings;
- (void)_updatePostingDisplayPreservingSelection:(BOOL)flag;
- (void)_updatePostingDisplay;
- (void)showHideGroupsDrawer;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)addGroupsButtonClicked:sender;
- (void)showSPAMFilterList;
- (void)addGroups;
- (BOOL)isAnyPostingSelected;
- (int)numberOfSelectedPostings;
- (ISONewsGroup *)selectedGroup;
- (void)outlineView:(NSOutlineView *)outlineView didClickOutlineColumn:(NSTableColumn *)tableColumn;
- (void)tableView:(NSTableView*)tableView didClickTableColumn:(NSTableColumn *)tableColumn;
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item;
- (NSString *)_makeDisplayableDate:(NSString *)originalDate;
- (NSString *)_retrieveNameOnlyFrom:(NSString *)aSender;
- (id)valueForColumn:(NSTableColumn *)aTableColumn fromItem:(ISONewsPosting *)aPosting;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectTableColumn:(NSTableColumn *)tableColumn;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification;
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (void)outlineViewClicked:sender;
- (void)showSearchPanel;
- (void)expandAndShowItem:(ISONewsPosting *)aPosting withSelecting:(BOOL)selectFlag;
- (void)expandAndShowItems:(NSArray *)postingArray;
- (void)_searchWithStartItem:(ISONewsPosting *)startSearchItem reverse:(BOOL)flag;
- (void)searchNext;
- (void)searchPrevious;
- (void)searchOK:sender;
- (void)searchCancel:sender;
- (ISONewsGroup *)activeGroup;
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool;
- (void)expandThread;
- (void)collapseThread;
- (void)expandAllThreads;
- (void)collapsAllThreads;
- (void)expandThreadsSmart;
- (void)window:(id)window rightArrowPressed:(NSEvent *)theEvent;
- (void)window:(id)window leftArrowPressed:(NSEvent *)theEvent;
- (void)window:(id)window spaceBarPressed:(NSEvent *)theEvent;
- (void)window:(id)window plusKeyPressed:(NSEvent *)theEvent;
- (void)window:(id)window minusKeyPressed:(NSEvent *)theEvent;
- (void)flagSelection;
- (void)unflagSelection;
- (void)removeSelection;
- (void)addSelectionToDownloadsWithSubThreads:(BOOL )withSubThreads;
- (void)addSelectionToDownloads;
- (void)followUpPosting:sender;
- (void)replyAuthor:sender;
- (void)markRead:sender;
- (void)markUnread:sender;
- (void)flagSelection:sender;
- (void)unflagSelection:sender;
- (void)saveSelection:sender;
- (void)downloadSelection:sender;
- (void)downloadSelectionWithThreads:sender;
- (void)removeSelection:sender;
- (void)addSenderToFriendsList:sender;
- (void)addSubjectToFavorites:sender;
- (void)addSPAMFilterWithSubject:sender;
- (void)addSPAMFilterWithSender:sender;
- (void)manageFavorites;
- (void)manageFriends;
- (void)filterForFavoriteSubjects;
- (void)filterForFriends;
- (void)toggleThreadedDisplay;
- (void)toggleThreadFocus;
- (void)toggleHideRead;
- (void)gtvPostingSelected:sender;
- (void)toggleGraphicalTV;
- (BOOL)validateMenuItem:(NSMenuItem *)item;
- (BOOL)isShowingDrawer;
- (void)nextGroup;
- (void)previousGroup;
- (void)nextPosting;
- (void)previousPosting;
- (void)window:(id)sender otherKeyPressed:(NSString *)aKey;
- (void)preferencesListFontChanged:(NSNotification *)notification;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)encodingChanged;
- (void)connectTabViewToSplitview;
- (void)disconnectTabViewFromSplitview;
- (void)toggleSplittingWindow;
- (BOOL)windowShouldClose:(id)sender;
-(void)_addTableColumn:(NSString *)identifier minW:(float)minW maxW:(float)maxW curW:(float)curW editable:(BOOL)editable resizable:(BOOL)resizable ha:(NSTextAlignment)ha ca:(NSTextAlignment)ca;
- (void)_addRemoveTableColumn:(NSString *)colIdentifier add:(BOOL)add;
- (void)_createDefaultColumnDisplay:(NSMutableArray *)displayedColumns;
- (void)initializeTableColumns;
- (void)viewOption:(NSString *)viewOption changedTo:(int)value;
- (void)groupChangedTo:(NSString *)groupName;
- (id)markMenu;
- (id)encodingMenu;
- (id)groupsMenu;
- (id)filterGroup;
- (id)filterGroupMenu;
- (id)filterGroupField;
- (void)filterForToolbarSelection:sender;
- (void)outlineViewColumnDidMove:(NSNotification *)notification;
- (void)outlineViewColumnDidResize:(NSNotification *)notification;
- (void)toggleTabviewTabs;
- (void)_removExpiredArticles;
- (void)expireRemoveClicked:sender;
- (void)expireCancelClicked:sender;
- (void)removeExpiredArticlesInGroup;
- (void)removeExpiredArticlesInSubscription;
- (void)toggleFullHeadersView;
- (void)offlineInGroup;
- (void)offlineInSubscription;
- (void)splitListAndContent;
- (void)cancelMessage;
- (void)addSelectionToBinaryExtractor:(id)sender;
- (BOOL)addSelectionToBinaryExtractor;
- (void)extractBinariesOfSelection;
- (void)gtv:(id)sender imageSizeChangedTo:(int)aSize;
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification;
- (void)window:(id)sender controlSpacePressed:(NSEvent *)theEvent;
- (void)window:(id)sender commandBackspacePressed:(NSEvent *)theEvent;
- (NSString *)selectedBodyPart;
- (void)resetLastPostingNumber;
- (void)outlineViewItemDidExpand:(NSNotification *)notification;
- (BOOL)isShowingGTV;
- (BOOL)isSplitListAndContent;
- (BOOL)isShowingTabviewTabs;
- (void)groupPostingsChangedRemotely:(NSNotification *)aNotification;
- (void)loadPosting;
- (void)setNeedsDisplayRefresh:(BOOL)flag;
- (void)loadSinglePosting;
- (void)selectPosting:(ISONewsPosting *)aPosting;
- (BOOL)isAnyPostingLocked;
- (void)lockUnlockPostings;

- (void)markThreadRead:(id)sender;
- (void)markThreadUnread:(id)sender;
- (void)markGroupRead:(id)sender;
- (void)markGroupUnread:(id)sender;
@end
