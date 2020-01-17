/*
*/

#import <Cocoa/Cocoa.h>
#import "ISOPreferences.h"
#import "ISOSubscription.h"		// For "UnknownStringEncoding"
#import "ISOBeep.h"
#import "ISOSPAMFilterMgr.h"
#import "ISOController.h"
#import "ISOSignatureMgr.h"
#import "ISOIdentityMgr.h"
#import "ISOLogger.h"
#import "NSPopUpButton_Extensions.h"
#import "EncodingPopupMaker.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFStringEncodingExt.h>

@interface NSToolbar (NSToolbarPrivate)
- (NSView *) _toolbarView;
@end

static NSMutableDictionary *defaultValues() 
{
    static NSMutableDictionary *dict = nil;
	static NSMutableArray	*blackArray;
	static NSMutableArray	*darkGrayArray;
	static NSMutableArray	*redArray;
	static NSMutableArray 	*fontArray;
	static NSMutableArray	*fixedFontArray;

	darkGrayArray = [NSMutableArray arrayWithObjects:
									[NSNumber numberWithFloat:0.33],
									[NSNumber numberWithFloat:0.33],
									[NSNumber numberWithFloat:0.33],
									[NSNumber numberWithFloat:1],
									nil];
	redArray = [NSMutableArray arrayWithObjects:
									[NSNumber numberWithFloat:1],
									[NSNumber numberWithFloat:0],
									[NSNumber numberWithFloat:0],
									[NSNumber numberWithFloat:1],
									nil];
	fontArray = [NSMutableArray arrayWithObjects:@"Helvetica", [NSNumber numberWithInt:12], nil];
	fixedFontArray = [NSMutableArray arrayWithObjects:@"Courier", [NSNumber numberWithInt:12], nil];
	blackArray = [NSMutableArray arrayWithObjects:
									[NSNumber numberWithFloat:0],
									[NSNumber numberWithFloat:0],
									[NSNumber numberWithFloat:0],
									[NSNumber numberWithFloat:1],
									nil];
    if (!dict) {
        dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            @"", MAC_ISOUsername, 
            @"", MAC_ISOUserEmail, 
            @"<none>", MAC_ISOOrganization, 
			@">", MAC_ISOQuotestring,
            [NSMutableArray array], MAC_ISONNTPServerList, 
            @"", MAC_ISOSubscriptionsDirectory, 
            [NSNumber numberWithBool:YES], MAC_ISOAllowLogicalSubscriptions,
            [NSNumber numberWithBool:NO], MAC_ISOAutoloadSubscription,
            @"", MAC_ISOAutoloadSubscriptionName,
            [NSNumber numberWithBool:NO], MAC_ISOAutocheckSubscriptions, 
            [NSNumber numberWithInt:5], MAC_ISOAutocheckSubscriptionsIntervall, 
            @"", MAC_ISOBinariesDirectory,
            [NSNumber numberWithBool:YES], MAC_ISOExtractBinariesMakeFilenamesUnique,       
            [NSNumber numberWithBool:NO], MAC_ISOExtractBinariesWithExtensions, 
            @"jpg,jpeg,gif,mp3,avi,mov,aiff,png,wav,jpe,mpg,mpeg", MAC_ISOExtractBinariesWithExtensionsText, 
            [NSNumber numberWithBool:YES], MAC_ISODontExtractMultipartBinaries, 
            [NSMutableArray array], MAC_ISOSPAMFilterList,
			[NSMutableArray array], MAC_ISOOutlineColors,
			blackArray, MAC_ISOUnreadArticleColor,
			darkGrayArray, MAC_ISOReadArticleColor,
			redArray, MAC_ISOReplysColor,
			fontArray, MAC_ISOListFont,
			[NSMutableDictionary dictionaryWithObjectsAndKeys:fixedFontArray, MAC_ISOUNKNOWNENCODING, nil], MAC_ISOArticleBodyFont,
			[NSNumber numberWithInt:MAC_ISOUNKNOWNENCODINGINT], MAC_ISODefaultPostingEncoding,
			[NSNumber numberWithInt:kCFStringEncodingISOLatin9], MAC_ISODefaultSendPostingEncoding,
			[NSNumber numberWithInt:72], MAC_ISOWrapAfter,
			[NSNumber numberWithInt:1], MAC_ISODefaultAttachmentEncoding,
			[NSNumber numberWithBool:YES], MAC_ISOSPAMProtectEmailAddress,
			[NSNumber numberWithBool:NO], MAC_ISORememberSentPostings,
			[NSNumber numberWithInt:10], MAC_ISOForgetAfterDays,
			[NSNumber numberWithBool:NO], MAC_ISOSaveSentPostings,
			[NSNumber numberWithBool:YES], MAC_ISOLimitHeadersDownloaded,
			[NSNumber numberWithInt:500], MAC_ISOLimitHeadersDownloadedCount,
			[NSNumber numberWithInt:PREFS_GroupClickedDontCheck], MAC_ISOGroupClickedAction,
			[NSNumber numberWithInt:PREFS_PostingClickedLoad], MAC_ISOPostingClickedAction,
			@"", MAC_ISOSavePostingsDirectory,
			[NSNumber numberWithBool:NO], MAC_ISOAutocheckSubscriptionsAllGroups,
			[NSNumber numberWithBool:YES], MAC_ISOAlertOnFollowupArrival,
			[NSNumber numberWithBool:NO], MAC_ISOAlertOnFollowupArrivalWithSound,
			@"", MAC_ISOAlertOnFollowupArrivalSound,
			[NSNumber numberWithInt:PREFS_ThreadCollapsedDisplay], MAC_ISODefaultThreadDisplay,
			@"In <article> <user> wrote:", MAC_ISOFollowUpBanner,
			[NSNumber numberWithBool:YES], MAC_ISOOpenThreadOnNavigation,
			[NSNumber numberWithBool:NO], MAC_ISOIsOffline,
			[NSNumber numberWithBool:YES], MAC_ISOCheckForUpdates,
			[NSNumber numberWithBool:YES], MAC_ISODisplayThreaded,
			[NSNumber numberWithBool:NO], MAC_ISOSaveOnSubscriptionClose,
			[NSNumber numberWithBool:YES], MAC_ISOSPAMAutoRemoveKillFilters,
			[NSNumber numberWithInt:10], MAC_ISOSPAMARKFDays,
			[NSNumber numberWithBool:YES], MAC_ISOUsenetFormats,
			blackArray, MAC_ISOHeadersColor,
			@"", MAC_ISOMailServer,
			fixedFontArray, MAC_ISOEditorFont,
			[NSNumber numberWithBool:NO], MAC_ISONewPostingArrivedAlert,
			@"", MAC_ISONewPostingArrivedAlertSound,
			[NSNumber numberWithBool:NO], MAC_ISODownloadOKAlert,
			@"", MAC_ISODownloadOKAlertSound,
			[NSNumber numberWithBool:NO], MAC_ISODownloadErrorAlert,
			@"", MAC_ISODownloadErrorAlertSound,
			[NSNumber numberWithBool:NO], MAC_ISOSendingOKAlert,
			@"", MAC_ISOSendingOKAlertSound,
			[NSNumber numberWithBool:NO], MAC_ISOSendingErrorAlert,
			@"", MAC_ISOSendingErrorAlertSound,
			[NSNumber numberWithInt:9999], MAC_ISOStandardPostingLifetime,
			[NSNumber numberWithBool:YES], MAC_ISOSupportXFaceURL,
			[NSNumber numberWithBool:YES], MAC_ISOCreateGroupSubdirs,
			[NSNumber numberWithBool:YES], MAC_ISOCreateDateSubdirs,
			[NSMutableArray array], MAC_ISOAdditionalHeaders,
			[NSNumber numberWithBool:NO], MAC_ISOReloadParentPosting,
			[NSNumber numberWithBool:NO], MAC_ISOCheckSpellingWhileTyping,
			[NSNumber numberWithBool:NO], MAC_ISONoAutomaticUserAgentHeader,
			[NSNumber numberWithBool:NO], MAC_ISONoCatchUpWarnings,
			[NSNumber numberWithBool:NO], MAC_ISONoMarkSubscriptionWarnings,
		nil];
    }
    return dict;
}

@implementation ISOPreferences
static ISOPreferences 	*sharedInstance = nil;
static NSDictionary		*cfstringEncodings = nil;
static NSDictionary		*mimeTypeDictionary = nil;
static NSArray			*encodingDisplayOrder = nil;
/**** Code to deal with defaults ****/
   
#define getBoolDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithBool:[defaults boolForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getIntDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [NSNumber numberWithInt:[defaults integerForKey:name]] : [defaultValues() objectForKey:name] forKey:name];}

#define getDefault(name) \
  {id obj = [defaults objectForKey:name]; \
      [dict setObject:obj ? [defaults objectForKey:name] : [defaultValues() objectForKey:name] forKey:name];}

+ (NSMutableDictionary *)preferencesFromDefaults 
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:10];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    getDefault(MAC_ISOUsername);
    getDefault(MAC_ISOUserEmail);
    getDefault(MAC_ISOOrganization);
	getDefault(MAC_ISOQuotestring);
    getDefault(MAC_ISOSubscriptionsDirectory);
    getBoolDefault(MAC_ISOAllowLogicalSubscriptions);
    getBoolDefault(MAC_ISOAutoloadSubscription);
    getDefault(MAC_ISOAutoloadSubscriptionName);
    getBoolDefault(MAC_ISOAutocheckSubscriptions);
    getIntDefault(MAC_ISOAutocheckSubscriptionsIntervall);
    getDefault(MAC_ISOBinariesDirectory);
    getBoolDefault(MAC_ISOExtractBinariesWithExtensions);
    getDefault(MAC_ISOExtractBinariesWithExtensionsText);
    getBoolDefault(MAC_ISODontExtractMultipartBinaries);
    getBoolDefault(MAC_ISOCreateGroupSubdirs);
    getBoolDefault(MAC_ISOCreateDateSubdirs);
	getBoolDefault(MAC_ISOReloadParentPosting);
    getDefault(MAC_ISOSPAMFilterList);
    getDefault(MAC_ISONNTPServerList);

	getDefault(MAC_ISOOutlineColors);
	getDefault(MAC_ISOUnreadArticleColor);
	getDefault(MAC_ISOReadArticleColor);
	getDefault(MAC_ISOReplysColor);
	getDefault(MAC_ISOListFont);
	getDefault(MAC_ISOArticleBodyFont);
	getDefault(MAC_ISODefaultPostingEncoding);
	getDefault(MAC_ISODefaultSendPostingEncoding);
	getDefault(MAC_ISOWrapAfter);
	getDefault(MAC_ISODefaultAttachmentEncoding);
	getDefault(MAC_ISOSPAMProtectEmailAddress);
	getDefault(MAC_ISORememberSentPostings);
	getDefault(MAC_ISOForgetAfterDays);
	getDefault(MAC_ISOSaveSentPostings);
	getDefault(MAC_ISOSavePostingsDirectory);
	
	getDefault(MAC_ISOLimitHeadersDownloaded);
	getDefault(MAC_ISOLimitHeadersDownloadedCount);
	getDefault(MAC_ISOGroupClickedAction);
	getDefault(MAC_ISOPostingClickedAction);
	
	getDefault(MAC_ISOAutocheckSubscriptionsAllGroups);
	getDefault(MAC_ISOAlertOnFollowupArrival);
	getDefault(MAC_ISOAlertOnFollowupArrivalWithSound);
	getDefault(MAC_ISOAlertOnFollowupArrivalSound);
	getDefault(MAC_ISODefaultThreadDisplay);
	getDefault(MAC_ISOFollowUpBanner);
	getDefault(MAC_ISOOpenThreadOnNavigation);
	getDefault(MAC_ISOIsOffline);
	getDefault(MAC_ISOCheckForUpdates);
	getDefault(MAC_ISODisplayThreaded);

	getDefault(MAC_ISOSaveOnSubscriptionClose);
	getDefault(MAC_ISOSPAMAutoRemoveKillFilters);
	getDefault(MAC_ISOSPAMARKFDays);

	getDefault(MAC_ISOUsenetFormats);
	getDefault(MAC_ISOHeadersColor);

	getDefault(MAC_ISOMailServer);
	getDefault(MAC_ISOEditorFont);
	getDefault(MAC_ISONewPostingArrivedAlert);
	getDefault(MAC_ISONewPostingArrivedAlertSound);
	getDefault(MAC_ISODownloadOKAlert);
	getDefault(MAC_ISODownloadOKAlertSound);
	getDefault(MAC_ISODownloadErrorAlert);
	getDefault(MAC_ISODownloadErrorAlertSound);
	getDefault(MAC_ISOSendingOKAlert);
	getDefault(MAC_ISOSendingOKAlertSound);
	getDefault(MAC_ISOSendingErrorAlert);
	getDefault(MAC_ISOSendingErrorAlertSound);
	getDefault(MAC_ISOStandardPostingLifetime);
	getDefault(MAC_ISOSupportXFaceURL);
	
	getDefault(MAC_ISOAdditionalHeaders);
	getDefault(MAC_ISOCheckSpellingWhileTyping);
	getDefault(MAC_ISONoAutomaticUserAgentHeader);
	getDefault(MAC_ISONoCatchUpWarnings);
	getDefault(MAC_ISONoMarkSubscriptionWarnings);
    return dict;
}

