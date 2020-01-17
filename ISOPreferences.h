#import <Cocoa/Cocoa.h>

/* Keys in the dictionary... */   
#define MAC_ISOUsername @"ISOUserName"
#define MAC_ISOUserEmail @"ISOUserEmail"
#define MAC_ISOOrganization @"ISOOrganization"
#define MAC_ISOQuotestring @"ISOQuotestring"
#define MAC_ISONNTPServerList @"ISONNTPServerList"
#define MAC_ISOSubscriptionsDirectory @"ISOSubscriptionsDirectory"
#define MAC_ISOAllowLogicalSubscriptions @"ISOAllowLogicalSubscriptions"
#define MAC_ISOAutoloadSubscription @"ISOAutoloadSubscription"
#define MAC_ISOAutoloadSubscriptionName @"ISOAutoloadSubscriptionName"
#define MAC_ISOAutocheckSubscriptions @"ISOAutocheckSubscriptions"
#define MAC_ISOAutocheckSubscriptionsIntervall @"ISOAutocheckSubscriptionsIntervall"

#define MAC_ISOBinariesDirectory @"ISOBinariesDirectory"
#define MAC_ISOExtractBinariesMakeFilenamesUnique @"ISOExtractBinariesMakeFilenamesUnique"
#define MAC_ISOExtractBinariesWithExtensions @"ISOExtractBinariesWithExtensions"
#define MAC_ISOExtractBinariesWithExtensionsText @"ISOExtractBinariesWithExtensionsText"
#define MAC_ISODontExtractMultipartBinaries @"ISODontExtractMultipartBinaries"
#define MAC_ISOCreateGroupSubdirs @"ISOCreateGroupSubdirs"
#define MAC_ISOCreateDateSubdirs @"ISOCreateDateSubdirs"

#define MAC_ISOSPAMFilterList @"ISOSPAMFilterList"

#define MAC_ISOOutlineColors @"ISOOutlineColors"
#define MAC_ISOUnreadArticleColor @"ISOUnreadArticleColor"
#define MAC_ISOReadArticleColor @"ISOReadArticleColor"
#define MAC_ISOReplysColor @"ISOReplysColor"
#define MAC_ISOListFont @"ISOListFont"
#define MAC_ISOArticleBodyFont @"ISOArticleBodyFont"
#define MAC_ISODefaultPostingEncoding @"ISODefaultPostingEncoding"
#define MAC_ISODefaultSendPostingEncoding @"ISODefaultSendPostingEncoding"
#define MAC_ISOWrapAfter @"ISOWrapAfter"
#define MAC_ISODefaultAttachmentEncoding @"ISODefaultAttachmentEncoding"
#define MAC_ISOSPAMProtectEmailAddress @"ISOSPAMProtectEmailAddress"
#define MAC_ISORememberSentPostings @"ISORememberSentPostings"
#define MAC_ISOForgetAfterDays @"ISOForgetAfterDays"
#define MAC_ISOSaveSentPostings @"ISOSaveSentPostings"
#define MAC_ISOSavePostingsDirectory @"ISOSavePostingsDirectory"

#define MAC_ISOLimitHeadersDownloaded @"ISOLimitHeadersDownloaded"
#define MAC_ISOLimitHeadersDownloadedCount @"ISOLimitHeadersDownloadedCount"
#define MAC_ISOGroupClickedAction @"ISOGroupClickedAction"
#define MAC_ISOPostingClickedAction @"ISOPostingClickedAction"

#define MAC_ISOAutocheckSubscriptionsAllGroups	@"ISOAutocheckSubscriptionsAllGroups"
#define MAC_ISOAlertOnFollowupArrival @"ISOAlertOnFollowupArrival"
#define MAC_ISOAlertOnFollowupArrivalWithSound @"ISOAlertOnFollowupArrivalWithSound"
#define MAC_ISOAlertOnFollowupArrivalSound @"ISOAlertOnFollowupArrivalSound"
#define MAC_ISODefaultThreadDisplay @"ISODefaultThreadDisplay"
#define MAC_ISOFollowUpBanner @"ISOFollowUpBanner"
#define MAC_ISOOpenThreadOnNavigation @"ISOOpenThreadOnNavigation"
#define MAC_ISOIsOffline @"ISOIsOffline"
#define MAC_ISOCheckForUpdates	@"ISOCheckForUpdates"
#define MAC_ISODisplayThreaded @"ISODisplayThreaded"

