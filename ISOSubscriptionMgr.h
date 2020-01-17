//
//  ISOSubscriptionMgrs.h
//  Halime
//
//  Created by iso on Thu Apr 26 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISOSubscription.h"
#import "ISOSubscriptionServerMgr.h"
#import "ISOSubscriptionWindowMgr.h"
#import "ISOPostingWindowMgr.h"

#define UnknownStringEncoding @"UnknownStringEncoding"

@interface ISOSubscriptionMgr : NSDocument
{
	ISOSubscription		*theSubscription;

	id					subscriptionWindowMgr;
	id					splitPostingWindowMgr;
    NSMutableArray		*windowControllers;
	NSTimer				*updateTimer;
	int					followUpsArrivedOnLastCheck;
	NSMutableArray		*followUpsArrived;
	NSMutableArray		*groupsBeingLoaded;
	NSStringEncoding	selectedEncoding;
	NSPopUpButton		*groupsPopupButton;
	BOOL				saveInSeparateThread;
	BOOL				runningInSeparateThread;
}
- initFromFile:(NSString *)filename;
- (id)initWithContentsOfFile:(NSString *)fileName ofType:(NSString *)docType;
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType;
- (void)dealloc;
- (BOOL)isDocumentEdited;
- (ISOSubscription *)theSubscription;

- (void)makeWindowControllers;
- (void)unhideWindow;
- (void)showWindows;

- (void)subscriptionChanged:sender;
- subscriptionDataChanged;
- subscriptionDataSaved;
- (void)autocheckForNewPostings;

/* Menu Actions */
- (void)newPosting;
- (void)followUp;
- (void)replyAuthor;
- (void)forward;
- (void)markPostingRead;
- (void)markPostingUnread;
- (void)addSenderToFriends;
- (void)addSubjectToFavorites;
- (void)markThreadRead;
- (void)markThreadUnread;

/* SUBSCRIPTION SPECIFIC MENUS */
- (void)markGroupRead;
- (void)markGroupUnread;
- (void)markSubscriptionRead;
- (void)markSubscriptionUnread;
- (void)checkForNewPostings;
- (void)filterForFavoriteSubjects;
- (void)manageFavoriteSubjects;
- (void)filterForFriends;
- (void)manageFriendsList;
- (void)saveSelectedMessages;
- (void)extractBinariesOfSelection;
- (void)removeAllInvalidArticles;
- (void)removeReadArticles;
- (void)catchUp;
- (void)catchUpSubscription;
- (void)showHideGroupsDrawer;
- (void)showSPAMFilterList;
- (void)addGroups;
- (void)showSearchPanel;
- (void)searchNext;
- (void)searchPrevious;
- (void)subscriptionWindowWillClose;
- (void)expandThread;
- (void)collapseThread;
- (void)expandAllThreads;
- (void)collapsAllThreads;
- (void)expandThreadsSmart;
- (void)killThread;
- (void)killParentThread;
- (void)removeFlagged;
- (void)downloadFlagged;
- (void)downloadFlaggedAndGoOffline;
- (void)flagSelection;
- (void)unflagSelection;
- (void)setupToolbar;
- (ISONewsGroup *)selectedGroup;
- (BOOL)hasGroupSelected;
- (int)numberOfSelectedPostings;
- (BOOL)hasPostingSelected;
- (void)removeSelection;
- (void)addSelectionToDownloads;
- (BOOL)isUnthreadedDisplay;
- (BOOL)isFilteredForSubjects;
- (BOOL)isFilteredForSenders;
- (BOOL)isFocusingOnThread;
- (void)toggleThreadedDisplay;
- (void)toggleThreadFocus;
- (void)toggleHideRead;
- (void)toggleOffline;
- (BOOL)isShowingDrawer;
- (BOOL)isHidingRead;
- (void)toggleGraphicalTV;
- (void)encodingChanged:sender;
- (NSStringEncoding )selectedEncoding;
- (NSDictionary *)viewOptions;
- (int)viewOptionValueForKey:(NSString *)aKey;
- (void)setViewOption:(NSString *)viewOption value:(int)value;
- (void)groupChanged:sender;
- (void)reflectGroupSelection:(NSString *)groupName;
- (void)updateGroupsDisplay;
- (void)filterForToolbarSelection:sender;
- (void)toggleTabviewTabs:sender;
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo;
- (void)checkForNewPostingsInSubscription:sender;
- (void)offlineInGroup:sender;
- (void)offlineInSubscription:sender;
- (void)expireLocallyInGroup:sender;
- (void)expireLocallyInSubscription:sender;
- (void)toggleFullHeaders:sender;
- (void)splitListAndContent:sender;
- (void)cancelMessage;
- (id)splitPostingWindowMgr;
- (id)subscriptionWindowMgr;
- (void)resetLastMessageNumber;
- (BOOL)isShowingGTV;
- (BOOL)isSplitListAndContent;
- (BOOL)isShowingFullHeaders;
- (BOOL)isShowingTabviewTabs;
- (void)setShouldShowAbbreviatedGroupNames:(BOOL)flag;
- (BOOL)shouldShowAbbreviatedGroupNames;
- (void)loadPosting:sender;
- (void)loadSinglePosting;
- (BOOL)isAnyPostingLocked;
- (void)lockUnlockPostings;
@end