#define setBoolDefault(name) \
  {[defaults setBool:[[dict objectForKey:name] boolValue] forKey:name];}

#define setIntDefault(name) \
  {[defaults setInteger:[[dict objectForKey:name] intValue] forKey:name];}

#define setDefault(name) \
  {[defaults setObject:[dict objectForKey:name] forKey:name];}

+ (void)savePreferencesToDefaults:(NSDictionary *)dict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    setDefault(MAC_ISOUsername);
    setDefault(MAC_ISOUserEmail);
    setDefault(MAC_ISOOrganization);
	setDefault(MAC_ISOQuotestring);
    setDefault(MAC_ISOSubscriptionsDirectory);
    setBoolDefault(MAC_ISOAllowLogicalSubscriptions);
    setBoolDefault(MAC_ISOAutoloadSubscription);
    setDefault(MAC_ISOAutoloadSubscriptionName);
    setBoolDefault(MAC_ISOAutocheckSubscriptions);
    setIntDefault(MAC_ISOAutocheckSubscriptionsIntervall);
    setDefault(MAC_ISOBinariesDirectory);
    setBoolDefault(MAC_ISOExtractBinariesWithExtensions);
    setDefault(MAC_ISOExtractBinariesWithExtensionsText);
    setBoolDefault(MAC_ISODontExtractMultipartBinaries);
    setBoolDefault(MAC_ISOCreateGroupSubdirs);
    setBoolDefault(MAC_ISOCreateDateSubdirs);
	setBoolDefault(MAC_ISOReloadParentPosting);
    setDefault(MAC_ISOSPAMFilterList);
    setDefault(MAC_ISONNTPServerList);

	setDefault(MAC_ISOOutlineColors);
	setDefault(MAC_ISOUnreadArticleColor);
	setDefault(MAC_ISOReadArticleColor);
	setDefault(MAC_ISOReplysColor);
	setDefault(MAC_ISOListFont);
	setDefault(MAC_ISOArticleBodyFont);
	setDefault(MAC_ISODefaultPostingEncoding);
	setDefault(MAC_ISODefaultSendPostingEncoding);
	setDefault(MAC_ISOWrapAfter);
	setDefault(MAC_ISODefaultAttachmentEncoding);
	setDefault(MAC_ISOSPAMProtectEmailAddress);
	setDefault(MAC_ISORememberSentPostings);
	setDefault(MAC_ISOForgetAfterDays);
	setDefault(MAC_ISOSaveSentPostings);
	setDefault(MAC_ISOSavePostingsDirectory);
	
	setDefault(MAC_ISOLimitHeadersDownloaded);
	setDefault(MAC_ISOLimitHeadersDownloadedCount);
	setDefault(MAC_ISOGroupClickedAction);
	setDefault(MAC_ISOPostingClickedAction);

	setDefault(MAC_ISOAutocheckSubscriptionsAllGroups);
	setDefault(MAC_ISOAlertOnFollowupArrival);
	setDefault(MAC_ISOAlertOnFollowupArrivalWithSound);
	setDefault(MAC_ISOAlertOnFollowupArrivalSound);
	setDefault(MAC_ISODefaultThreadDisplay);
	setDefault(MAC_ISOFollowUpBanner);
	setDefault(MAC_ISOOpenThreadOnNavigation);
	setDefault(MAC_ISOIsOffline);
	setDefault(MAC_ISOCheckForUpdates);
	setDefault(MAC_ISODisplayThreaded);

	setDefault(MAC_ISOSaveOnSubscriptionClose);
	setDefault(MAC_ISOSPAMAutoRemoveKillFilters);
	setDefault(MAC_ISOSPAMARKFDays);

	setDefault(MAC_ISOUsenetFormats);
	setDefault(MAC_ISOHeadersColor);

	setDefault(MAC_ISOMailServer);
	setDefault(MAC_ISOEditorFont);
	setDefault(MAC_ISONewPostingArrivedAlert);
	setDefault(MAC_ISONewPostingArrivedAlertSound);
	setDefault(MAC_ISODownloadOKAlert);
	setDefault(MAC_ISODownloadOKAlertSound);
	setDefault(MAC_ISODownloadErrorAlert);
	setDefault(MAC_ISODownloadErrorAlertSound);
	setDefault(MAC_ISOSendingOKAlert);
	setDefault(MAC_ISOSendingOKAlertSound);
	setDefault(MAC_ISOSendingErrorAlert);
	setDefault(MAC_ISOSendingErrorAlertSound);
	setDefault(MAC_ISOStandardPostingLifetime);
	setDefault(MAC_ISOSupportXFaceURL);
	setDefault(MAC_ISOAdditionalHeaders);
	setDefault(MAC_ISOCheckSpellingWhileTyping);
	setDefault(MAC_ISONoAutomaticUserAgentHeader);
	setDefault(MAC_ISONoCatchUpWarnings);
	setDefault(MAC_ISONoMarkSubscriptionWarnings);
	[defaults synchronize];
}

+ (id)objectForKey:(id)key
{
    return [[[self sharedInstance] preferences] objectForKey:key];
}

+ (void)saveDefaults
{
    if (sharedInstance) {
        [ISOPreferences savePreferencesToDefaults:[sharedInstance preferences]];
    }
}

+ (ISOPreferences *)sharedInstance
{
    return sharedInstance ? sharedInstance : [[self alloc] init];
}

- (void)_createEncodingArrays
{
	NSMutableArray			*ianaArray;
	NSMutableDictionary		*encDict;
	const CFStringEncoding	*encodingList = CFStringGetListOfAvailableEncodings();
	int 					i = 0;
	NSString				*title;

	ianaArray = [NSMutableArray arrayWithObjects:@"NONE/Automatic", nil];
	encDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:MAC_ISOUNKNOWNENCODINGINT], @"NONE/Automatic",nil];
	
	while (encodingList[i]!=kCFStringEncodingInvalidId)
	{
		title = (NSString *)CFStringConvertEncodingToIANACharSetName(encodingList[i]);
		if (!title) {
			title = (NSString *)CFStringGetNameOfEncoding(encodingList[i]);
		}
		[ianaArray addObject:title];
		[encDict setObject:[NSNumber numberWithInt:encodingList[i]] forKey:title];
		i++;
	}
	
	encodingDisplayOrder = [NSArray arrayWithArray:ianaArray];
	[encodingDisplayOrder retain];

	cfstringEncodings = [NSDictionary dictionaryWithDictionary:encDict];
	[cfstringEncodings retain];

}

- (id)init
{
    if (sharedInstance) {
        [self dealloc];
    } else {
        [super init];
		editingFontField = nil;
        curValues = [NSMutableDictionary dictionaryWithDictionary:[[self class] preferencesFromDefaults]];
		[curValues retain];
        nntpServerArray = [NSMutableArray arrayWithArray:[curValues objectForKey:MAC_ISONNTPServerList]];
        spamFilterArray = [NSMutableArray arrayWithArray:[curValues objectForKey:MAC_ISOSPAMFilterList]];
		additionalHeaders = [NSMutableArray arrayWithArray:[curValues objectForKey:MAC_ISOAdditionalHeaders]];
		articleBodyFonts = [NSMutableDictionary dictionaryWithDictionary:[curValues objectForKey:MAC_ISOArticleBodyFont]];
		outlineColors = [NSMutableArray arrayWithArray:[curValues objectForKey:MAC_ISOOutlineColors]];
		
		[curValues setObject:nntpServerArray forKey:MAC_ISONNTPServerList];
		[curValues setObject:additionalHeaders forKey:MAC_ISOAdditionalHeaders];
		[curValues setObject:spamFilterArray forKey:MAC_ISOSPAMFilterList];
		[curValues setObject:articleBodyFonts forKey:MAC_ISOArticleBodyFont];
		[curValues setObject:outlineColors forKey:MAC_ISOOutlineColors];
		displayedValues = curValues;
        newsServerMgrs = [[NSMutableArray arrayWithCapacity:0] retain];
        sharedInstance = self;
		[[ISOSignatureMgr sharedSignatureMgr] _loadSignatures];
		[[ISOIdentityMgr sharedIdentityMgr] _loadIdentities];
		[[ISOIdentityMgr sharedIdentityMgr] updateIdentityTable];
		[[ISOSignatureMgr sharedSignatureMgr] updateSignatureTable];
		mimeTypeDictionary =  [NSDictionary dictionaryWithObjectsAndKeys: 
												@"image/jpeg", @"jpg",
												@"image/jpeg", @"jpeg",
												@"image/jpeg", @"jpe",
												@"image/gif", @"gif",
												@"image/tiff", @"tiff",
												@"image/tiff", @"tif",
												@"image/bmp", @"bmp",
												@"image/png", @"png",
												@"audio/basic", @"au",
												@"audio/basic", @"snd",
												@"audio/mpeg", @"mpga",
												@"audio/mpeg", @"mp2",
												@"audio/mpeg", @"mp3",
												@"audio/x-mpegurl", @"m3u",
												@"audio/x-aiff", @"aif",
												@"audio/x-aiff", @"aiff",
												@"audio/x-aiff", @"aifc",
												@"audio/x-wav", @"wav",
												@"audio/x-realaudio", @"ra",
												@"audio/x-pn-realaudio", @"ram",
												@"audio/x-pn-realaudio", @"rm",
												@"video/mpeg", @"mpeg",
												@"video/mpeg", @"mpg",
												@"video/mpeg", @"mpe",
												@"video/quicktime", @"qt",
												@"video/quicktime", @"mov",
												@"video/x-msvideo", @"avi",
												@"application/x-gzip", @"gz",
												@"application/zip", @"zip",
												@"application/mac-binhex40", @"hqx",
												@"application/msword", @"doc",
												@"application/pdf", @"pdf",
												@"aplication/postscript", @"ps",
												@"aplication/postscript", @"ai",
												@"aplication/postscript", @"eps",
												@"application/x-tar", @"tar",
												@"text/html", @"html",
												@"text/rtf", @"rtf",
												@"text/plain", @"txt",
												@"text/css", @"css",
												@"text/sgml", @"sgml",
												@"text/sgml", @"sgm",
												nil];
		[mimeTypeDictionary retain];
		[self _createEncodingArrays];
    }
    return sharedInstance;
}

- (void) awakeFromNib
{
    NSToolbar *toolbar;

    toolbar = [[[NSToolbar alloc] initWithIdentifier: @"ISOPreferencesToolbar"] autorelease];
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setDelegate: self];
	[window setToolbar: toolbar];
}

- (NSArray *)encodingDisplayOrder
{
	return encodingDisplayOrder;
}

- (NSDictionary *)cfstringEncodings
{
	return cfstringEncodings;
}

- (NSDictionary *)mimeTypeDictionary
{
	return mimeTypeDictionary;
}