#define	MAC_ISOSaveOnSubscriptionClose	@"ISOSaveOnSubscriptionClose"
#define MAC_ISOSPAMAutoRemoveKillFilters @"ISOSPAMAutoRemoveKillFilters"
#define MAC_ISOSPAMARKFDays @"ISOSPAMARKFDays"
#define MAC_ISOUsenetFormats @"UsenetFormats"
#define MAC_ISOHeadersColor @"HeadersColor"

#define MAC_ISOMailServer @"ISOMailServer"
#define MAC_ISOEditorFont @"ISOEditorFont"
#define MAC_ISONewPostingArrivedAlert @"ISONewPostingArrivedAlert"
#define MAC_ISONewPostingArrivedAlertSound @"ISONewPostingArrivedAlertSound"
#define MAC_ISODownloadOKAlert @"ISODownloadOKAlert"
#define MAC_ISODownloadOKAlertSound @"ISODownloadOKAlertSound"
#define MAC_ISODownloadErrorAlert @"ISODownloadErrorAlert"
#define MAC_ISODownloadErrorAlertSound @"ISODownloadErrorAlertSound"
#define MAC_ISOSendingOKAlert @"ISOSendingOKAlert"
#define MAC_ISOSendingOKAlertSound @"ISOSendingOKAlertSound"
#define MAC_ISOSendingErrorAlert @"ISOSendingErrorAlert"
#define MAC_ISOSendingErrorAlertSound @"ISOSendingErrorAlertSound"
#define MAC_ISOStandardPostingLifetime @"ISOStandardPostingLifetime"
#define MAC_ISOSupportXFaceURL @"ISOSupportXFaceURL"
#define MAC_ISOAdditionalHeaders @"ISOAdditionalHeaders"
#define MAC_ISOReloadParentPosting @"ISOReloadParentPosting"
#define MAC_ISOCheckSpellingWhileTyping @"ISOCheckSpellingWhileTyping"
#define MAC_ISONoAutomaticUserAgentHeader @"ISONoAutomaticUserAgentHeader"
#define MAC_ISONoCatchUpWarnings @"ISONoCatchUpWarnings"
#define MAC_ISONoMarkSubscriptionWarnings @"ISONoMarkSubscriptionWarnings"

#define PREFS_GroupClickedCheck			0
#define PREFS_GroupClickedDontCheck		1
#define PREFS_GroupClickedAskMe			2

#define PREFS_PostingClickedLoad		0
#define PREFS_PostingClickedDontLoad	1
#define PREFS_PostingClickedAskMe		2

#define PREFS_ThreadExpandedDisplay		0
#define PREFS_ThreadCollapsedDisplay	1
#define PREFS_ThreadSmartDisplay		2

#define MAC_ISOUNKNOWNENCODING	@"-1"
#define MAC_ISOUNKNOWNENCODINGINT	-1

#import "ISONewsServermgr.h"

@interface ISOPreferences : NSResponder
{
	id prefsTabview;
	id window;
	id backupWindow;
	
	// Server Part
	id nntpServerlist;
	id nntpServernameField;
	id nntpServerportField;
	id nntpNeedsAuthSwitch;
	id nntpAuthLoginField;
	id nntpAuthPasswordField;
	id nntpSlowServerSwitch;
	id nntpFQDNfield;
	id deleteServerButton;
	id changeServerButton;
	id addServerButton;
	
	// General Part
	id userNameField;
	id userEmailField;
	id organizationField;
	id quoteStringField;
	
	// Subscriptions Part
	id autoloadSubscriptionSwitch;
	id autoloadSubscriptionField;
	id autoloadSubscriptionChooseButton;
	id autoCheckSubscriptionSwitch;
	id autoCheckSubscriptionIntervallField;
	id checkAllGroupsSwitch;

	// Binaries Part
	id batchExtractionDirectoryField;
	id batchExtractionMakeFilenamesUniqueRadio;
	
	id batchExtractExtractBinariesWithExtSwitch;
	id batchExtractExtractBinariesWithExtField;

	id batchExtractDontExctractMultipartSwitch;
	id beCreateGroupSubdirsSwitch;
	id beCreateDateSubdirsSwitch;

