//
//  ISOOfflineMgr.h
//  Halime
//
//  Created by Imdat Solak on Sat Jan 26 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ISONewsPosting.h"
#import "ISONewsGroup.h"

#define OFFLINE_GROUPS		0
#define OFFLINE_INCOMING	1
#define OFFLINE_OUTGOING	2
#define OFFLINE_BINARIES	3

@interface ISOOfflineMgr : NSObject
{
	id	window;
	id	downloadsTable;
	id	uploadsTable;
	id	removeDownloadsButton;
	id	holdonDownloadsButton;
	id	releaseDownloadsButton;
	id	numDownloadField;
	
	id	removeUploadsButton;
	id	holdonUploadsButton;
	id	releaseUploadsButton;
	id	numUploadField;
	
	id	srOnlineButton;
	id	srOfflineButton;
	
	id	groupsSwitch;
	id	incomingSwitch;
	id	outgoingSwitch;
	id	binariesSwitch;
	
	id	progressIndicator;
	id	totalProgressIndicator;
	id	progressMessageField;
	
	id	errorTable;
	id	errorWindow;
	id	errorTextView;
	
	id	tabView;
	id	groupsTable;
	id	holdGroupButton;
	id	releaseGroupButton;
	id	removeGroupButton;
	
	id	binariesTable;
	id	holdBinariesButton;
	id	releaseBinariesButton;
	id	removeBinariesButton;
	id	downloadFolderField;
	id	chooseDownloadFolderButton;
	id	createGroupSubdirsSwitch;
	id	createDateSubdirsSwitch;
	id	filenamePopup;
	id	extractFileTypesOnlySwitch;
	id	extractionFileTypesField;
	id	dontExtractMultipartSwitch;
	id	numBinariesField;
	
	NSMutableArray	*downloads;
	NSMutableArray	*uploads;
	NSArray			*spamFilter;
	
	NSMutableArray	*errorArray;
	NSMutableArray	*groupsToDownload;
	NSMutableArray	*postingsToExtractBinariesFrom;

	BOOL	isWorking;
	BOOL	pleaseFinishWorking;
	BOOL	sendingReceivingAll;
	
	id		actionMessageField;
}
+ sharedOfflineMgr;
- init;
- (void)dealloc;
- setSPAMFilter:(NSArray *)anArray;
- showSendReceiveWindowSwitchingTo:(int)tabViewItemToShow;
- showSendReceiveWindow;

- (void)addToPostingsToExtractBinariesFrom:(ISONewsPosting *)aPosting;
- (void)addArrayToPostingsToExtractBinariesFrom:(NSArray *)anArray;
- (void)removeFromPostingsToExtractBinariesFrom:(ISONewsPosting *)aPosting;

- addToDownloads:(ISONewsPosting *)aPosting;
- (void)addToDownloadsFromArray:(NSArray *)anArray;
- removeFromDownloads:(ISONewsPosting *)aPosting;
- addToUploads:(ISONewsPosting *)aPosting;
- removeFromUploads:(ISONewsPosting *)aPosting;
- addGroupToGroupDownloads:(ISONewsGroup *)aGroup;
- removeGroupFromGroupDownloads:(ISONewsGroup *)aGroup;

- (void)removeGroups:sender;
- (void)holdonGroups:sender;
- (void)releaseGroups:sender;

- (void)removeDownloads:sender;
- (void)holdonDownloads:sender;
- (void)releaseDownloads:sender;

- (void)removeUploads:sender;
- (void)holdonUploads:sender;
- (void)releaseUploads:sender;

- (void)removeBinaries:sender;
- (void)holdonBinaries:sender;
- (void)releaseBinaries:sender;

- (void)sendReceiveAndStayOnline:sender;
- (void)sendReceiveAndGoOffline:sender;

/* Threaded Functions */
- (void)srOnlineWithSelection:(id)userData;
- (void)srOfflineWithSelection:(id)userData;
/* Threaded Functions */

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
- (void)addToErrorLog:(NSString *)message forPosting:(ISONewsPosting *)aPosting;
- (void)cleanupErrors:sender;
- (void)showErrors:sender;
- (void)uploadsDoubleClicked:sender;

/* ********************** */
- (void)chooseDownloadDirectory:(id)sender;
- (void)extractFileTypesSwitchClicked:(id)sender;
- (void)setDownloadGroups:(BOOL)flag;
- (void)setDownloadIncoming:(BOOL)flag;
- (void)setUploadOutgoing:(BOOL)flag;
- (void)setExtractBinaries:(BOOL)flag;
@end