- (NSFont *)_fontFromFontArray:(NSArray *)fontInfoArray
{
	NSFont	*aFont = nil;
	if (fontInfoArray) {
		aFont = [NSFont fontWithName:[fontInfoArray objectAtIndex:0] size:[[fontInfoArray objectAtIndex:1] floatValue]];
	}
	if (!aFont) {
		aFont = [NSFont userFontOfSize:10.0];
	}
	return aFont;
}



- (void)dealloc
{
    [newsServerMgrs release];
	[cfstringEncodings release];
	[mimeTypeDictionary release];
	[super dealloc];
}

- (NSMutableDictionary *)preferences
{
    return curValues;
}

- (void)createEncodingPopups
{
	[articleBodyEncodingPopup removeAllItems];
	[defaultPostingEncondingPopup removeAllItems];
	[defaultSendEncodingPopup removeAllItems];

	MakeEncodingPopup (articleBodyEncodingPopup, self, @selector(articleBodyEncodingPopupClicked:), YES);
	MakeEncodingPopup (defaultPostingEncondingPopup, self, @selector(miscChanged:), YES);
	MakeEncodingPopup (defaultSendEncodingPopup, self, @selector(miscChanged:), YES);
}

- (void)showPanel:(id)sender
{
    if (!prefsTabview) {
        if (![NSBundle loadNibNamed:@"ISOPreferences" owner:self])  {
            [ISOActiveLogger logWithDebuglevel:1 :@"Failed to load ISOPreferences.nib"];
            NSBeep();
            return;
        }
		[window setExcludedFromWindowsMenu:YES];
		[window setMenu:nil];
		[self createEncodingPopups];
        [self updateUI];
        [window center];
		[self _cleanNNTPFields];
		[spamOperatorMenu setAutoenablesItems:NO];
		[self _cleanSPAMFields];
    }
    [window makeKeyAndOrderFront:nil];
	[dtsMsgField setStringValue:@""];
	[self selectGeneralPrefs:self];
}

- (NSColor *)_getColorFromArray:(NSArray *)colorArray
{
	if (colorArray) {
		NSColor *aColor;
		
		aColor = [NSColor colorWithCalibratedRed:[[colorArray objectAtIndex:0] floatValue]
					green:[[colorArray objectAtIndex:1] floatValue]
					blue:[[colorArray objectAtIndex:2] floatValue]
					alpha:[[colorArray objectAtIndex:3] floatValue]];
		return aColor;
	} else {
		return nil;
	}
}

- (void)_setColorWell:(id)colorWell colorArray:(NSArray *)colorArray
{
	[colorWell setColor:[self _getColorFromArray:colorArray]];
}

- (void)_setFontField:(id)aField toFontFromFontInfoArray:(NSArray *)fontInfoArray
{
	NSFont *aFont = [NSFont fontWithName:[fontInfoArray objectAtIndex:0] size:[[fontInfoArray objectAtIndex:1] floatValue]];
	[self setFontField:aField toFont:aFont];
}

- (void)updateUI
{
    if (!prefsTabview) return;	/* UI hasn't been loaded... */

    [userNameField setStringValue:[displayedValues objectForKey:MAC_ISOUsername]];
    [userEmailField setStringValue:[displayedValues objectForKey:MAC_ISOUserEmail]];
    [organizationField setStringValue:[displayedValues objectForKey:MAC_ISOOrganization]];
    [quoteStringField setStringValue:[displayedValues objectForKey:MAC_ISOQuotestring]];
    
    // NNTP Server List
    
    [autoloadSubscriptionSwitch setState:[[displayedValues objectForKey:MAC_ISOAutoloadSubscription] boolValue]? 1:0];
    [autoloadSubscriptionField setStringValue:[displayedValues objectForKey:MAC_ISOAutoloadSubscriptionName]];
    [autoCheckSubscriptionSwitch setState:[[displayedValues objectForKey:MAC_ISOAutocheckSubscriptions] boolValue]? 1:0];
    [autoCheckSubscriptionIntervallField setIntValue:[[displayedValues objectForKey:MAC_ISOAutocheckSubscriptionsIntervall] intValue]];
    
    [batchExtractionDirectoryField setStringValue:[displayedValues objectForKey:MAC_ISOBinariesDirectory]];
    
    // [batchExtractionMakeFilenamesUniqueRadio ...
    [batchExtractExtractBinariesWithExtSwitch setState:[[displayedValues objectForKey:MAC_ISOExtractBinariesWithExtensions] boolValue]? 1:0];
    [batchExtractExtractBinariesWithExtField setStringValue:[displayedValues objectForKey:MAC_ISOExtractBinariesWithExtensionsText]];

	[batchExtractExtractBinariesWithExtField setEditable:[[displayedValues objectForKey:MAC_ISOExtractBinariesWithExtensions] boolValue]];

    [batchExtractDontExctractMultipartSwitch setState:[[displayedValues objectForKey:MAC_ISODontExtractMultipartBinaries] boolValue]? 1:0];

    [beCreateGroupSubdirsSwitch setState:[[displayedValues objectForKey:MAC_ISOCreateGroupSubdirs] boolValue]? 1:0];
    [beCreateDateSubdirsSwitch setState:[[displayedValues objectForKey:MAC_ISOCreateDateSubdirs] boolValue]? 1:0];
    [reloadParentPostingSwitch setState:[[displayedValues objectForKey:MAC_ISOReloadParentPosting] boolValue]? 1:0];

	[self _setFontField:listFontField toFontFromFontInfoArray:[displayedValues objectForKey:MAC_ISOListFont]];
	[self _setFontField:editorFontField toFontFromFontInfoArray:[displayedValues objectForKey:MAC_ISOEditorFont]];

	[defaultPostingEncondingPopup selectItemWithTag:[[displayedValues objectForKey:MAC_ISODefaultPostingEncoding] intValue]];
	[defaultSendEncodingPopup selectItemWithTag:[[displayedValues objectForKey:MAC_ISODefaultSendPostingEncoding] intValue]];

    [wrapAfterField setIntValue:[[displayedValues objectForKey:MAC_ISOWrapAfter] intValue]];
	// defaultAttachmentEncodingPopup
    [spamProtectEmailSwitch setState:[[displayedValues objectForKey:MAC_ISOSPAMProtectEmailAddress] boolValue]? 1:0];
    [rememberSentSwitch setState:[[displayedValues objectForKey:MAC_ISORememberSentPostings] boolValue]? 1:0];
    [forgetAfterField setIntValue:[[displayedValues objectForKey:MAC_ISOForgetAfterDays] intValue]];
    [saveSentSwitch setState:[[displayedValues objectForKey:MAC_ISOSaveSentPostings] boolValue]? 1:0];
    [saveSentField setStringValue:[displayedValues objectForKey:MAC_ISOSavePostingsDirectory]];
	[chooseSentDirButton setEnabled:[[displayedValues objectForKey:MAC_ISOSaveSentPostings] boolValue]];
	
	if ([outlineColors count]) {
		[self _setColorWell:outlineColor1 colorArray:[outlineColors objectAtIndex:0]];
		[self _setColorWell:outlineColor2 colorArray:[outlineColors objectAtIndex:1]];
		[self _setColorWell:outlineColor3 colorArray:[outlineColors objectAtIndex:2]];
		[self _setColorWell:outlineColor4 colorArray:[outlineColors objectAtIndex:3]];
		[self _setColorWell:outlineColor5 colorArray:[outlineColors objectAtIndex:4]];
		if ([outlineColors count] > 5) {
			[self _setColorWell:outlineColor6 colorArray:[outlineColors objectAtIndex:5]];
		}
	}
	[self _setColorWell:unreadArticleColor colorArray:[displayedValues objectForKey:MAC_ISOUnreadArticleColor]];
	[self _setColorWell:readArticleColor colorArray:[displayedValues objectForKey:MAC_ISOReadArticleColor]];
	[self _setColorWell:replysArticleColor colorArray:[displayedValues objectForKey:MAC_ISOReplysColor]];
	[self _setColorWell:headersColorWell colorArray:[displayedValues objectForKey:MAC_ISOHeadersColor]];

    [limitPostingsDownloadedSwitch setState:[[displayedValues objectForKey:MAC_ISOLimitHeadersDownloaded] boolValue]? 1:0];
    [limitPostingsDownloadedField setIntValue:[[displayedValues objectForKey:MAC_ISOLimitHeadersDownloadedCount] intValue]];
    [groupClickedActionMatrix selectCellWithTag:[[displayedValues objectForKey:MAC_ISOGroupClickedAction] intValue]];
	[postingClickedActionMatrix selectCellWithTag:[[displayedValues objectForKey:MAC_ISOPostingClickedAction] intValue]];

	[checkAllGroupsSwitch setState:[[displayedValues objectForKey:MAC_ISOAutocheckSubscriptionsAllGroups] boolValue]];
	[alertOnFollowUpSwitch setState:[[displayedValues objectForKey:MAC_ISOAlertOnFollowupArrival] boolValue]];
	[alertWithSoundSwitch setState:[[displayedValues objectForKey:MAC_ISOAlertOnFollowupArrivalWithSound] boolValue]];

	[alertSoundField setStringValue:[displayedValues objectForKey:MAC_ISOAlertOnFollowupArrivalSound]];

	[defaultThreadDisplayMatrix selectCellWithTag:[[displayedValues objectForKey:MAC_ISODefaultThreadDisplay] intValue]];

	[followUpBannerField setStringValue:[displayedValues objectForKey:MAC_ISOFollowUpBanner]];

	[openThreadOnNavigationSwitch setState:[[displayedValues objectForKey:MAC_ISOOpenThreadOnNavigation] boolValue]];
	[checkForUpdatesSwitch setState:[[displayedValues objectForKey:MAC_ISOCheckForUpdates] boolValue]];
	[displayThreadedSwitch setState:[[displayedValues objectForKey:MAC_ISODisplayThreaded] boolValue]];
	
	[saveOnCloseSubsSwitch setState:[[displayedValues objectForKey:MAC_ISOSaveOnSubscriptionClose] boolValue]];

	[spamAutoRemoveKillFiltersSwitch setState:[[displayedValues objectForKey:MAC_ISOSPAMAutoRemoveKillFilters] boolValue]];
	[spamAutoRemoveKFField setIntValue:[[displayedValues objectForKey:MAC_ISOSPAMARKFDays] intValue]];
	
	[usenetFormatsSwitch setState:[[displayedValues objectForKey:MAC_ISOUsenetFormats] boolValue]];

	[mailServerField setStringValue:[displayedValues objectForKey:MAC_ISOMailServer]];
	[newPostingArriveAlertSwitch setState:[[displayedValues objectForKey:MAC_ISONewPostingArrivedAlert] boolValue]];
	[newPostingArriveSoundField setStringValue:[displayedValues objectForKey:MAC_ISONewPostingArrivedAlertSound]];

	[downloadOkSoundSwitch setState:[[displayedValues objectForKey:MAC_ISODownloadOKAlert] boolValue]];
	[downloadOkSoundField setStringValue:[displayedValues objectForKey:MAC_ISODownloadOKAlertSound]];

	[downloadErrorSoundSwitch setState:[[displayedValues objectForKey:MAC_ISODownloadErrorAlert] boolValue]];
	[downloadErrorSoundField setStringValue:[displayedValues objectForKey:MAC_ISODownloadErrorAlertSound]];

	[sendingOkSoundSwitch setState:[[displayedValues objectForKey:MAC_ISOSendingOKAlert] boolValue]];
	[sendingOkSoundField setStringValue:[displayedValues objectForKey:MAC_ISOSendingOKAlertSound]];

	[sendingErrorSoundSwitch setState:[[displayedValues objectForKey:MAC_ISOSendingErrorAlert] boolValue]];
	[sendingErrorSoundField setStringValue:[displayedValues objectForKey:MAC_ISOSendingErrorAlertSound]];
	[standardPostingLifetime setIntValue:[[displayedValues objectForKey:MAC_ISOStandardPostingLifetime] intValue]];
	[xFaceURLSupportSwitch setState:[[displayedValues objectForKey:MAC_ISOSupportXFaceURL] boolValue]]; 

	[checkSpellingWhileTypingSwitch setState:[[displayedValues objectForKey:MAC_ISOCheckSpellingWhileTyping] boolValue]];
	
	[noAutoUserAgentHeaderSwitch setState:[[displayedValues objectForKey:MAC_ISONoAutomaticUserAgentHeader] boolValue]];
	
	[noCatchUpWarningsSwitch setState:[[displayedValues objectForKey:MAC_ISONoCatchUpWarnings] boolValue]];
	
	[noMarkSubscriptionWarningsSwitch setState:[[displayedValues objectForKey:MAC_ISONoMarkSubscriptionWarnings] boolValue]];
	
	[self newPostingArrivedAlertSwitchClicked:self];
	[self downloadOKAlertSwitchClicked:self];
	[self downloadErrorAlertSwitchClicked:self];
	[self sendingOKAlertSwitchClicked:self];
	[self sendingErrorAlertSwitchClicked:self];

	[self articleBodyEncodingPopupClicked:self];
	[spamList reloadData];
	[nntpServerlist reloadData];
	[self displayThreadedSwitchClicked:self];
	[self autoloadSubscriptionClicked:self];
	[self autocheckOpenSubscriptionsClicked:self];
	[self rememberSwitchClicked:self];
	[self savePostingsSwitchClicked:self];
	[self limitPostingsSwitchClicked:self];	
	[self alertMeOnFollowUpSwitchClicked:self];	
	[self alertWithSoundSwitchClicked:self];	
	[self spamAutoRemoveKillFiltersSwitchClicked:self];
}