	// SPAM part
	id spamList;
	id spamHeaderMenu;
	id spamOperatorMenu;
	id spamContainsField;
	
	id spamDeleteFilterButton;
	id spamChangeFilterButton;
	id spamAddFilterButton;

	// New Preferences
	id	outlineColor1;
	id	outlineColor2;
	id	outlineColor3;
	id	outlineColor4;
	id	outlineColor5;
	id	outlineColor6;
	id	unreadArticleColor;
	id	readArticleColor;
	id	replysArticleColor;
	id	listFontField;
	
	id	articleBodyEncodingPopup;
	id	articleBodyEncFontField;
	
	id	defaultPostingEncondingPopup;
	id	defaultSendEncodingPopup;
	id	wrapAfterField;
	id	defaultAttachmentEncodingPopup;
	id	spamProtectEmailSwitch;
	id	rememberSentSwitch;
	id	forgetAfterField;
	id	saveSentSwitch;
	id	saveSentField;
	id	chooseSentDirButton;
	
	id	limitPostingsDownloadedSwitch;
	id	limitPostingsDownloadedField;
	id	groupClickedActionMatrix;
	id	postingClickedActionMatrix;
	
	id	alertOnFollowUpSwitch;
	id	alertWithSoundSwitch;
	id	alertSoundField;
	id	alertSoundChooseButton;
	
	id	defaultThreadDisplayMatrix;

	id	followUpBannerField;
	
	id	openThreadOnNavigationSwitch;
	id	checkForUpdatesSwitch;
	id	displayThreadedSwitch;
	id	dtsMsgField;
	
	id	controller;
	
	id	saveOnCloseSubsSwitch;
	
	id	spamAutoRemoveKillFiltersSwitch;
	id	spamAutoRemoveKFField;
	
	id	usenetFormatsSwitch;
	id	headersColorWell;
	
	id	mailServerField;
	id	editorFontField;
	
	id	newPostingArriveAlertSwitch;
	id	newPostingArriveSoundField;
	id	newPostingArriveButton;
	
	id	downloadOkSoundSwitch;
	id	downloadOkSoundField;
	id	downloadOkSoundButton;
	
	id	downloadErrorSoundSwitch;
	id	downloadErrorSoundField;
	id	downloadErrorSoundButton;
	
	id	sendingOkSoundSwitch;
	id	sendingOkSoundField;
	id	sendingOkSoundButton;
	
	id	sendingErrorSoundSwitch;
	id	sendingErrorSoundField;
	id	sendingErrorSoundButton;

	id	standardPostingLifetime;
	id	xFaceURLSupportSwitch;
	id	reloadParentPostingSwitch;
	
    NSMutableDictionary *curValues;
    NSMutableDictionary *displayedValues;
    
    NSMutableArray	*nntpServerArray;
    NSMutableArray	*spamFilterArray;
    NSMutableArray	*outlineColors;
	NSMutableArray	*additionalHeaders;
    NSMutableDictionary *articleBodyFonts;

    NSMutableArray	*newsServerMgrs;
	id	editingFontField;
	
	/* HEADERS */
	id	additionalHeadersPanel;
	id	headerTable;
	id	headerField;
	id	valueField;
	id	addHeaderButton;
	id	deleteHeaderButton;
	id	changeHeaderButton;
	
	id	generalPrefsView;
	id	serverPrefsView;
	id	subscriptionPrefsView;
	id	batchOfflinePrefsView;
	id	readingPrefsView;
	id	postingPrefsview;
	id	spamPrefsview;

	id	checkSpellingWhileTypingSwitch;
	id	noAutoUserAgentHeaderSwitch;
	id	noCatchUpWarningsSwitch;
	id	noMarkSubscriptionWarningsSwitch;
}

+ (id)objectForKey:(id)key;	/* Convenience for getting global preferences */
+ (void)saveDefaults;		/* Convenience for saving global preferences */

+ (ISOPreferences *)sharedInstance;
- (NSArray *)encodingDisplayOrder;
- (NSDictionary *)cfstringEncodings;
- (NSDictionary *)mimeTypeDictionary;

- (NSMutableDictionary *)preferences;	/* The current preferences; contains values for the documented keys */

- (void)showPanel:(id)sender;	/* Shows the panel */