/* Gets everything from UI except for fonts...
*/
- (NSArray *)_getColorArrayFor:(NSColor *)aColor
{
    float	r, g, b, a;
	NSArray	*colorArray;
	
	[aColor getRed:&r green:&g blue:&b alpha:&a];
	colorArray = [NSArray arrayWithObjects:
					[NSNumber numberWithFloat:r],
					[NSNumber numberWithFloat:g],
					[NSNumber numberWithFloat:b],
					[NSNumber numberWithFloat:a],
					nil];
	return colorArray;
}

- (void)_appendColor:(NSColor *)aColor toArray:(NSMutableArray *)anArray
{
	[anArray addObject:[self _getColorArrayFor:aColor]];
}

- (NSArray *)_getFontInfoArrayFromField:(id)aFontField
{
	NSFont		*theFont;
	NSString	*fontName;
	float		pointSize;

	theFont = [aFontField font];
	fontName = [theFont fontName];
	pointSize = [theFont pointSize];		
	
	return [NSMutableArray arrayWithObjects:fontName, [NSNumber numberWithFloat:pointSize], nil];
}

- (void)miscChanged:(id)sender
{
    static NSNumber 	*yes = nil;
    static NSNumber 	*no = nil;
	int					encodingIndex;
	NSString			*encAsString;
	NSMutableDictionary	*theEncDict;
	
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
    }

    [displayedValues setObject:[userNameField stringValue] forKey:MAC_ISOUsername];
    [displayedValues setObject:[userEmailField stringValue] forKey:MAC_ISOUserEmail];
    [displayedValues setObject:[organizationField stringValue] forKey:MAC_ISOOrganization];
    [displayedValues setObject:[quoteStringField stringValue] forKey:MAC_ISOQuotestring];

    [displayedValues setObject:[autoloadSubscriptionSwitch state]? yes:no forKey:MAC_ISOAutoloadSubscription];
    [displayedValues setObject:[autoloadSubscriptionField stringValue] forKey:MAC_ISOAutoloadSubscriptionName];
    [displayedValues setObject:[autoCheckSubscriptionSwitch state]? yes:no forKey:MAC_ISOAutocheckSubscriptions];
    [displayedValues setObject:[NSNumber numberWithInt:[autoCheckSubscriptionIntervallField intValue]] forKey:MAC_ISOAutocheckSubscriptionsIntervall];
    [displayedValues setObject:[batchExtractionDirectoryField stringValue] forKey:MAC_ISOBinariesDirectory];

    [displayedValues setObject:[batchExtractExtractBinariesWithExtSwitch state]? yes:no forKey:MAC_ISOExtractBinariesWithExtensions];
    [displayedValues setObject:[batchExtractExtractBinariesWithExtField stringValue] forKey:MAC_ISOExtractBinariesWithExtensionsText];

    [displayedValues setObject:[batchExtractDontExctractMultipartSwitch state]? yes:no forKey:MAC_ISODontExtractMultipartBinaries];

    [displayedValues setObject:[beCreateGroupSubdirsSwitch state]? yes:no forKey:MAC_ISOCreateGroupSubdirs];
    [displayedValues setObject:[beCreateDateSubdirsSwitch state]? yes:no forKey:MAC_ISOCreateDateSubdirs];
    [displayedValues setObject:[reloadParentPostingSwitch state]? yes:no forKey:MAC_ISOReloadParentPosting];

	[displayedValues setObject:additionalHeaders forKey:MAC_ISOAdditionalHeaders];
    [displayedValues setObject:nntpServerArray forKey:MAC_ISONNTPServerList];
    [displayedValues setObject:spamFilterArray forKey:MAC_ISOSPAMFilterList];

	[outlineColors removeAllObjects];
	[self _appendColor:[outlineColor1 color] toArray:outlineColors];
	[self _appendColor:[outlineColor2 color] toArray:outlineColors];
	[self _appendColor:[outlineColor3 color] toArray:outlineColors];
	[self _appendColor:[outlineColor4 color] toArray:outlineColors];
	[self _appendColor:[outlineColor5 color] toArray:outlineColors];
	[self _appendColor:[outlineColor6 color] toArray:outlineColors];
	[displayedValues setObject:outlineColors forKey:MAC_ISOOutlineColors];

    [displayedValues setObject:[self _getColorArrayFor:[unreadArticleColor color]] forKey:MAC_ISOUnreadArticleColor];
    [displayedValues setObject:[self _getColorArrayFor:[readArticleColor color]] forKey:MAC_ISOReadArticleColor];
    [displayedValues setObject:[self _getColorArrayFor:[replysArticleColor color]] forKey:MAC_ISOReplysColor];
    [displayedValues setObject:[self _getColorArrayFor:[headersColorWell color]] forKey:MAC_ISOHeadersColor];

	[displayedValues setObject:[self _getFontInfoArrayFromField:listFontField] forKey:MAC_ISOListFont];
	[displayedValues setObject:[self _getFontInfoArrayFromField:editorFontField] forKey:MAC_ISOEditorFont];
	
	encodingIndex = [[articleBodyEncodingPopup selectedItem] tag];
	encAsString = [NSString stringWithFormat:@"%d", encodingIndex];
	theEncDict = [displayedValues objectForKey:MAC_ISOArticleBodyFont];
	[theEncDict setObject:[self _getFontInfoArrayFromField:articleBodyEncFontField] forKey:encAsString];

    [displayedValues setObject:[NSNumber numberWithInt:[[defaultSendEncodingPopup selectedItem] tag]] forKey:MAC_ISODefaultSendPostingEncoding];
    [displayedValues setObject:[NSNumber numberWithInt:[[defaultPostingEncondingPopup selectedItem] tag]] forKey:MAC_ISODefaultPostingEncoding];
    [displayedValues setObject:[NSNumber numberWithInt:[wrapAfterField intValue]] forKey:MAC_ISOWrapAfter];
	// defaultAttachmentEncodingPopup
    [displayedValues setObject:[spamProtectEmailSwitch state]? yes:no forKey:MAC_ISOSPAMProtectEmailAddress];
    [displayedValues setObject:[rememberSentSwitch state]? yes:no forKey:MAC_ISORememberSentPostings];

    [displayedValues setObject:[NSNumber numberWithInt:[forgetAfterField intValue]] forKey:MAC_ISOForgetAfterDays];
    [displayedValues setObject:[saveSentSwitch state]? yes:no forKey:MAC_ISOSaveSentPostings];
    [displayedValues setObject:[saveSentField stringValue] forKey:MAC_ISOSavePostingsDirectory];


    [displayedValues setObject:[limitPostingsDownloadedSwitch state]? yes:no forKey:MAC_ISOLimitHeadersDownloaded];

    [displayedValues setObject:[NSNumber numberWithInt:[limitPostingsDownloadedField intValue]] forKey:MAC_ISOLimitHeadersDownloadedCount];
    [displayedValues setObject:[NSNumber numberWithInt:[[groupClickedActionMatrix selectedCell] tag]] forKey:MAC_ISOGroupClickedAction];
    [displayedValues setObject:[NSNumber numberWithInt:[[postingClickedActionMatrix selectedCell] tag]] forKey:MAC_ISOPostingClickedAction];

    [displayedValues setObject:[checkAllGroupsSwitch state]? yes:no forKey:MAC_ISOAutocheckSubscriptionsAllGroups];
    [displayedValues setObject:[alertOnFollowUpSwitch state]? yes:no forKey:MAC_ISOAlertOnFollowupArrival];
    [displayedValues setObject:[alertWithSoundSwitch state]? yes:no forKey:MAC_ISOAlertOnFollowupArrivalWithSound];

    [displayedValues setObject:[alertSoundField stringValue] forKey:MAC_ISOAlertOnFollowupArrivalSound];
    [displayedValues setObject:[NSNumber numberWithInt:[[defaultThreadDisplayMatrix selectedCell] tag]] forKey:MAC_ISODefaultThreadDisplay];

    [displayedValues setObject:[followUpBannerField stringValue] forKey:MAC_ISOFollowUpBanner];

    [displayedValues setObject:[openThreadOnNavigationSwitch state]? yes:no forKey:MAC_ISOOpenThreadOnNavigation];
    [displayedValues setObject:[checkForUpdatesSwitch state]? yes:no forKey:MAC_ISOCheckForUpdates];
	[displayedValues setObject:[displayThreadedSwitch state]? yes:no forKey:MAC_ISODisplayThreaded];


	[displayedValues setObject:[saveOnCloseSubsSwitch state]? yes:no forKey:MAC_ISOSaveOnSubscriptionClose];

	[displayedValues setObject:[spamAutoRemoveKillFiltersSwitch state]? yes:no forKey:MAC_ISOSPAMAutoRemoveKillFilters];
    [displayedValues setObject:[NSNumber numberWithInt:[spamAutoRemoveKFField intValue]] forKey:MAC_ISOSPAMARKFDays];

	[displayedValues setObject:[usenetFormatsSwitch state]? yes:no forKey:MAC_ISOUsenetFormats];

	[displayedValues setObject:[mailServerField stringValue] forKey:MAC_ISOMailServer];

	[displayedValues setObject:[newPostingArriveAlertSwitch state]? yes:no forKey:MAC_ISONewPostingArrivedAlert];
	[displayedValues setObject:[newPostingArriveSoundField stringValue] forKey:MAC_ISONewPostingArrivedAlertSound];

	[displayedValues setObject:[downloadOkSoundSwitch state]? yes:no forKey:MAC_ISODownloadOKAlert];
	[displayedValues setObject:[downloadOkSoundField stringValue] forKey:MAC_ISODownloadOKAlertSound];

	[displayedValues setObject:[downloadErrorSoundSwitch state]? yes:no forKey:MAC_ISODownloadErrorAlert];
	[displayedValues setObject:[downloadErrorSoundField stringValue] forKey:MAC_ISODownloadErrorAlertSound];

	[displayedValues setObject:[sendingOkSoundSwitch state]? yes:no forKey:MAC_ISOSendingOKAlert];
	[displayedValues setObject:[sendingOkSoundField stringValue] forKey:MAC_ISOSendingOKAlertSound];

	[displayedValues setObject:[sendingErrorSoundSwitch state]? yes:no forKey:MAC_ISOSendingErrorAlert];
	[displayedValues setObject:[sendingErrorSoundField stringValue] forKey:MAC_ISOSendingErrorAlertSound];
	[displayedValues setObject:[NSNumber numberWithInt:[standardPostingLifetime intValue]] forKey:MAC_ISOStandardPostingLifetime];

	[displayedValues setObject:[xFaceURLSupportSwitch state]? yes:no forKey:MAC_ISOSupportXFaceURL];

	[displayedValues setObject:[checkSpellingWhileTypingSwitch state]? yes:no forKey:MAC_ISOCheckSpellingWhileTyping];
	[displayedValues setObject:[noAutoUserAgentHeaderSwitch state]? yes:no forKey:MAC_ISONoAutomaticUserAgentHeader];

	[displayedValues setObject:[noCatchUpWarningsSwitch state]? yes:no forKey:MAC_ISONoCatchUpWarnings];

	[displayedValues setObject:[noMarkSubscriptionWarningsSwitch state]? yes:no forKey:MAC_ISONoMarkSubscriptionWarnings];

	[[self class] saveDefaults];
}

- (void)_cleanNNTPFields
{
	[nntpServernameField setStringValue:@""];
	[nntpServerportField setStringValue:@""];
	[nntpNeedsAuthSwitch setState:0];
	[nntpAuthLoginField setStringValue:@""];
	[nntpAuthPasswordField setStringValue:@""];
	[nntpFQDNfield setStringValue:@""];
	[nntpSlowServerSwitch setState:0];
	[nntpNeedsAuthSwitch setState:0];
	[deleteServerButton setEnabled:NO];
	[changeServerButton setEnabled:NO];
	[addServerButton setEnabled:NO];
	[nntpAuthLoginField setEnabled:NO];
	[nntpAuthPasswordField setEnabled:NO];
}

- (void)addNNTPServer:(id)sender
{
	NSMutableDictionary *aServer;
	static NSNumber *yes = nil;
    static NSNumber *no = nil;
    
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
    }
    
    if ([[nntpServernameField stringValue] length] > 3) {
        aServer = [NSMutableDictionary dictionaryWithCapacity:5];
        [aServer setObject:[nntpServernameField stringValue] forKey:@"NNTPSERVERNAME"];
		if ([[nntpServerportField stringValue] length]) {
			[aServer setObject:[nntpServerportField stringValue] forKey:@"NNTPSERVERPORT"];
		} else {
			[aServer setObject:@"119" forKey:@"NNTPSERVERPORT"];
		}
        [aServer setObject:[nntpNeedsAuthSwitch state]? yes:no forKey:@"NNTPSERVERNEEDSAUTH"];
        [aServer setObject:[nntpAuthLoginField stringValue] forKey:@"NNTPSERVERLOGIN"];
        [aServer setObject:[nntpAuthPasswordField stringValue] forKey:@"NNTPSERVERPASSWORD"];
		[aServer setObject:[nntpSlowServerSwitch state]? yes:no forKey:@"NNTPSERVERSLOW"];
		[aServer setObject:[nntpFQDNfield stringValue] forKey:@"NNTPSERVERFQDN"];
        [nntpServerArray addObject:aServer];
        [nntpServerlist reloadData];
		[self miscChanged:self];
		[self _cleanNNTPFields];
    } else {
        [ISOBeep beep:@"News Server Name must have at least 3 characters."];
    }
}

- (void)changeNNTPServer:(id)sender
{
	int	selectedRow = [nntpServerlist selectedRow];
	NSMutableDictionary	*aServer;
	static NSNumber *yes = nil;
    static NSNumber *no = nil;
    
    if (!yes) {
        yes = [[NSNumber alloc] initWithBool:YES];
        no = [[NSNumber alloc] initWithBool:NO];
    }
	
	if (selectedRow >= 0) {
		aServer = [nntpServerArray objectAtIndex:selectedRow];
		if (aServer) {
			[aServer setObject:[nntpServernameField stringValue] forKey:@"NNTPSERVERNAME"];
			if ([[nntpServerportField stringValue] length]) {
				[aServer setObject:[nntpServerportField stringValue] forKey:@"NNTPSERVERPORT"];
			} else {
				[aServer setObject:@"119" forKey:@"NNTPSERVERPORT"];
			}
			[aServer setObject:[nntpNeedsAuthSwitch state]? yes:no forKey:@"NNTPSERVERNEEDSAUTH"];
			[aServer setObject:[nntpAuthLoginField stringValue] forKey:@"NNTPSERVERLOGIN"];
			[aServer setObject:[nntpAuthPasswordField stringValue] forKey:@"NNTPSERVERPASSWORD"];
			[aServer setObject:[nntpSlowServerSwitch state]? yes:no forKey:@"NNTPSERVERSLOW"];
			[aServer setObject:[nntpFQDNfield stringValue] forKey:@"NNTPSERVERFQDN"];
			[self miscChanged:self];
			[self _cleanNNTPFields];
		}
        [nntpServerlist reloadData];
	}
}

- (void)deleteNNTPServer:(id)sender
{
	int	selectedRow = [nntpServerlist selectedRow];
	
	if (selectedRow >= 0) {
		[nntpServerArray removeObjectAtIndex:selectedRow];
		[self miscChanged:self];
        [nntpServerlist reloadData];
		[self _cleanNNTPFields];
	}
}

- (void)serverSelected:(id)sender
{
	int	selectedRow = [nntpServerlist selectedRow];
	NSMutableDictionary	*aServer;
	
	if (selectedRow >= 0) {
		aServer = [nntpServerArray objectAtIndex:selectedRow];
		if (aServer) {
			[nntpServernameField setStringValue:[aServer objectForKey:@"NNTPSERVERNAME"]];
			[nntpServerportField setStringValue:[aServer objectForKey:@"NNTPSERVERPORT"]];
			[nntpNeedsAuthSwitch setState:[[aServer objectForKey:@"NNTPSERVERNEEDSAUTH"] intValue]];
			[nntpAuthLoginField setStringValue:[aServer objectForKey:@"NNTPSERVERLOGIN"]];
			[nntpAuthPasswordField setStringValue:[aServer objectForKey:@"NNTPSERVERPASSWORD"]];
			[nntpSlowServerSwitch setState:[[aServer objectForKey:@"NNTPSERVERSLOW"] intValue]];
			[nntpAuthLoginField setEnabled:[[aServer objectForKey:@"NNTPSERVERNEEDSAUTH"] intValue]];
			[nntpAuthPasswordField setEnabled:[[aServer objectForKey:@"NNTPSERVERNEEDSAUTH"] intValue]];
			[nntpFQDNfield setStringValue:[aServer objectForKey:@"NNTPSERVERFQDN"]? [aServer objectForKey:@"NNTPSERVERFQDN"]:@""];

			[deleteServerButton setEnabled:YES];
			[changeServerButton setEnabled:YES];
			[addServerButton setEnabled:YES];
		} else {
			[deleteServerButton setEnabled:NO];
			[changeServerButton setEnabled:NO];
		}
	} else {
		[deleteServerButton setEnabled:NO];
		[changeServerButton setEnabled:NO];
	}
}

- (void)_cleanSPAMFields
{
	[spamHeaderMenu selectItemAtIndex:0];

	[self _chooseStringOrientedSPAMFilter];
	
	[spamContainsField setStringValue:@""];

	[spamDeleteFilterButton setEnabled:NO];
	[spamChangeFilterButton setEnabled:NO];
	[spamAddFilterButton setEnabled:NO];
}


- (void)_chooseValueOrtientedSPAMFilter
{
	[[spamOperatorMenu itemAtIndex:K_SPAMCONTAINSOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMDOESNOTCONTAINOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMISOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISNOTOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISGREATERTHANOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISLOWERTHANOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXMATCHES] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXDOESNOTMATCH] setEnabled:NO];

	[spamOperatorMenu selectItemAtIndex:K_SPAMISOPERATOR];
}

- (void)_chooseStringOrientedSPAMFilter
{
	[[spamOperatorMenu itemAtIndex:K_SPAMCONTAINSOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMDOESNOTCONTAINOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISNOTOPERATOR] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMISGREATERTHANOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMISLOWERTHANOPERATOR] setEnabled:NO];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXMATCHES] setEnabled:YES];
	[[spamOperatorMenu itemAtIndex:K_SPAMREGEXDOESNOTMATCH] setEnabled:YES];
	[spamOperatorMenu selectItemAtIndex:K_SPAMCONTAINSOPERATOR];
}

- (void)spamWhatMenuSelected:(id)sender
{
	int	selectedItemIndex = [spamHeaderMenu indexOfSelectedItem];

	if ( (selectedItemIndex == K_SPAMDATEMENU) || 
		 (selectedItemIndex == K_SPAMNEWSGROUPSCOUNTMENU) ||
		 (selectedItemIndex == K_SPAMSIZEMENU) ) {
		[self _chooseValueOrtientedSPAMFilter];
	} else {
		[self _chooseStringOrientedSPAMFilter];
	}
	
}

- (void)spamOperatorMenuSelected:(id)sender
{
}

- (void)spamFilterSelected:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	NSMutableDictionary	*aFilter;
	
	if (selectedRow >= 0) {
		aFilter = [spamFilterArray objectAtIndex:selectedRow];
		if (aFilter) {
			[spamHeaderMenu selectItemAtIndex:[[aFilter objectForKey:@"SPAMFILTERWHAT"] intValue]];
			[self spamWhatMenuSelected:self];
			[spamOperatorMenu selectItemAtIndex:[[aFilter objectForKey:@"SPAMFILTEROPERATOR"] intValue]];
			[spamContainsField setStringValue:[aFilter objectForKey:@"SPAMFILTERVALUE"]];

			[spamDeleteFilterButton setEnabled:YES];
			[spamChangeFilterButton setEnabled:YES];
			[spamAddFilterButton setEnabled:YES];
		} else {
			[spamDeleteFilterButton setEnabled:NO];
			[spamChangeFilterButton setEnabled:NO];
		}
	} else {
		[spamDeleteFilterButton setEnabled:NO];
		[spamChangeFilterButton setEnabled:NO];
	}
}

- (void)addSPAMFilter:(id)sender
{
	NSMutableDictionary *aFilter;
    
    if ([[spamContainsField stringValue] length] > 0) {
        aFilter = [NSMutableDictionary dictionaryWithCapacity:3];
        [aFilter setObject:[NSNumber numberWithInt:[spamHeaderMenu indexOfSelectedItem]] forKey:@"SPAMFILTERWHAT"];
        [aFilter setObject:[NSNumber numberWithInt:[spamOperatorMenu indexOfSelectedItem]] forKey:@"SPAMFILTEROPERATOR"];
        [aFilter setObject:[spamContainsField stringValue] forKey:@"SPAMFILTERVALUE"];
        [aFilter setObject:[NSNumber numberWithInt:K_SPAMIGNOREACTION] forKey:@"SPAMFILTERACTION"];

        [spamFilterArray addObject:aFilter];
        [spamList reloadData];
		[self miscChanged:self];
		[self _cleanSPAMFields];
    } else {
        [ISOBeep beep:@"SPAM Filter value part must be at least one character"];
    }
}

- (void)changeSPAMFilter:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	NSMutableDictionary	*aFilter;

	if (selectedRow >= 0) {
		aFilter = [spamFilterArray objectAtIndex:selectedRow];
		if (aFilter) {
			[aFilter setObject:[NSNumber numberWithInt:[spamHeaderMenu indexOfSelectedItem]] forKey:@"SPAMFILTERWHAT"];
			[aFilter setObject:[NSNumber numberWithInt:[spamOperatorMenu indexOfSelectedItem]] forKey:@"SPAMFILTEROPERATOR"];
			[aFilter setObject:[spamContainsField stringValue] forKey:@"SPAMFILTERVALUE"];
			[aFilter setObject:[NSNumber numberWithInt:K_SPAMIGNOREACTION] forKey:@"SPAMFILTERACTION"];
			[self miscChanged:self];
			[self _cleanSPAMFields];
		}
        [spamList reloadData];
	}
}

- (void)deleteSPAMFilter:(id)sender
{
	int	selectedRow = [spamList selectedRow];
	
	if (selectedRow >= 0) {
		[spamFilterArray removeObjectAtIndex:selectedRow];
		[self miscChanged:self];
        [spamList reloadData];
		[self _cleanSPAMFields];
	}
}

- (void)chooseAutoloadSubscription:(id)sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	NSMutableArray	*anArray = [NSMutableArray arrayWithCapacity:1];
	NSString		*theFilename;
	
	[anArray addObject:@"halime"];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForTypes:anArray] == NSOKButton) {
		theFilename = [[openPanel filenames] objectAtIndex:0];
		[autoloadSubscriptionField setStringValue:theFilename];
		[displayedValues setObject:[autoloadSubscriptionField stringValue] forKey:MAC_ISOAutoloadSubscriptionName];
		[self miscChanged:self];
	}
}