- (void)updateUI;		/* Updates the displayed values in the UI */
- (void)miscChanged:(id)sender;		/* Action message for most of the misc items in the UI to get displayedValues */

- (void)_cleanNNTPFields;
- (void)addNNTPServer:(id)sender;
- (void)changeNNTPServer:(id)sender;
- (void)deleteNNTPServer:(id)sender;
- (void)serverSelected:(id)sender;

- (void)_cleanSPAMFields;
- (void)_chooseValueOrtientedSPAMFilter;
- (void)_chooseStringOrientedSPAMFilter;
- (void)spamWhatMenuSelected:(id)sender;
- (void)spamOperatorMenuSelected:(id)sender;
- (void)spamFilterSelected:(id)sender;
- (void)addSPAMFilter:(id)sender;
- (void)changeSPAMFilter:(id)sender;
- (void)deleteSPAMFilter:(id)sender;

- (void)chooseAutoloadSubscription:(id)sender;

+ (NSMutableDictionary *)preferencesFromDefaults;
+ (void)savePreferencesToDefaults:(NSDictionary *)dict;

/* XXXClicked Methods called by the UI */
- (void)articleBodyEncodingPopupClicked:sender;
- (void)needsAuthenticationClicked:(id)sender;

- (void)autoloadSubscriptionClicked:(id)sender;
- (void)autocheckOpenSubscriptionsClicked:(id)sender;

- (void)extractBinariesWithExtensionsClicked:(id)sender;
- (void)chooseBinaryExtractionDirectory:(id)sender;
- (void)displayThreadedSwitchClicked:(id)sender;

- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)headerValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)nntpServerValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (id)spamFilterValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (int)serverCount;
- (ISONewsServerMgr *)createNewsServerMgrForServer:(NSString *)newsServerName addToPool:(BOOL)addToPool;
- (ISONewsServerMgr *)newsServerMgrForServer:(NSString *)newsServerName;
- (ISONewsServerMgr *)newsServerMgrForServerAtIndex:(int)index;
- (NSDictionary *)nntpServerInfoAtIndex:(int)index;

- (void)rememberSwitchClicked:sender;
- (void)savePostingsSwitchClicked:sender;
- (void)limitPostingsSwitchClicked:sender;
- (void)chooseSaveDirectory:sender;
- (void)spamAutoRemoveKillFiltersSwitchClicked:sender;

- (void)alertMeOnFollowUpSwitchClicked:sender;
- (void)alertWithSoundSwitchClicked:sender;
- (void)chooseAlertSound:sender;
- (void)chooseListFont:sender;
- (void)chooseBodyFont:sender;
- (void)setCurrentFontForAllEncodings:sender;
- (void)setFontField:(id)fontField toFontNamed:(NSString *)fontName andSize:(float)size;
- (void)setFontField:(id)fontField toFont:(NSFont *)font;
- (IBAction)openFontPanel:(id)sender;
- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName;
- (void)changeFont:(id)sender;

/* Pref Requests */
- (NSString *)prefsUserName;
- (NSString *)prefsUserEmail;
- (NSString *)prefsQuoteString;
- (NSCharacterSet *)prefsQuoteCharacterSet;
- (NSArray *)prefsQuoteColors;
- (NSString *)prefsOrganization;
- (BOOL)prefsAutoloadSubscription;
- (NSString *)prefsAutoloadSubscriptionFilename;
- (NSDictionary *)prefsArticleBodyFonts;
- (NSFont *)prefsListviewFont;
- (NSFont *)articleBodyFontForEncoding:(NSStringEncoding )encoding;
- (BOOL)prefsAutoCheckSubscription;
- (int)prefsAutoCheckSubscriptionInterval;
- (NSColor *)prefsUnreadArticleColor;
- (NSColor *)prefsReadArticleColor;
- (NSColor *)prefsReplysColor;
- (BOOL)prefsRememberSentPostings;
- (BOOL)prefsSaveSentPostings;
- (NSString *)prefsSentPostingsSaveDirectory;
- (int)prefsWrapTextLength;
- (BOOL)prefsWrapText;

- (BOOL)prefsLimitHeadersDownloaded;
- (int)prefsNumberOfMaxHeadersToDownload;
- (int)prefsGroupClickedAction;
- (int)prefsPostingClickedAction;