/* **** TABLE ISSUES **** */
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == nntpServerlist) {
        return [nntpServerArray count];
    } else if (aTableView == spamList) {
        return [spamFilterArray count];
    } else if (aTableView == headerTable) {
        return [additionalHeaders count];
    } else {
        return 0;
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == nntpServerlist) {
        return [self nntpServerValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == spamList) {
        return [self spamFilterValueForTableColumn:aTableColumn row:rowIndex];
    } else if (aTableView == headerTable) {
        return [self headerValueForTableColumn:aTableColumn row:rowIndex];
    } else {
        return nil;
    }

}
- (id)headerValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((rowIndex >= 0) && (rowIndex < [additionalHeaders count])) {
		if ([(NSString *)[aTableColumn identifier] compare:@"HEADER"] == NSOrderedSame) {
			return [[additionalHeaders objectAtIndex:rowIndex] objectAtIndex:0];
		} else {
			return [[additionalHeaders objectAtIndex:rowIndex] objectAtIndex:1];
		}
	} else {
		return @"";
	}
}

- (id)nntpServerValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableDictionary *aDict;

    NSParameterAssert(rowIndex >= 0 && rowIndex < [nntpServerArray count]);
    aDict = [nntpServerArray objectAtIndex:rowIndex];
	if (([(NSString *)[aTableColumn identifier] compare:@"NNTPSERVERNEEDSAUTH"] == NSOrderedSame) ||
		([(NSString *)[aTableColumn identifier] compare:@"NNTPSERVERSLOW"] == NSOrderedSame) ){
		return [[aDict objectForKey:[aTableColumn identifier]] intValue]? NSLocalizedString(@"YES", @""):NSLocalizedString(@"NO", @"");
	} else if ([(NSString *)[aTableColumn identifier] compare:@"NNTPSERVERPASSWORD"] == NSOrderedSame) {
		if ([[aDict objectForKey:@"NNTPSERVERNEEDSAUTH"] intValue]) {
			return @"**********";
		} else {
			return @"";
		}
	} else {
		return [aDict objectForKey:[aTableColumn identifier]];
	}
}

- (id)spamFilterValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSMutableDictionary *aDict;
	NSArray		*s_spamFilterTexts = [NSArray arrayWithObjects:
				@"From:",
				@"Subject:",
				@"Newsgroups:",
				@"Date:",
				@"# of groups posted to:",
				@"Size:",
				nil];
	NSArray		*s_spamFilterOperatorTexts = [NSArray arrayWithObjects:
				@"contains",
				@"does not contain",
				@"is",
				@"is not",
				@"is greater than",
				@"is lower than",
				@"RE matches",
				@"RE does not match",
				nil];
	
    NSParameterAssert(rowIndex >= 0 && rowIndex < [spamFilterArray count]);
    aDict = [spamFilterArray objectAtIndex:rowIndex];
 
	if (aDict) {
		if ([(NSString *)[aTableColumn identifier] compare:@"SPAMFILTERWHAT"] == NSOrderedSame) {
			NSString *aKey = [s_spamFilterTexts objectAtIndex:[[aDict objectForKey:[aTableColumn identifier]] intValue]];
			return NSLocalizedString(aKey,@"");
		} else if ([(NSString *)[aTableColumn identifier] compare:@"SPAMFILTEROPERATOR"] == NSOrderedSame) {
			NSString *aKey = [s_spamFilterOperatorTexts objectAtIndex:[[aDict objectForKey:[aTableColumn identifier]] intValue]];
			return NSLocalizedString(aKey,@"");
		} else {
			return [aDict objectForKey:[aTableColumn identifier]];
		}
	} else {
		return @"";
	}
}

/**** Window delegation ****/

- (BOOL)windowShouldClose:(id)aWindow
{
	[[self class] saveDefaults];
	return YES;
}


/* XXXClicked Methods called by the UI */
- (void)articleBodyEncodingPopupClicked:sender
{
	NSFont	*aFont;
	int		encodingIndex;

	encodingIndex = [[articleBodyEncodingPopup selectedItem] tag];
	aFont = [self articleBodyFontForEncoding:encodingIndex];
	[self setFontField:articleBodyEncFontField toFont:aFont];
    [[NSFontManager sharedFontManager] setSelectedFont:[articleBodyEncFontField font] isMultiple:NO];

}

- (void)needsAuthenticationClicked:(id)sender
{
	[nntpAuthLoginField setEnabled:[nntpNeedsAuthSwitch state]];
	[nntpAuthPasswordField setEnabled:[nntpNeedsAuthSwitch state]];
		
	[self miscChanged:self];
}

- (void)autoloadSubscriptionClicked:(id)sender
{
	[autoloadSubscriptionChooseButton setEnabled:[autoloadSubscriptionSwitch state]];
	[self miscChanged:self];
}


- (void)autocheckOpenSubscriptionsClicked:(id)sender
{
	[autoCheckSubscriptionIntervallField setEnabled:[autoCheckSubscriptionSwitch state]];
	[checkAllGroupsSwitch setEnabled:[autoCheckSubscriptionSwitch state]];
	[self miscChanged:self];
}


- (void)extractBinariesWithExtensionsClicked:(id)sender
{
	[batchExtractExtractBinariesWithExtField setEditable:[batchExtractExtractBinariesWithExtSwitch state]];
	[self miscChanged:self];
}

- (void)chooseBinaryExtractionDirectory:(id)sender
{
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"", nil]] == NSOKButton) {
		[batchExtractionDirectoryField setStringValue:[[openPanel filenames] objectAtIndex:0]];
		[self miscChanged:self];
	}
}

- (void)displayThreadedSwitchClicked:(id)sender
{
	[defaultThreadDisplayMatrix setEnabled:[displayThreadedSwitch state]];
	if (![displayThreadedSwitch state]) {
		[openThreadOnNavigationSwitch setState:1];
	}
	[openThreadOnNavigationSwitch setEnabled:[displayThreadedSwitch state]];
	[self miscChanged:self];
	[dtsMsgField setStringValue:NSLocalizedString(@"Changes will take effect for the next subscription opened.", @"")];
}

- (int)serverCount
{
    return [nntpServerArray count];
}

- (ISONewsServerMgr *)createNewsServerMgrForServer:(NSString *)newsServerName addToPool:(BOOL)addToPool
{
    ISONewsServerMgr	*theMgr = nil;
    ISONewsServer		*aServer;
    int	i, count;
    BOOL found;

	count = [nntpServerArray count];
	i = 0;
	found = NO;
	while (!found && (i<count)) {
		NSDictionary *aDict = [nntpServerArray objectAtIndex:i];
		NSString *aString = [aDict objectForKey:@"NNTPSERVERNAME"];
		if ([aString compare:newsServerName] == NSOrderedSame) {
			aServer = [[ISONewsServer alloc] initWithServer:aString
							port:[[aDict objectForKey:@"NNTPSERVERPORT"] intValue]
							authenticate:[[aDict objectForKey:@"NNTPSERVERNEEDSAUTH"] boolValue]
							usingLogin:[aDict objectForKey:@"NNTPSERVERLOGIN"]
							andPassword:[aDict objectForKey:@"NNTPSERVERPASSWORD"]];
			[aServer setIsSlowServer:[[aDict objectForKey:@"NNTPSERVERSLOW"] boolValue]];
			[aServer setFQDN:[aDict objectForKey:@"NNTPSERVERFQDN"]];
			theMgr = [[ISONewsServerMgr alloc] initForServer:aServer];
			found = YES;
		}
		i++;
	}
	if (found) {
		if (addToPool && theMgr) {
			[newsServerMgrs addObject:theMgr];
		}
		return theMgr;
	} else {
		return nil;
	}
}


- (ISONewsServerMgr *)newsServerMgrForServer:(NSString *)newsServerName
{
    ISONewsServerMgr	*aMgr, *theMgr;
    ISONewsServer		*aServer;
    int	i, count;
    BOOL found;
    
    found = NO;
    i = 0;
    count = [newsServerMgrs count];
    theMgr = nil;
    while (!found && (i<count)) {
        aMgr = [newsServerMgrs objectAtIndex:i];
        aServer = [aMgr newsServer];
        if ( ([[aServer serverName] compare:newsServerName] == NSOrderedSame) && (![aMgr isBeingUsed])){
            found = YES;
            theMgr = aMgr;
        }
        i++;
    }
    if (!found) {
		theMgr = [self createNewsServerMgrForServer:newsServerName addToPool:YES];
    }
    return theMgr;
}

- (ISONewsServerMgr *)newsServerMgrForServerAtIndex:(int)index
{
    NSDictionary *aS = [self nntpServerInfoAtIndex:index];
    NSString	*aString = [aS objectForKey:@"NNTPSERVERNAME"];
    return [self newsServerMgrForServer:aString];
}

- (NSDictionary *)nntpServerInfoAtIndex:(int)index
{
    return [nntpServerArray objectAtIndex:index];
}


- (void)rememberSwitchClicked:sender
{
	[forgetAfterField setEnabled:[rememberSentSwitch state]];
	[self miscChanged:sender];
}

- (void)savePostingsSwitchClicked:sender
{
	[chooseSentDirButton setEnabled:[saveSentSwitch state]];
	[self miscChanged:sender];
}

- (void)limitPostingsSwitchClicked:sender
{
	[limitPostingsDownloadedField setEnabled:[limitPostingsDownloadedSwitch state]];
	[self miscChanged:sender];
}

- (void)chooseSaveDirectory:sender
{
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"", nil]] == NSOKButton) {
		[saveSentField setStringValue:[[openPanel filenames] objectAtIndex:0]];
		[self miscChanged:self];
	}
}

- (void)spamAutoRemoveKillFiltersSwitchClicked:sender
{
	[spamAutoRemoveKFField setEnabled:[spamAutoRemoveKillFiltersSwitch state]];
	[self miscChanged:sender];
}

- (void)alertMeOnFollowUpSwitchClicked:sender
{
	[alertWithSoundSwitch setEnabled:[alertOnFollowUpSwitch state]];
	[self miscChanged:sender];
}

- (void)alertWithSoundSwitchClicked:sender
{
	[alertSoundChooseButton setEnabled:[alertWithSoundSwitch state]? YES:NO];
	[self miscChanged:sender];
}

- (NSString *)_chooseASoundFile
{
	NSOpenPanel	*openPanel = [NSOpenPanel openPanel];
	
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	if ([openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObjects:@"snd", @"aiff", @"wav", nil]] == NSOKButton) {
		NSString 	*soundName = [[openPanel filenames] objectAtIndex:0];
		NSSound		*aSound = nil;
		if (soundName && [soundName length]) {
			aSound = [[NSSound alloc] initWithContentsOfFile:soundName byReference:YES];
		}
		if (!aSound) {
			NSBeep();
			return @"";
		} else {
			[aSound setDelegate:self];
			if (![aSound play]) {
				NSBeep();
				return @"";
			} else {
				return soundName;
			}
		}
	} else {
		return @"";
	}
}

- (void)chooseAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[alertSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (void)chooseListFont:sender
{
	editingFontField = listFontField;
	[self openFontPanel:self];
}

- (void)chooseBodyFont:sender
{
	editingFontField = articleBodyEncFontField;
	[self openFontPanel:self];
}

- (void)setCurrentFontForAllEncodings:sender
{
	int	choice = NSRunAlertPanel(NSLocalizedString(@"One Font to Display Them All", @""),
					NSLocalizedString(@"Are you really sure that you know what you are doing? You are going to set one font for all encodings, is this what you really, really want?", @""),
					NSLocalizedString(@"Yes, One Font For All", @""),
					nil,
					NSLocalizedString(@"Yikes! No! No Way!", @""));
	if (choice == NSAlertDefaultReturn) {
		int 				i, count;
		NSArray				*keyArray = [cfstringEncodings allKeys];
		NSFont				*theFont = [articleBodyEncFontField font];
		NSString			*fontName = [theFont fontName];
		float				pointSize = [theFont pointSize];
		NSMutableDictionary	*theEncDict;
		NSMutableArray		*fontInfoArray;
		
		count = [keyArray count];
		theEncDict = [displayedValues objectForKey:MAC_ISOArticleBodyFont];
		fontInfoArray = [NSMutableArray arrayWithObjects:fontName, [NSNumber numberWithFloat:pointSize], nil];
		for (i=0;i<count;i++) {
			[theEncDict setObject:fontInfoArray forKey:[[cfstringEncodings objectForKey:[keyArray objectAtIndex:i]] stringValue]];
		}
		[self miscChanged:self];
	}
}

- (void)setFontField:(id)fontField toFontNamed:(NSString *)fontName andSize:(float)size
{
    [fontField setStringValue:[NSString stringWithFormat:@"%@ %.1f", fontName, size]];
}

- (void)setFontField:(id)fontField toFont:(NSFont *)font
{
    if (!font) return;
    [fontField setFont:font];
	[self setFontField:fontField toFontNamed:[font familyName] andSize:[font pointSize]];
}


- (IBAction)openFontPanel:(id)sender
{
    [window makeFirstResponder:nil];     // Make sure *we* get the changeFont: call
    [[NSFontManager sharedFontManager] setSelectedFont:[editingFontField font] isMultiple:NO];
    [[NSFontPanel sharedFontPanel] orderFront:self];   // Leave us as key
}

/* We only allow fixed-pitch fonts.  Does not seem to be called on OSX. */
- (BOOL)fontManager:(id)sender willIncludeFont:(NSString *)fontName
{
    return YES; // [sender fontNamed:fontName hasTraits:NSFixedPitchFontMask];
}

- (void)changeFont:(id)sender
{
    NSFont *font = [editingFontField font];
	
    font = [sender convertFont:font];
    [self setFontField:editingFontField toFont:font];
	if (editingFontField == listFontField) {
		[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOListFontChanged" object:nil]];
	}
	[self miscChanged:self];
}


/* ***************************** ****** */
- (NSString *)prefsUserName
{
	return [displayedValues objectForKey:MAC_ISOUsername];
}

- (NSString *)prefsUserEmail
{
	return [displayedValues objectForKey:MAC_ISOUserEmail];
}

- (NSString *)prefsQuoteString
{
	return [displayedValues objectForKey:MAC_ISOQuotestring];
}

- (NSCharacterSet *)prefsQuoteCharacterSet
{
	return [NSCharacterSet characterSetWithCharactersInString:[self prefsQuoteString]];
}

- (NSString *)prefsOrganization
{
	return [displayedValues objectForKey:MAC_ISOOrganization];
}

- (NSArray *)prefsQuoteColors
{
	return outlineColors;
}

- (void)textDidChange:(NSNotification *)aNotification
{
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if ([aNotification object] == nntpServernameField) {
		[addServerButton setEnabled:([[nntpServernameField stringValue] length] >= 3)];
		[deleteServerButton setEnabled:([[nntpServernameField stringValue] length] >= 3) && ([nntpServerlist selectedRow]>=0)];
		[changeServerButton setEnabled:([[nntpServernameField stringValue] length] >= 3) && ([nntpServerlist selectedRow]>=0)];
	} else if ([aNotification object] == spamContainsField) {
		[spamAddFilterButton setEnabled:[[spamContainsField stringValue] length]];
		[spamDeleteFilterButton setEnabled:[[spamContainsField stringValue] length] && ([spamList selectedRow]>=0)];
		[spamChangeFilterButton setEnabled:[[spamContainsField stringValue] length] && ([spamList selectedRow]>=0)];
	} else if (([aNotification object] == listFontField) || ([aNotification object] == articleBodyEncFontField)) {
		if ([aNotification object] == listFontField) {
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"ISOListFontChanged" object:nil]];
		}
	} else if (([aNotification object] == headerField) || ([aNotification object] == valueField)) {
		[self headerEntryFieldsChanged:aNotification];
	}
	
	[self miscChanged:self];
}

- (BOOL)prefsAutoloadSubscription
{
	return [[displayedValues objectForKey:MAC_ISOAutoloadSubscription] intValue];
}

- (NSString *)prefsAutoloadSubscriptionFilename
{
	return [displayedValues objectForKey:MAC_ISOAutoloadSubscriptionName];
}

- (NSDictionary *)prefsArticleBodyFonts
{
	return [displayedValues objectForKey:MAC_ISOArticleBodyFont];
}

- (NSFont *)prefsListviewFont
{
	return [self _fontFromFontArray:[displayedValues objectForKey:MAC_ISOListFont]];
}

- (NSFont *)articleBodyFontForEncoding:(NSStringEncoding )encoding
{
	NSString	*encKey;
	
	if (encoding < 0) {
		encoding = MAC_ISOUNKNOWNENCODINGINT;
	}
	encKey = [NSString stringWithFormat:@"%d", encoding];
	return [self _fontFromFontArray:[[displayedValues objectForKey:MAC_ISOArticleBodyFont] objectForKey:encKey]];
}

- (BOOL)prefsAutoCheckSubscription
{
	return [[displayedValues objectForKey:MAC_ISOAutocheckSubscriptions] boolValue];
}

- (int)prefsAutoCheckSubscriptionInterval
{
	return [[displayedValues objectForKey:MAC_ISOAutocheckSubscriptionsIntervall] intValue];
}

- (NSColor *)prefsUnreadArticleColor
{
	return [self _getColorFromArray:[displayedValues objectForKey:MAC_ISOUnreadArticleColor]];
}

- (NSColor *)prefsReadArticleColor
{
	return [self _getColorFromArray:[displayedValues objectForKey:MAC_ISOReadArticleColor]];
}

- (NSColor *)prefsReplysColor
{
	return [self _getColorFromArray:[displayedValues objectForKey:MAC_ISOReplysColor]];
}

- (BOOL)prefsRememberSentPostings
{
	return [[displayedValues objectForKey:MAC_ISORememberSentPostings] boolValue];
}

- (BOOL)prefsSaveSentPostings
{
	return [[displayedValues objectForKey:MAC_ISOSaveSentPostings] boolValue];
}

- (NSString *)prefsSentPostingsSaveDirectory
{
	return [displayedValues objectForKey:MAC_ISOSavePostingsDirectory];
}

- (int)prefsWrapTextLength
{
	return [[displayedValues objectForKey:MAC_ISOWrapAfter] intValue];
}

- (BOOL)prefsWrapText
{
	return ([[displayedValues objectForKey:MAC_ISOWrapAfter] intValue] > 0);
}

- (BOOL)prefsLimitHeadersDownloaded
{
	return [[displayedValues objectForKey:MAC_ISOLimitHeadersDownloaded] boolValue];
}

- (int)prefsNumberOfMaxHeadersToDownload
{
	return [[displayedValues objectForKey:MAC_ISOLimitHeadersDownloadedCount] intValue];
}

- (int)prefsGroupClickedAction
{
	return [[displayedValues objectForKey:MAC_ISOGroupClickedAction] intValue];
}

- (int)prefsPostingClickedAction
{
	return [[displayedValues objectForKey:MAC_ISOPostingClickedAction] intValue];
}

- (BOOL)prefsCheckForAllGroups
{
	return [[displayedValues objectForKey:MAC_ISOAutocheckSubscriptionsAllGroups] boolValue];
}

- (BOOL)prefsAlertOnFollowUp
{
	return [[displayedValues objectForKey:MAC_ISOAlertOnFollowupArrival] boolValue];
}

- (BOOL)prefsAlertOnFollowUpWithSound
{
	return [[displayedValues objectForKey:MAC_ISOAlertOnFollowupArrivalWithSound] boolValue];
}

- (NSString *)prefsFollowUpAlertSound
{
	return [displayedValues objectForKey:MAC_ISOAlertOnFollowupArrivalSound];
}

- (int)prefsDefaultThreadDisplay
{
	return [[displayedValues objectForKey:MAC_ISODefaultThreadDisplay] intValue];
}

- (NSString *)prefsFollowUpBanner
{
	return [displayedValues objectForKey:MAC_ISOFollowUpBanner];
}

- (BOOL)prefsOpenThreadOnNavigation
{
	return [[displayedValues objectForKey:MAC_ISOOpenThreadOnNavigation] boolValue];
}

- (int)prefsDefaultPostingEncoding
{
	return [[displayedValues objectForKey:MAC_ISODefaultPostingEncoding] intValue];
}

- (int)prefsDefaultSendPostingEncoding
{
	return [[displayedValues objectForKey:MAC_ISODefaultSendPostingEncoding] intValue];
}

- (BOOL)prefsDisplayPostingsThreaded
{
	return [[displayedValues objectForKey:MAC_ISODisplayThreaded] boolValue];
}

- (NSArray *)prefsGlobalSPAMFilters
{
	return spamFilterArray;
}


- (void)setController:(id)anObject
{
	controller = anObject;
}

- (id)controller
{
	return controller;
}

- (void)chooseEditorFont:sender
{
	editingFontField = editorFontField;
	[self openFontPanel:self];
}

- (void)newPostingArrivedAlertSwitchClicked:sender
{
	[newPostingArriveButton setEnabled:[newPostingArriveAlertSwitch state]];
	[self miscChanged:self];
}