- (BOOL)prefsCheckForAllGroups;
- (BOOL)prefsAlertOnFollowUp;
- (BOOL)prefsAlertOnFollowUpWithSound;
- (NSString *)prefsFollowUpAlertSound;
- (int)prefsDefaultThreadDisplay;
- (NSString *)prefsFollowUpBanner;
- (BOOL)prefsOpenThreadOnNavigation;
- (BOOL)prefsCheckForUpdates;
- (int)prefsDefaultPostingEncoding;
- (int)prefsDefaultSendPostingEncoding;
- (BOOL)prefsDisplayPostingsThreaded;
- (NSArray *)prefsGlobalSPAMFilters;
- (void)setController:(id)anObject;
- (id)controller;

- (void)chooseEditorFont:sender;

- (void)newPostingArrivedAlertSwitchClicked:sender;
- (void)chooseNewPostingAlertSound:sender;

- (void)downloadOKAlertSwitchClicked:sender;
- (void)chooseDownloadOKAlertSound:sender;

- (void)downloadErrorAlertSwitchClicked:sender;
- (void)chooseDownloadErrorAlertSound:sender;

- (void)sendingOKAlertSwitchClicked:sender;
- (void)chooseSendingOKAlertSound:sender;

- (void)sendingErrorAlertSwitchClicked:sender;
- (void)chooseSendingErrorAlertSound:sender;

- (BOOL)isOffline;
- (void)setIsOffline:(BOOL)flag;
- (BOOL)prefsSaveOnCloseSubscription;
- (BOOL)prefsSPAMAutoRemoveKillFilter;
- (int)prefsSPAMARKFDays;
- (BOOL)prefsUsenetFormats;
- (NSColor *)prefsHeadersColor;

- (NSString *)prefsMailServer;
- (NSFont *)prefsEditorFont;
- (BOOL)prefsShouldNewPostingArrivedAlert;
- (NSString *)prefsNewPostingArrivedAlertSoundName;

- (BOOL)prefsShouldDownloadOKAlert;
- (NSString *)prefsDownloadOKAlertSoundName;

- (BOOL)prefsShouldDownloadErrorAlert;
- (NSString *)prefsDownloadErrorAlertSoundName;

- (BOOL)prefsShouldSendingOKAlert;
- (NSString *)prefsSendingOKAlertSoundName;

- (BOOL)prefsShouldSendingErrorAlert;
- (NSString *)prefsSendingErrorAlertSoundName;

- (void)prefsAlertWithSoundKey:(NSString *)soundKey;
- (int)prefsStandardPostingLifetime;

- (BOOL)prefsSupportXFaceURL;
- (BOOL)doNotAutomaticallySendUserAgentHeader;
- (BOOL)noCatchUpWarnings;
- (BOOL)noMarkSubscriptionWarnings;

- (NSString *)prefsExtractionDirectory;
- (BOOL)prefsCreateGroupSubdirs;
- (BOOL)prefsCreateDateSubdirs;
- (BOOL)prefsExtractFileTypesOnly;
- (NSString *)prefsExtractionFileTypes;
- (BOOL)prefsDontExtractMultipart;
- (BOOL)prefsMakeFilenamesUnique;
- (NSArray *)prefsAdditionalHeaders;
- (BOOL)prefsReloadParentPosting;
- (BOOL)prefsCheckSpellingWhileTyping;

/* HEADERS */
- (void)headerEntryFieldsChanged:(NSNotification *)aNotification;
- (void)additionalHeaders:(id)sender;
- (void)headerTableClicked:(id)sender;
- (void)addHeader:(id)sender;
- (void)deleteHeader:(id)sender;
- (void)changeHeader:(id)sender;
- (void)finishedEditingHeaders:sender;

- (void)selectGeneralPrefs:sender;
- (void)selectServerPrefs:sender;
- (void)selectSubscriptionPrefs:sender;
- (void)selectBatchOfflinePrefs:sender;
- (void)selectReadingPrefs:sender;
- (void)selectPostingPrefs:sender;
- (void)selectSPAMPrefs:sender;

- (NSString *)genericPrefForKey:(NSString *)aKey;
- (void)setGenericPref:(NSString *)aValue forKey:(NSString *)aKey;

@end