- (void)chooseNewPostingAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[newPostingArriveSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (void)downloadOKAlertSwitchClicked:sender
{
	[downloadOkSoundButton setEnabled:[downloadOkSoundSwitch state]];
}

- (void)chooseDownloadOKAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[downloadOkSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (void)downloadErrorAlertSwitchClicked:sender
{
	[downloadErrorSoundButton setEnabled:[downloadErrorSoundSwitch state]];
}

- (void)chooseDownloadErrorAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[downloadErrorSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (void)sendingOKAlertSwitchClicked:sender
{
	[sendingOkSoundButton setEnabled:[sendingOkSoundSwitch state]];
}

- (void)chooseSendingOKAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[sendingOkSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (void)sendingErrorAlertSwitchClicked:sender
{
	[sendingErrorSoundButton setEnabled:[sendingErrorSoundSwitch state]];
}

- (void)chooseSendingErrorAlertSound:sender
{
	NSString *sFile = [self _chooseASoundFile];
	if (sFile && [sFile length]) {
		[sendingErrorSoundField setStringValue:sFile];
		[self miscChanged:self];
	}
}

- (BOOL)isOffline
{
	return [[displayedValues objectForKey:MAC_ISOIsOffline] boolValue];
}

- (void)setIsOffline:(BOOL)flag
{
	int	i, count;
	
	[displayedValues setObject:[NSNumber numberWithBool:flag] forKey:MAC_ISOIsOffline];

	if (flag) {
		count = [newsServerMgrs count];
		for (i=0;i<count;i++) {
			[[newsServerMgrs objectAtIndex:i] hardcoreDisconnect];
		}
	}
	if (controller) {
		[controller goOffline:flag];
	}
	[[self class] saveDefaults];
}

- (BOOL)prefsCheckForUpdates
{
	return [[displayedValues objectForKey:MAC_ISOCheckForUpdates] boolValue];
}


- (BOOL)prefsSaveOnCloseSubscription
{
	return [[displayedValues objectForKey:MAC_ISOSaveOnSubscriptionClose] boolValue];
}

- (BOOL)prefsSPAMAutoRemoveKillFilter
{
	return [[displayedValues objectForKey:MAC_ISOSPAMAutoRemoveKillFilters] boolValue];
}

- (int)prefsSPAMARKFDays
{
	return [[displayedValues objectForKey:MAC_ISOSPAMARKFDays] intValue];
}

- (BOOL)prefsUsenetFormats
{
	return [[displayedValues objectForKey:MAC_ISOUsenetFormats] boolValue];
}

- (NSColor *)prefsHeadersColor
{
	NSArray	*colorDataArray = [displayedValues objectForKey:MAC_ISOHeadersColor];
	
	return [NSColor colorWithCalibratedRed:[[colorDataArray objectAtIndex:0] floatValue]
		green:[[colorDataArray objectAtIndex:1] floatValue]
		blue:[[colorDataArray objectAtIndex:2] floatValue]
		alpha:[[colorDataArray objectAtIndex:3] floatValue]];
}

- (NSString *)prefsMailServer
{
	return [displayedValues objectForKey:MAC_ISOMailServer];
}

- (NSFont *)prefsEditorFont
{
	return [self _fontFromFontArray:[displayedValues objectForKey:MAC_ISOEditorFont]];
}

- (BOOL)prefsShouldNewPostingArrivedAlert
{
	return [[displayedValues objectForKey:MAC_ISONewPostingArrivedAlert] boolValue];
}

- (NSString *)prefsNewPostingArrivedAlertSoundName
{
	return [displayedValues objectForKey:MAC_ISONewPostingArrivedAlertSound];
}

- (BOOL)prefsShouldDownloadOKAlert
{
	return [[displayedValues objectForKey:MAC_ISODownloadOKAlert] boolValue];
}

- (NSString *)prefsDownloadOKAlertSoundName
{
	return [displayedValues objectForKey:MAC_ISODownloadOKAlertSound];
}

- (BOOL)prefsShouldDownloadErrorAlert
{
	return [[displayedValues objectForKey:MAC_ISODownloadErrorAlert] boolValue];
}

- (NSString *)prefsDownloadErrorAlertSoundName
{
	return [displayedValues objectForKey:MAC_ISODownloadErrorAlertSound];
}

- (BOOL)prefsShouldSendingOKAlert
{
	return [[displayedValues objectForKey:MAC_ISOSendingOKAlert] boolValue];
}

- (NSString *)prefsSendingOKAlertSoundName
{
	return [displayedValues objectForKey:MAC_ISOSendingOKAlertSound];
}

- (BOOL)prefsShouldSendingErrorAlert
{
	return [[displayedValues objectForKey:MAC_ISOSendingErrorAlert] boolValue];
}

- (NSString *)prefsSendingErrorAlertSoundName
{
	return [displayedValues objectForKey:MAC_ISOSendingErrorAlertSound];
}


- (void)prefsAlertWithSoundKey:(NSString *)soundKey
{
	NSString 	*soundName = [displayedValues objectForKey:soundKey];
	if (soundName && [soundName length]) {
		NSSound		*aSound = [[NSSound alloc] initWithContentsOfFile:soundName byReference:YES];
		if (!aSound) {
			NSBeep();
		} else {
			[aSound setDelegate:self];
			if (![aSound play]) {
				NSBeep();
			}
		}
	}
}


- (int)prefsStandardPostingLifetime
{
	return [[displayedValues objectForKey:MAC_ISOStandardPostingLifetime] intValue];
}

- (BOOL)prefsSupportXFaceURL
{
	return [[displayedValues objectForKey:MAC_ISOSupportXFaceURL] boolValue];
}

- (NSString *)prefsExtractionDirectory
{
	return [displayedValues objectForKey:MAC_ISOBinariesDirectory];
}

- (BOOL)prefsCreateGroupSubdirs
{
	return [[displayedValues objectForKey:MAC_ISOCreateGroupSubdirs] boolValue];
}

- (BOOL)prefsCreateDateSubdirs
{
	return [[displayedValues objectForKey:MAC_ISOCreateDateSubdirs] boolValue];
}

- (BOOL)prefsExtractFileTypesOnly
{
	return [[displayedValues objectForKey:MAC_ISOExtractBinariesWithExtensions] boolValue];
}

- (NSString *)prefsExtractionFileTypes
{
	return [displayedValues objectForKey:MAC_ISOExtractBinariesWithExtensionsText];
}

- (BOOL)prefsDontExtractMultipart
{
	return [[displayedValues objectForKey:MAC_ISODontExtractMultipartBinaries] boolValue];
}

- (BOOL)prefsMakeFilenamesUnique
{
	return [[displayedValues objectForKey:MAC_ISOExtractBinariesMakeFilenamesUnique] boolValue];
}

- (NSArray *)prefsAdditionalHeaders
{
	return additionalHeaders;
}

- (BOOL)prefsReloadParentPosting
{
	return [[displayedValues objectForKey:MAC_ISOReloadParentPosting] boolValue];
}

- (BOOL)doNotAutomaticallySendUserAgentHeader
{
	return [[displayedValues objectForKey:MAC_ISONoAutomaticUserAgentHeader] boolValue];
}

- (BOOL)noCatchUpWarnings
{
	return [[displayedValues objectForKey:MAC_ISONoCatchUpWarnings] boolValue];
}

- (BOOL)noMarkSubscriptionWarnings
{
	return [[displayedValues objectForKey:MAC_ISONoMarkSubscriptionWarnings] boolValue];
}

/* sound delegate */
- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
	if (aBool) {
		[sound release];
	}
}


- (BOOL)prefsCheckSpellingWhileTyping
{
	return [[displayedValues objectForKey:MAC_ISOCheckSpellingWhileTyping] boolValue];
}


/* ADDITIONAL HEADER STUFF */
- (void)headerEntryFieldsChanged:(NSNotification *)aNotification
{
	NSRange	aRange;
	int	selectedRow = [headerTable selectedRow];

	aRange = [[headerField stringValue] rangeOfString:@":"];
	[addHeaderButton setEnabled:((aRange.length == 1) && ([[valueField stringValue] length]>0))];
	if ((selectedRow >=0) && (selectedRow < [additionalHeaders count])) {
		[changeHeaderButton setEnabled:(aRange.length == 1) && [[valueField stringValue] length]];
	}
}

- (void)_emptyHeaderControls
{
	[headerField setStringValue:@""];
	[valueField setStringValue:@""];
	[changeHeaderButton setEnabled:NO];
	[deleteHeaderButton setEnabled:NO];
	[addHeaderButton setEnabled:NO];
}

- (void)additionalHeaders:(id)sender
{
	[[NSApplication sharedApplication] beginSheet:additionalHeadersPanel 
			modalForWindow:window
			modalDelegate:nil
			didEndSelector:nil
			contextInfo:nil];
	[headerTable reloadData];
	[self _emptyHeaderControls];
}

- (void)headerTableClicked:(id)sender
{
	int	selectedRow = [headerTable selectedRow];
	if ((selectedRow >=0) && (selectedRow < [additionalHeaders count])) {
		[deleteHeaderButton setEnabled:YES];
		[changeHeaderButton setEnabled:YES];
		[addHeaderButton setEnabled:YES];
		[headerField setStringValue:[[additionalHeaders objectAtIndex:selectedRow] objectAtIndex:0]];
		[valueField setStringValue:[[additionalHeaders objectAtIndex:selectedRow] objectAtIndex:1]];
	} else {
		[changeHeaderButton setEnabled:NO];
		[deleteHeaderButton setEnabled:NO];
	}
}

- (void)addHeader:(id)sender
{
	NSArray	*anArray = [NSMutableArray arrayWithObjects:[headerField stringValue],
									[valueField stringValue], nil];
	
	[additionalHeaders addObject:anArray];
	[headerTable reloadData];
	[self _emptyHeaderControls];
}

- (void)deleteHeader:(id)sender
{
	int	selectedRow = [headerTable selectedRow];
	if ((selectedRow >=0) && (selectedRow < [additionalHeaders count])) {
		[additionalHeaders removeObjectAtIndex:selectedRow];
		[headerTable reloadData];
		[self _emptyHeaderControls];
	} else {
		[ISOBeep beep:@"Please first select a header to delete..."];
	}
}

- (void)changeHeader:(id)sender
{
	int	selectedRow = [headerTable selectedRow];
	if ((selectedRow >=0) && (selectedRow < [additionalHeaders count])) {
		NSArray	*anArray = [NSMutableArray arrayWithObjects:[headerField stringValue],
									[valueField stringValue], nil];
		[additionalHeaders replaceObjectAtIndex:selectedRow withObject:anArray];
		[headerTable reloadData];
		[self _emptyHeaderControls];
	} else {
		[ISOBeep beep:@"Please first select a header to change..."];
	}
}

- (void)finishedEditingHeaders:sender
{
	[additionalHeadersPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:additionalHeadersPanel];
}


/* NEW TOOLBAR BASED PREFERENCES */
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:@"GeneralPrefs", @"ServersPrefs", @"SubscriptionPrefs", 
						@"BatchOfflinePrefs", @"ReadingPrefs", @"PostingPrefs", @"SPAMPrefs",
						NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:@"GeneralPrefs", NSToolbarSeparatorItemIdentifier, 
						@"ServersPrefs", @"SubscriptionPrefs", @"BatchOfflinePrefs", 
						@"SPAMPrefs", @"ReadingPrefs", @"PostingPrefs", nil];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    NSToolbarItem	*toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
	
    if ([itemIdent isEqual: @"GeneralPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Accounts", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Accounts", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"GeneralPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectGeneralPrefs:)];
    } else if ([itemIdent isEqual: @"ServersPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Server", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Server", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"ServerPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectServerPrefs:)];
    } else if ([itemIdent isEqual: @"SubscriptionPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Subscriptions", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Subscriptions", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"SubscriptionPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectSubscriptionPrefs:)];
    } else if ([itemIdent isEqual: @"BatchOfflinePrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Batch/Offline", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Batch/Offline", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"BatchOfflinePrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectBatchOfflinePrefs:)];
    } else if ([itemIdent isEqual: @"ReadingPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Reading", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Reading", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"ReadingPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectReadingPrefs:)];
    } else if ([itemIdent isEqual: @"PostingPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"Posting", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"Posting", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"PostingPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectPostingPrefs:)];
    } else if ([itemIdent isEqual: @"SPAMPrefs"]) {
		[toolbarItem setLabel: NSLocalizedString(@"SPAM Filters", @"")];
		[toolbarItem setPaletteLabel: NSLocalizedString(@"SPAM Filters", @"")];
		[toolbarItem setImage: [NSImage imageNamed: @"SPAMPrefs"]];
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(selectSPAMPrefs:)];
	}
	return toolbarItem;
}

- (void) toolbarWillAddItem: (NSNotification *) notif
{
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif
{
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem
{
	return YES;
}

/* Pref Panes Switching */
- (void) _resizeWindowForContentView:(NSView *) view
{
	NSRect			windowFrame, newWindowFrame;
	unsigned int	newWindowHeight;

	windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
	newWindowHeight = NSHeight([view frame]);
	
	[((NSWindow *)window) setContentView:[[[NSView alloc] initWithFrame:NSMakeRect(0,0,windowFrame.size.width, 100)] autorelease]];
	if ([[window toolbar] isVisible]) {
		newWindowHeight += NSHeight([[[window toolbar] _toolbarView] frame]);
	}
	newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect(NSMinX(windowFrame), NSMaxY(windowFrame) - newWindowHeight, NSWidth(windowFrame), newWindowHeight) styleMask:[window styleMask]];
	[window setFrame:newWindowFrame display:YES animate:[window isVisible]];
}

- (void)_setNewPrefView:(id)aView
{
	id oldView = [window contentView];
	if (oldView != aView) {
		[oldView retain];
//		[[backupWindow contentView] addSubview:oldView];
		[self _resizeWindowForContentView:aView];
		if ([aView superview]) {
			[aView removeFromSuperview];
		}
		[((NSWindow *)window) setContentView:aView];
	}
}

- (void)selectGeneralPrefs:sender
{
	[self _setNewPrefView:generalPrefsView];
}

- (void)selectServerPrefs:sender
{
	[self _setNewPrefView:serverPrefsView];
}

- (void)selectSubscriptionPrefs:sender
{
	[self _setNewPrefView:subscriptionPrefsView];
}

- (void)selectBatchOfflinePrefs:sender
{
	[self _setNewPrefView:batchOfflinePrefsView];
}

- (void)selectReadingPrefs:sender
{
	[self _setNewPrefView:readingPrefsView];
}

- (void)selectPostingPrefs:sender
{
	[self _setNewPrefView:postingPrefsview];
}

- (void)selectSPAMPrefs:sender
{
	[self _setNewPrefView:spamPrefsview];
}

- (NSString *)genericPrefForKey:(NSString *)aKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:aKey]) {
		return [defaults objectForKey:aKey];
	} else {
		return @"";
	}
}

- (void)setGenericPref:(NSString *)aValue forKey:(NSString *)aKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:aValue forKey:aKey];
	[defaults synchronize];
}

@end
