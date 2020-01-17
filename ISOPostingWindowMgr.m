//
//  ISOPostingWindowMgr.m
//  Halime
//
//  Created by Imdat Solak on Mon Dec 24 2001.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOPostingWindowMgr.h"
#import "ISOPreferences.h"
#import "ISOSentPostingsMgr.h"
#import "ISOResourceMgr.h"
#import "ISOBeep.h"
#import "ISONewsServerMgr.h"
#import "ISOSMTPClient.h"
#import "ISOOutPostingMgr.h"
#import "ISOIdentityMgr.h"
#import "NSString_Extensions.h"
#import "NSTextView_Extensions.h"
#import "NSPopUpButton_Extensions.h"
#import "uudeview.h"
#import "ISOLogger.h"
#import "EncodingPopupMaker.h"
#import "version.h"
#import "Functions.h"

#define K_V_MESSAGEID	@"<article>"
#define K_V_USER		@"<user>"
#define K_V_DATE		@"<date>"
#define K_V_SUBJECT		@"<subject>"

#define K_SIGDELIMITER 	@"\n-- \n"
#define K_ALT_SIGDELIMITER @"\n-- \r\n"


#define MAC_ISOHalimeSentDocToolbarIdentifier	@"ISOHalimeSentDocToolbarIdentifier"
#define MAC_SENDPOSTING		@"SendPosting"
#define MAC_FORGETIT		@"ForgetIt"
#define MAC_LOADDRAFT		@"LoadDraft"
#define MAC_SAVEDRAFT		@"SaveDraft"
#define MAC_ADDATTACHMENT	@"AddAttachment"
#define MAC_RECOLORIZE		@"ReColorize"
#define MAC_ENCODING		@"CharacterEncoding"
#define MAC_ADDITIONALHEADERS	@"AdditionalHeaders"

@implementation ISOPostingWindowMgr

- init
{
	[super init];
	storedReferences = nil;
	storedMessageID = nil;
	deferredPosting = nil;
	attachments = [[NSMutableArray array] retain];
	additionalHeaders = [NSMutableArray arrayWithArray:[[ISOPreferences sharedInstance] prefsAdditionalHeaders]];
	[additionalHeaders retain];
	theSelection = nil;
	isFollowUp = NO;
	isReplyTo = NO;
	return self;
}

- initFromDeferredPosting:(ISONewsPosting *)oldPosting
{
	[self init];
	originalPosting = nil;
	theGroup = nil;
	deferredPosting = oldPosting;
	[deferredPosting retain];
	if ([deferredPosting referencesHeader]) {
		isFollowUp = YES;
	}
	return self;
}

- initNewPostingInGroup:(ISONewsGroup *)aGroup
{
	[self init];
	originalPosting = nil;
	theGroup = aGroup;
	return self;
}


- initFollowUpTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup selectionText:(NSString *)selectionText
{
	[self init];
	originalPosting = aPosting;
	theGroup = aGroup;
	if ([aPosting followUpHeader] && [[aPosting followUpHeader] length] &&	[[aPosting followUpHeader] caseInsensitiveCompare:@"poster"] == NSOrderedSame) {
		isReplyTo = YES;
		NSRunAlertPanel(NSLocalizedString(@"Reply-To instead of FollowUp", @""),
			NSLocalizedString(@"The sender of the posting you want to follow-up requested that follow-ups should be sent as mail to him (Follow-Up: poster). Therefore, this follow-up is being created as a Reply via Email.", @""),
			NSLocalizedString(@"OK", @""),
			nil,
			nil);
	} else {
		isFollowUp = YES;
	}
	if (selectionText) {
		theSelection = [[NSString stringWithString:selectionText] retain];
	}
	return self;
}

- initFollowUpTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup
{
	return [self initFollowUpTo:aPosting inGroup:aGroup selectionText:nil];
}

- initReplyTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup selectionText:(NSString *)selectionText
{
	[self init];
	isReplyTo = YES;
	originalPosting = aPosting;
	theGroup = aGroup;
	if (selectionText) {
		theSelection = [[NSString stringWithString:selectionText] retain];
	}
	return self;
}

- initReplyTo:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup
{
	return [self initReplyTo:aPosting inGroup:aGroup selectionText:nil];
}

- (void)dealloc
{
	[deferredPosting release];
	deferredPosting = nil;
	[storedMessageID release];
	storedMessageID = nil;
	[storedReferences release];
	storedReferences = nil;
	[attachments release];
	attachments = nil;
	[attachmentsTable setDataSource:nil];
	[((NSTableView *)attachmentsTable) setDelegate:nil];
	[attachmentsTable setTarget:nil];
	[additionalHeaders release];
	[theSelection release];
	[encodingPopup release];
	[super dealloc];
}

- (void)_replaceVariable:(NSString *)var withValue:(NSString *)value inString:(NSMutableString *)aString
{
	NSRange	aRange = [aString rangeOfString:var];
	if (aRange.length == [var length]) {
		[aString replaceCharactersInRange:aRange withString:value];
	}
}

- (NSString *)_followUpBanner
{
	NSMutableString	*followUpBanner;
	
	if ([[ISOPreferences sharedInstance] prefsFollowUpBanner]) {
		followUpBanner = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsFollowUpBanner]];
	} else {
		followUpBanner = [NSMutableString stringWithString:@"In <article> <user> wrote:"];
	}
	
	[self _replaceVariable:K_V_MESSAGEID withValue:[originalPosting messageIDHeader] inString:followUpBanner];
	[self _replaceVariable:K_V_USER withValue:ISONameOnlyFromSenderString([originalPosting decodedSender]) inString:followUpBanner];
	[self _replaceVariable:K_V_DATE withValue:ISOCreateDisplayableDateFromDateHeader([originalPosting dateHeader], NO, NO)  inString:followUpBanner];
	[self _replaceVariable:K_V_SUBJECT withValue:[originalPosting decodedSubject] inString:followUpBanner];
	return followUpBanner;
}

- (void)updateIdentities
{
	int	i, count;
	ISOIdentityMgr	*theIDMgr = [ISOIdentityMgr sharedIdentityMgr];
	
	count = [theIDMgr identityCount];
	for (i=0;i<count;i++) {
		if ([theIDMgr idNameOfIdentityAtIndex:i]) {
			[identityPopup addItemWithTitle:[theIDMgr idNameOfIdentityAtIndex:i]];
		} else {
			[identityPopup addItemWithTitle:[theIDMgr nameOfIdentityAtIndex:i]];
		}
	}
	[identityPopup setAutoenablesItems:YES];
}

- (void)setupEncodings
{
}

- (void)showWindow
{
	unsigned int textLength;
	
	storedReferences = nil;
	storedMessageID = nil;
	if (!window) {
        if (![NSBundle loadNibNamed:@"ISOPostingComposer" owner:self])  {
            [ISOBeep beep:@"Could not load ISOPostingComposer.nib" withDescription:@"Somehow, I could not load the UI-Files for composing postings. Please check all permissions..."];
			return ;
		}
	}
	[encodingPopup retain];
	// Check for "Followup-To: poster"
	[self updateIdentities];
	[self setupEncodings];
	[self setupToolbar];
	[newsgroupsField setStringValue:@""];
	if (theGroup || deferredPosting) {
		if (isReplyTo) {
			[newsgroupsPopup selectItemWithTag:1];
		} else {
			[newsgroupsPopup selectItemWithTag:0];
		}
		[self newsgroupsPopupClicked:self];
/*
		if (originalPosting) {
			if (isFollowUp && [originalPosting followUpHeader]) {
				[newsgroupsField setStringValue:[originalPosting followUpHeader]];
			} else if (isReplyTo) {
				if ([originalPosting replyToHeader]) {
					[newsgroupsField setStringValue:[originalPosting replyToHeader]];
				} else {
					[newsgroupsField setStringValue:[originalPosting fromHeader]];
				}
				[newsgroupsPopup selectItemWithTag:1];
				[self newsgroupsPopupClicked:self];
			} else {
				[newsgroupsField setStringValue:[originalPosting newsgroupsHeader]];
			}
		} else if (deferredPosting) {
			[newsgroupsField setStringValue:[deferredPosting newsgroupsHeader]];
		} else {
			[newsgroupsField setStringValue:[theGroup groupName]];
		}
*/
	}
	if (isFollowUp || deferredPosting || isReplyTo) {
		NSMutableString *aString = [NSMutableString string];
		
		if (originalPosting) {
			if (![[originalPosting decodedSubject] hasPrefix:@"Re:"] && ![[originalPosting decodedSubject] hasPrefix:@"RE:"] && ![[originalPosting decodedSubject] hasPrefix:@"re:"] ) {
				[aString appendString:@"Re: "];
			}
			if ([originalPosting decodedSubject]) {
				[aString appendString:[originalPosting decodedSubject]];
			}
		} else if (deferredPosting) {
			[aString setString:[deferredPosting decodedSubject]];
		}
		[subjectField setStringValue:aString];
		if (originalPosting && [originalPosting bodyAsText]) {
			NSMutableString *quoteString;
			int				wrapLength;
			NSRange			sigRange;
			BOOL			noSig = YES;
			NSMutableString	*origT;
			NSString 		*tempStr;
			
			aString = [NSMutableString stringWithString:[self _followUpBanner]];
			[aString appendString:@"\n"];
			if (theSelection) {
				origT = [NSMutableString stringWithString:theSelection];
			} else {
				origT = [NSMutableString stringWithString:[originalPosting decodedBody]];
			}
			wrapLength = MAX([[ISOPreferences sharedInstance] prefsWrapTextLength], 72);
			sigRange = [origT rangeOfString:K_SIGDELIMITER];
			if (sigRange.length != [K_SIGDELIMITER length]) {
				sigRange = [origT rangeOfString:K_ALT_SIGDELIMITER];
				if (sigRange.length != [K_ALT_SIGDELIMITER length]) {
					noSig = YES;
				} else {
					noSig = NO;
				}
			} else {
				noSig = NO;
			}
			if (!noSig) {
				sigRange.length = [origT length] - sigRange.location;
				[origT replaceCharactersInRange:sigRange withString:@""];
			}
			quoteString = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsQuoteString]];
			tempStr = [origT wrappedStringWithLineLength:wrapLength andQuotedWithQuoteString:quoteString];
			[aString appendString:tempStr];
			[textView setString:aString];
			
		} else if (deferredPosting) {
			[textView setString:[deferredPosting decodedBody] ];
		} else {
			[textView setString:@""];
		}
		if (originalPosting) {
			aString = [NSMutableString stringWithString:[originalPosting decodedSubject]];
		} else if (deferredPosting) {
			aString = [NSMutableString stringWithString:[deferredPosting decodedSubject]];
		}
		if (isFollowUp) {
			[aString appendFormat:@" %@", NSLocalizedString(@"(FollowUp)", @"")];
		} else if (isReplyTo) {
			[aString appendFormat:@" %@", NSLocalizedString(@"(Reply via Email)", @"")];
		}
		[window setTitle:aString];
		if (originalPosting) {
			if ([originalPosting referencesHeader]) {
				storedReferences = [NSString stringWithString:[originalPosting referencesHeader]];
				[storedReferences retain];
			}
			storedMessageID = [NSString stringWithString:[originalPosting messageIDHeader]];
			[storedMessageID retain];
		} else if (deferredPosting) {
			if ([deferredPosting referencesHeader]) {
				storedReferences = [NSString stringWithString:[deferredPosting referencesHeader]];
				[storedReferences retain];
			}
			storedMessageID = nil;
		}
		if (deferredPosting) {
			if ([deferredPosting followUpHeader]) {
				[followUpField setStringValue:[deferredPosting followUpHeader]];
			} else {
				[followUpField setStringValue:@""];
			}
			if ([deferredPosting replyToHeader]) {
				[replyToField setStringValue:[deferredPosting replyToHeader]];
			} else {
				[replyToField setStringValue:@""];
			}
		}
	} else {
		storedReferences = nil;
		storedMessageID = nil;
		[window setTitle:NSLocalizedString(@"New posting", @"")];
		[newsgroupsPopup setEnabled:NO];
	}
	[rewrapBeforeSendingSwitch setState:[[ISOPreferences sharedInstance] prefsWrapText]? 1:0];
	textLength = [[textView string] length];
	[self identityChanged:self];
//	[textView colorizeRange:NSMakeRange(0, [[textView string] length])];
	[textView setFont:[[ISOPreferences sharedInstance] prefsEditorFont]];
	[textView setContinuousSpellCheckingEnabled:[[ISOPreferences sharedInstance] prefsCheckSpellingWhileTyping]];
	[window setDocumentEdited:NO];
	[window makeKeyAndOrderFront:self];
	[textView setSelectedRange:NSMakeRange(textLength, 0)];
	[window makeFirstResponder:textView];
}

- (void)_setIdentity:(NSString *)userName :(NSString *)eMail :(NSString *)signature
{
	NSMutableString *userData = [NSMutableString stringWithString:userName];
	NSRange			sigRange;
	NSString		*sigString;
	
	[userData appendString:@" <"];
	[userData appendString:eMail];
	[userData appendString:@">"];
	[fromField setStringValue:userData];
	sigRange = [[textView string] rangeOfString:K_SIGDELIMITER];
	if (sigRange.length == [K_SIGDELIMITER length]) {
		sigRange.length = [[textView string] length] - sigRange.location;
	} else {
		sigRange.location = [[textView string] length];
		sigRange.length = 0;
	}
	if ((signature != nil) && ([signature length])) {
		sigString = [NSString stringWithFormat:@"%@%@", K_SIGDELIMITER, signature];
		[textView replaceCharactersInRange:sigRange withString:sigString];
	}
}

- (void)identityChanged:sender
{
	int idNo = [identityPopup indexOfSelectedItem]-1;
	NSString	*email;
	NSString	*name;
	NSString	*signature;
	
	if (idNo == -1) {
		idNo = [[ISOIdentityMgr sharedIdentityMgr] defaultIdentityIndex];
	}
	if (idNo >= 0) {
		email = [[ISOIdentityMgr sharedIdentityMgr] emailOfIdentityAtIndex:idNo];
		name = [[ISOIdentityMgr sharedIdentityMgr] nameOfIdentityAtIndex:idNo];
		signature = [[ISOIdentityMgr sharedIdentityMgr] signatureOfIdentityAtIndex:idNo];
		if (!email || ([email compare:@""] == NSOrderedSame)) {
			email = [[ISOPreferences sharedInstance] prefsUserEmail];
			name = [[ISOPreferences sharedInstance] prefsUserName];
			signature = nil;
		}
		[self _setIdentity:name :email :signature];
 	} else {
		email = [[ISOPreferences sharedInstance] prefsUserEmail];
		name = [[ISOPreferences sharedInstance] prefsUserName];
		signature = nil;
		[self _setIdentity:name :email :signature];
	}
	[window setDocumentEdited:YES];
}

- (void)_finishAddAttachmentSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)con
{
	[sheet orderOut:self];
	if (returnCode == NSFileHandlingPanelOKButton) {
		NSArray	*filenames = [((NSOpenPanel *)sheet) filenames];
		int		i, count;

		count = [filenames count];
		for (i=0;i<count;i++) {
			NSString *fileName = [filenames objectAtIndex:i];
			
			[attachments addObject:fileName];
			[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISOAttachmentLoadDirectory"];
		}
		[window setDocumentEdited:YES];
		[attachmentsTable reloadData];
		[self attachmentTableClicked:self];
	}
}

- (void)addAttachmentButtonClicked:sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	NSMutableArray	*anArray = [NSMutableArray arrayWithCapacity:1];
	
	[openPanel setTitle:NSLocalizedString(@"Add Attachment", @"")];
	[anArray addObject:@""];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISOAttachmentLoadDirectory"]
				file:@""
				modalForWindow:window
				modalDelegate:self
				didEndSelector:@selector(_finishAddAttachmentSheet:returnCode:contextInfo:)
				contextInfo:nil];
	[window setDocumentEdited:YES];
}

- (void)removeAttachmentButtonClicked:sender
{
	int selectedRow = [attachmentsTable selectedRow];
	if (selectedRow >=0 && (selectedRow < [attachments count])) {
		[attachments removeObjectAtIndex:selectedRow];
		[attachmentsTable reloadData];
		[window setDocumentEdited:YES];
		[self attachmentTableClicked:self];
	}
}


- (void)sendClicked:sender
{
	BOOL			errorOccured = NO;
	NSMutableString	*message = [NSMutableString stringWithString:NSLocalizedString(@"Your message cannot be posted due to the following reason(s):", @"")];
	
	if ([[fromField stringValue] length] == 0) {
		[message appendString:@"\n¥ "];
		[message appendString:NSLocalizedString(@"The Sender/From field is empty.", @"")];
		errorOccured = YES;
	}
	if ([[subjectField stringValue] length] == 0) {
		[message appendString:@"\n¥ "];
		[message appendString:NSLocalizedString(@"The Subject field is empty.", @"")];
		errorOccured = YES;
	}
	if ([[newsgroupsField stringValue] length] == 0) {
		[message appendString:@"\n¥ "];
		[message appendString:NSLocalizedString(@"The Newsgroups field is empty. Where -do you think- should I post the posting to?", @"")];
		errorOccured = YES;
	}
	if ([[textView string] length] == 0) {
		[message appendString:@"\n¥ "];
		[message appendString:NSLocalizedString(@"The message body is empty. You should write at least one or two sentences...", @"")];
		errorOccured = YES;
	}
	if (errorOccured) {
		 NSRunAlertPanel(NSLocalizedString(@"Cannot post message", @""),
			message,
			NSLocalizedString(@"Let me correct it", @""),
			nil,
			nil
		);
	} else {
		[self _sendPosting];
	}
}

- (void)cancelClicked:sender
{
	if ([self windowShouldClose:window]) {
		[window orderOut:self];
	}
}


- (void)reallySavePosting:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)con
{
	NSString		*fileName;
	NSDictionary	*valueDict;
	
	[sheet orderOut:self];
	if (returnCode == NSFileHandlingPanelOKButton) {
		fileName = [((NSSavePanel *)sheet) filename];
		
		[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISODraftsDirectory"];
		valueDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[subjectField stringValue], @"SUBJECT",
						[newsgroupsField stringValue], @"NEWSGROUPS",
						[fromField stringValue], @"FROM",
						[replyToField stringValue], @"REPLYTO",
						[followUpField stringValue], @"FOLLOWUPTO", 
						[textView string], @"BODY",
						(storedReferences)? storedReferences:@"", @"REFERENCES",
						(storedMessageID)? storedMessageID:@"", @"ORIGINALPOSTINGID",
						[NSNumber numberWithBool:isFollowUp], @"ISFOLLOWUP",
						[NSNumber numberWithBool:isReplyTo], @"ISREPLYTO",
						nil];
		if (![valueDict writeToFile:fileName atomically:NO]) {
			NSRunAlertPanel(NSLocalizedString(@"Could not Save Posting", @""),
				NSLocalizedString(@"The posting could not be saved. Please try again later.", @""),
				NSLocalizedString(@"OK", @""),
				nil,
				nil);
		} else {
			[window setDocumentEdited:NO];
		}
	}
}


- (void)saveClicked:sender
{
	NSSavePanel			 *savePanel;
	
	savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:NSLocalizedString(@"Save Posting", @"")];
	[savePanel setRequiredFileType:@"hdrft"];
	[savePanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISODraftsDirectory"]
				file:@""
				modalForWindow:window
				modalDelegate:self
				didEndSelector:@selector(reallySavePosting:returnCode:contextInfo:)
				contextInfo:nil];
}

- (void)reallyLoadPosting:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)con
{
	NSString		*fileName;
	NSDictionary	*valueDict;
	
	[sheet orderOut:self];
	if (returnCode == NSFileHandlingPanelOKButton) {
		fileName = [[((NSOpenPanel *)sheet) filenames] objectAtIndex:0];
		[[ISOPreferences sharedInstance] setGenericPref:[fileName stringByDeletingLastPathComponent] forKey:@"ISODraftsDirectory"];
		valueDict = [NSDictionary dictionaryWithContentsOfFile:fileName];
		if (valueDict) {
			[subjectField setStringValue:[valueDict objectForKey:@"SUBJECT"]];
			[newsgroupsField setStringValue:[valueDict objectForKey:@"NEWSGROUPS"]];
			[fromField setStringValue:[valueDict objectForKey:@"FROM"]];
			[replyToField setStringValue:[valueDict objectForKey:@"REPLYTO"]];
			[followUpField setStringValue:[valueDict objectForKey:@"FOLLOWUPTO"]];
			isFollowUp = [[valueDict objectForKey:@"ISFOLLOWUP"] boolValue];
			if ([valueDict objectForKey:@"ISREPLYTO"]) {
				isReplyTo = [[valueDict objectForKey:@"ISREPLYTO"] boolValue];
			} else {
				isReplyTo = NO;
			}
			[textView setString:[valueDict objectForKey:@"BODY"]];
			storedReferences = [[valueDict objectForKey:@"REFERENCES"] retain];
			storedMessageID = [[valueDict objectForKey:@"ORIGINALPOSTINGID"] retain];
		} else {
			NSBeep();
		}
	}
}

- (void)loadClicked:sender
{
	NSOpenPanel		*openPanel = [NSOpenPanel openPanel];
	NSMutableArray	*anArray = [NSMutableArray arrayWithCapacity:1];
	
	[openPanel setTitle:NSLocalizedString(@"Open a Draft", @"")];
	[anArray addObject:@"hdrft"];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel beginSheetForDirectory:[[ISOPreferences sharedInstance] genericPrefForKey:@"ISODraftsDirectory"]
				file:@""
				types:anArray
				modalForWindow:window
				modalDelegate:self
				didEndSelector:@selector(reallyLoadPosting:returnCode:contextInfo:)
				contextInfo:nil];
}

- (BOOL)windowShouldClose:(id)sender
{
	if ([window isDocumentEdited]) {
		int choice = NSAlertDefaultReturn;
		
		choice = NSRunAlertPanel(NSLocalizedString(@"Discard Posting", @"Title of alert panel which comes up when user wants to close the compose window without sending the content."), 
		NSLocalizedString(@"The posting you edited will be lost. Are you sure you want to discard your composition/posting?", @"Message in the alert panel which shows the question."), 
		NSLocalizedString(@"Don't Discard", @"Choice (on a button) given to user which allows him/her to keep editing."), 
		nil,
		NSLocalizedString(@"Discard", @"Choice for really cancelling the posting."));
		if (choice == NSAlertDefaultReturn) {
			return NO;
		}
	}
	[((NSWindow *)window) setDelegate:nil];
	[self dealloc];
	return YES;
}

- (void)textDidChange:(NSNotification *)aNotification
{
	[window setDocumentEdited:YES];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
	if (([aNotification object] == headerField) || ([aNotification object] == valueField)) {
		[self headerEntryFieldsChanged:aNotification];
	}
	[window setDocumentEdited:YES];
}

/* ************** */
- (void)_appendHeader:(NSString *)header withValue:(NSString *)value toMessage:(NSMutableString *)theMessage
{
	if (value) {
		[theMessage appendString:header];
		[theMessage appendString:value];
		[theMessage appendString:@"\r\n"];
	}
}

- (NSString *)_hostname
{
	return [[NSHost currentHost] name];
}

- (NSString *)_createMessageID:(ISONewsServerMgr *)theMgr
{
	NSMutableString *aString = [NSMutableString stringWithString:@""];
	NSMutableString	*hostname = [NSMutableString stringWithString:[[theMgr newsServer] FQDN]];
	NSString *nntpServer = [[theMgr newsServer] serverName];
	NSRange	aRange;
	
	aRange = [hostname rangeOfString:@"."];
	if (aRange.length != 1) {
//		[hostname setString:[self _hostname]];
		[hostname setString:nntpServer];
		aRange = [hostname rangeOfString:@"."];
		if (aRange.length != 1) {
			[hostname setString:nntpServer];
			aRange = [hostname rangeOfString:@"."];
			if (aRange.length != 1) {
				[hostname appendString:@".local"];
			}
		}
	}
	[aString appendString:@"<"];
	[aString appendString:[[NSDate date] descriptionWithCalendarFormat:@"%Y%m%d%H%M%S%F%z" timeZone:nil locale:nil]];
	[aString appendString:@"@"];
	[aString appendString:hostname];
	[aString appendString:@">"];
	return aString;
}

- (NSString *)stringConvertedWithRespectToEncoding:(NSString *)aString putEncodingInto:(NSMutableString *)encString cte:(NSMutableString *)cteString senc:(int *)stringEncoding doWrap:(BOOL)wrapFlag
{
	int wrapLength;
	
	*stringEncoding = [[encodingPopup selectedItem] tag];
	[cteString setString:@"7bit"];
	[encString setString:@"US-ASCII"];
	if (CFStringConvertEncodingToIANACharSetName(*stringEncoding)) {
		[encString setString:(NSString *)CFStringConvertEncodingToIANACharSetName(*stringEncoding)];
	} else {
		// Tja, was nun???
		[encString setString:@""];
	}
	
	[cteString setString:ISOBitsForCFStringEncoding(*stringEncoding)];

	wrapLength = MAX([[ISOPreferences sharedInstance] prefsWrapTextLength], 72);
	if (wrapFlag) {
		aString = [aString wrappedStringWithLineLength:wrapLength andQuotedWithQuoteString:nil];
	}
	return aString;
}


- (void)_appendMessageBodyTo:(NSMutableString *)theMessage putEncodingInto:(NSMutableString *)encString cte:(NSMutableString *)cteString senc:(int *)stringEncoding
{
	NSString	*body = [textView string];

	body = [self stringConvertedWithRespectToEncoding:body putEncodingInto:encString cte:cteString senc:stringEncoding doWrap:([rewrapBeforeSendingSwitch state]==1)];
	[theMessage appendString:body];
}

#define K_ENCF	"/private/tmp/halime.enc.out"

- (BOOL)_appendAttachmentsToBody:(NSMutableString *)theMessage numberOfParts:(int *)numParts
{
	int		i, count;
	BOOL	errorOccured = NO;

	count = [attachments count];
	if (count) {
		[encMsgWindow makeKeyAndOrderFront:self];
		[encMsgWindow center];
		[encMsgWindow display];
		for (i=0;i<count;i++) {
			NSString		*thisAtt = [attachments objectAtIndex:i];
			NSMutableString	*savePath = [NSMutableString stringWithString:@"/private/tmp/"];
			FILE			*outfp;
			int				flen;
			char			*buffer;
			int				ret;
			
			[savePath appendString:[thisAtt lastPathComponent]];
			[savePath appendString:@".uue"];

			UUInitialize();

			[encAttNameField setStringValue:[thisAtt lastPathComponent]];
			[encAttNameField display];
			[encAttLeftField setIntValue:count-i];
			[encAttLeftField display];
			outfp = fopen([savePath cString], "w+");
			ret = UUEncodeToStream (outfp, NULL, [thisAtt cString], UU_ENCODED, [[thisAtt lastPathComponent] cString], 0644);
			if (ret == UURET_OK) {
				fseek(outfp, 0, SEEK_END);
				flen = ftell(outfp);
				fseek(outfp, 0, SEEK_SET);
				buffer = malloc(flen+1);
				bzero(buffer, flen+1);
				fread(buffer, flen, 1, outfp);
				fclose(outfp);
				[theMessage appendFormat:@"\r\n%s", buffer];
				free(buffer);
				
			} else {
				errorOccured = YES;
			}
			fclose(outfp);
			UUCleanUp();
//			[ISOResourceMgr removePath:savePath];
		}
		[encMsgWindow orderOut:self];
	}
	return !errorOccured;
}

- (void)_appendXFaceHeaderToMessage:(NSMutableString *)message
{
	int idNo = [identityPopup indexOfSelectedItem]-1;

	if (idNo == -1) {
		idNo = [[ISOIdentityMgr sharedIdentityMgr] defaultIdentityIndex];
	}
	if (idNo >= 0) {
		NSString *xFace = [[ISOIdentityMgr sharedIdentityMgr] xFaceOfIdentityAtIndex:idNo];
		NSMutableString	*xFStr = [NSMutableString string];
		
		if (xFace && [xFace length]) {
			int	startPos = 0;
			int length = 70;
			
			length = MIN(70, [xFace length]);
			while (startPos < [xFace length]) {
				NSString	*aStr = [xFace substringWithRange:NSMakeRange(startPos, length)];
				if (aStr) {
					if ([xFStr length]) {
						[xFStr appendString:@"\r\n\t"];
					}
					[xFStr appendString:aStr];
				}
				startPos += length;
				length = MIN(70, [xFace length] - startPos);
			}
		}
		if ([xFStr length]) {
			[self _appendHeader:@"X-Face: " withValue:xFStr toMessage:message];
		}
 	}
}

- (void)_appendXFaceURLHeaderTomessage:(NSMutableString *)message
{
	int idNo = [identityPopup indexOfSelectedItem]-1;

	if (idNo == -1) {
		idNo = [[ISOIdentityMgr sharedIdentityMgr] defaultIdentityIndex];
	}
	if (idNo >= 0) {
		NSString *xFaceURL = [[ISOIdentityMgr sharedIdentityMgr] xFaceURLOfIdentityAtIndex:idNo];
		if (xFaceURL && [xFaceURL length]) {
			[self _appendHeader:@"X-FaceURL: " withValue:xFaceURL toMessage:message];
		}
 	}
}

- (void)_appendAdditionalHeadersToMessage:(NSMutableString *)message
{
	int	i, count;
	count = [additionalHeaders count];
	
	for (i=0;i<count;i++) {
		[self _appendHeader:[NSString stringWithFormat:@"%@ ", [[additionalHeaders objectAtIndex:i] objectAtIndex:0]]
				withValue:[[additionalHeaders objectAtIndex:i] objectAtIndex:1]
				toMessage:message];
	}
	[self _appendXFaceHeaderToMessage:message];
	[self _appendXFaceURLHeaderTomessage:message];
}

- (void)_sendPosting
{
	ISONewsServerMgr	*theMgr = nil;
	NSMutableString		*enc, *cte, *aBody;
	NSMutableString		*theMessage = [NSMutableString string];
	NSMutableString		*errorMsg = [NSMutableString string];
	NSString			*fromString, *replyToString, *subjectString;
	NSString			*messageID;
	int					stringEncoding;
	BOOL				putIntoDeferred;
	int					numParts;
	ISONewsPosting		*thisPosting;
	BOOL				alwaysPost = ([[newsgroupsPopup selectedItem] tag] != 1);
	BOOL				sentSuccessfully = NO;
	
	/* Now, lets first create the header */
	enc = [NSMutableString string];
	cte = [NSMutableString string];
	aBody = [NSMutableString string];
	if (theGroup) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[[theGroup newsServer] serverName]];
	} else if (deferredPosting) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[deferredPosting serverName]];
	}
	if (!theMgr) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServerAtIndex:0];
	}
	[self _appendMessageBodyTo:aBody putEncodingInto:enc cte:cte senc:&stringEncoding];

	[self _appendAttachmentsToBody:aBody numberOfParts:&numParts];

	if (![[ISOPreferences sharedInstance] doNotAutomaticallySendUserAgentHeader]) {
		[self _appendHeader:@"User-Agent: " withValue:[NSString stringWithFormat:@"%@/%@", K_HALIME_APPNAME, K_CURRENTVERSIONSTRING] toMessage:theMessage];
	}
	fromString = [[fromField stringValue] getTransferableStringWithIANAName:enc andCFStringEncoding:stringEncoding flexible:YES];
	[self _appendHeader:@"From: " withValue:fromString toMessage:theMessage];

	subjectString = [[subjectField stringValue] getTransferableStringWithIANAName:enc andCFStringEncoding:stringEncoding flexible:YES];
	[self _appendHeader:@"Subject: " withValue:subjectString toMessage:theMessage];
	
	[self _appendHeader:@"Newsgroups: " withValue:[newsgroupsField stringValue] toMessage:theMessage];
	if ([[ISOPreferences sharedInstance] isOffline]) {
		[self _appendHeader:@"Date: " withValue:[[NSCalendarDate calendarDate] descriptionWithCalendarFormat:@"%a, %d %b %Y %H:%M:%S %z"] toMessage:theMessage];
	}

	if ([[followUpField stringValue] length] > 0) {
		[self _appendHeader:@"Followup-To: " withValue:[followUpField stringValue] toMessage:theMessage];
	}
	if ([[replyToField stringValue] length] > 0) {
		replyToString = [[replyToField stringValue] getTransferableStringWithIANAName:enc andCFStringEncoding:stringEncoding flexible:YES];
		[self _appendHeader:@"Reply-To: " withValue:replyToString toMessage:theMessage];
	}
	messageID = [self _createMessageID:theMgr];
	[messageID retain];
	[self _appendHeader:@"MIME-Version: " withValue:@"1.0" toMessage:theMessage];
	[self _appendHeader:@"Message-ID: " withValue:messageID toMessage:theMessage];
	[self _appendHeader:@"Organization: " withValue:[[ISOPreferences sharedInstance] prefsOrganization] toMessage:theMessage];
	if (isFollowUp || isReplyTo) {
		NSMutableString	*refString = [NSMutableString string];
		if (storedReferences) {
			NSArray *refArray = [storedReferences componentsSeparatedByString:@"<"];
			int i, count;
			count = [refArray count];
			NSLog(@"All References: [%@]", storedReferences);
			if (count <= 7) {
				[refString appendFormat:@"%@ ", storedReferences];
			} else {
				for (i=count-8;i<count;i++) {
					NSLog(@"Reference: [%@]", [refArray objectAtIndex:i]);
					[refString appendFormat:@"<%@ ", [refArray objectAtIndex:i]];
				}
			}
		}
		if (storedMessageID) {
			[refString appendString:storedMessageID];
		}
		[self _appendHeader:@"References: " withValue:refString toMessage:theMessage];
	}
	if ([enc length]) {
		NSString *s = [NSString stringWithFormat:@"text/plain; charset=\"%@\"", enc];
		[self _appendHeader:@"Content-Type: " withValue:s toMessage:theMessage];
	}
	if ([cte length]) {
		[self _appendHeader:@"Content-Transfer-Encoding: " withValue:cte toMessage:theMessage];
	}
	[self _appendAdditionalHeadersToMessage:theMessage];
	[theMessage appendString:@"\r\n"];

	if (aBody) {
		[theMessage appendString:aBody];
	}
	
	thisPosting = [[ISONewsPosting alloc] initFromString:theMessage];
	if (thisPosting) {
		if ((![[ISOPreferences sharedInstance] isOffline]) && (deferredPosting)) {
			putIntoDeferred = (NSRunAlertPanel(NSLocalizedString(@"Send Posting", @""),
					NSLocalizedString(@"The posting you want to send was opened from the 'Offline Manager Window', i.e. it was a deferred posting. Do you want to send this posting immediately or put it back to the 'Offline Manager' so you can send it later?", @""),
					NSLocalizedString(@"Send Immediately", @""),
					nil,
					NSLocalizedString(@"Send Later", @"")) == NSAlertOtherReturn);
			
		} else {
			putIntoDeferred = NO;
		}
		if ([[ISOPreferences sharedInstance] isOffline] || putIntoDeferred) {
			if (deferredPosting) { // Now remove the old copy of this posting
				[[ISOOutPostingMgr sharedOutPostingMgr] removeOutPosting:deferredPosting requester:self];
			}
			[thisPosting setServerName:[[theMgr newsServer] serverName]];
			[[ISOOutPostingMgr sharedOutPostingMgr] addOutPosting:thisPosting requester:self];
			NSRunAlertPanel(NSLocalizedString(@"Posting added to Outgoing", @""),
				NSLocalizedString(@"As you are OFFLINE the posting was added to the list of outgoing postings. If you want to send them, please choose 'Show Offline Manager' and send it from there. Also note: This posting was automatically saved, so you don't need to worry that it could get lost.", @""),
				NSLocalizedString(@"OK", @""),
				nil,
				nil);
			[((NSWindow *)window) setDelegate:nil];
			[window orderOut:self];
			if (originalPosting) {
				if (isFollowUp) {
					[originalPosting setIsFollowedUp:YES];
				} 
				if (isReplyTo) {
					[originalPosting setIsReplied:YES];
				}
			}
			[self dealloc];
		} else {
			[theMessage appendString:@"\r\n"];
			if (isReplyTo) {
				NSString	*recipientEmail = [self recipientEmail];
				NSString	*senderEmail = [self _makeSMTPEmailAddress:fromString];
				if (recipientEmail && senderEmail) {
					ISOSMTPClient	*smtpClient;
					[ISOActiveLogger logWithDebuglevel:30 :@"Sending as reply to: [%@], from: [%@], alwaysPost: %@", recipientEmail, senderEmail, alwaysPost? @"YES":@"NO"];
					smtpClient = [[ISOSMTPClient alloc] 
									initForServerNamed:[[ISOPreferences sharedInstance] prefsMailServer] 
									withSender:senderEmail
									forRecipient:recipientEmail
									sendAsPostingAndEmail:alwaysPost];
					if (smtpClient && [smtpClient connect:self]) {
						int	result;
						
						result = [smtpClient sendPosting:thisPosting writeErrorsInto:errorMsg usingStringEncoding:stringEncoding cte:cte];
						[smtpClient disconnect:self];
						if (result == K_SMTPPOSTOKAYRESULT_INT) {
							if (!alwaysPost) {
								if ([[ISOPreferences sharedInstance] prefsShouldSendingOKAlert]) {
									[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingOKAlertSound];
								}
								if ([[ISOPreferences sharedInstance] prefsRememberSentPostings]) {
									[[ISOSentPostingsMgr sharedInstance] addSentPostingID:messageID];
									[[ISOSentPostingsMgr sharedInstance] save];
								}
								if ([[ISOPreferences sharedInstance] prefsSaveSentPostings]) {
									NSMutableString *filename = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsSentPostingsSaveDirectory]];
									if (filename) {
										[filename appendFormat:@"/%@.txt", messageID];
										if (![theMessage writeToFile:filename atomically:NO]) {
											NSRunAlertPanel(NSLocalizedString(@"Couldn't save a copy of the file", @""),
												NSLocalizedString(@"Couldn't save a copy of the file to harddisc...", @""),
												NSLocalizedString(@"Damn", @""),
												nil,
												nil);
										}
									}
									
								}
								if (deferredPosting) {
									[[ISOOutPostingMgr sharedOutPostingMgr] removeOutPosting:deferredPosting requester:self];
								}
							}
							sentSuccessfully = YES;
							if (originalPosting) {
								[originalPosting setIsReplied:YES];
							}
						} else {
							if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
								[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
							}
							NSRunAlertPanel(NSLocalizedString(@"Sending as Mail failed", @""),
								NSLocalizedString(@"Couldn't send the posting as mail due to the following error: %@", @""),
								NSLocalizedString(@"OK, I'll try again later", @""),
								nil,
								nil, errorMsg);
						}
					}
				} else {
					NSRunAlertPanel(NSLocalizedString(@"Can't send message as Mail", @""),
						NSLocalizedString(@"This message cannot be send as Mail because there is no recipient information available. Please either fill out the recipient (To) field or post it as newsposting to the group.", @""),
						NSLocalizedString(@"OK", @""),
						nil,
						nil);
				}
			}
			if (alwaysPost && theMgr) {
				sentSuccessfully = NO;
				if ([theMgr connect:self]) {
					int result;
					result = [theMgr sendPosting:thisPosting writeErrorsInto:errorMsg usingStringEncoding:stringEncoding cte:cte];
					[theMgr disconnect:self];
					if (result == K_NNTPPOSTOKAYRESULT_INT) {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingOKAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingOKAlertSound];
						}
						if ([[ISOPreferences sharedInstance] prefsRememberSentPostings]) {
							[[ISOSentPostingsMgr sharedInstance] addSentPostingID:messageID];
							[[ISOSentPostingsMgr sharedInstance] save];
						}
						if ([[ISOPreferences sharedInstance] prefsSaveSentPostings]) {
							NSMutableString *filename = [NSMutableString stringWithString:[[ISOPreferences sharedInstance] prefsSentPostingsSaveDirectory]];
							if (filename) {
								[filename appendFormat:@"/%@.txt", messageID];
								if (![theMessage writeToFile:filename atomically:NO]) {
									NSRunAlertPanel(NSLocalizedString(@"Couldn't save a copy of the file", @""),
										NSLocalizedString(@"Couldn't save a copy of the file to harddisc...", @""),
										NSLocalizedString(@"Damn", @""),
										nil,
										nil);
								}
							}
							
						}
						if (deferredPosting) {
							[[ISOOutPostingMgr sharedOutPostingMgr] removeOutPosting:deferredPosting requester:self];
						}
						sentSuccessfully = YES;
						if ((originalPosting) && (isFollowUp)) {
							[originalPosting setIsFollowedUp:YES];
						}
					} else if (result == K_NNTPPOSTFORBIDDENRESPONSE_INT) {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Posting not allowed", @""),
							NSLocalizedString(@"Couldn't post the message due to an 440 error: You are not allowed to post to this server.", @""),
							NSLocalizedString(@"OK, forget it then.", @""),
							nil,
							nil);
					} else if (result == K_NNTPPOSTFAILURERESPONSE_INT) {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Posting failed", @""),
							NSLocalizedString(@"Couldn't post the message due to an 441 error: %@", @""),
							NSLocalizedString(@"OK, I'll try again later", @""),
							nil,
							nil, errorMsg);
					} else {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Posting failed", @""),
							NSLocalizedString(@"Couldn't post the message due to an unknown error. It is neither 440 nor 441. I am sorry...", @""),
							NSLocalizedString(@"OK, I'll try again later", @""),
							nil,
							nil);
					}
				} else {
					if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
						[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
					}
					NSRunAlertPanel(NSLocalizedString(@"Posting failed", @""),
						NSLocalizedString(@"Posting of your message failed because I could not connect to the server. Maybe you would like to try again later (the server may be down, the connection broken, no power supply...;-)", @""),
						NSLocalizedString(@"Merde!", @""),
						nil,
						nil);
				}
			} else if (!alwaysPost) {
				sentSuccessfully = YES;
			} else {
				sentSuccessfully = NO;
				[ISOBeep beep:@"No NNTP Server found... There is something really fishy here!"];
			}
		}
		[thisPosting release];
	} else {
		if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
		}
		NSRunAlertPanel(NSLocalizedString(@"Could not create a posting", @""),
			NSLocalizedString(@"Couldn't create a logical posting out of the posting data", @""),
			NSLocalizedString(@"Damn", @""),
			nil,
			nil);
	}
	[messageID release];
	if (sentSuccessfully) {
		[((NSWindow *)window) setDelegate:nil];
		[window orderOut:self];
		[self dealloc];
	}
}

- (void)attachmentTableClicked:sender
{
	int	selectedRow = [attachmentsTable selectedRow];
	if ((selectedRow >=0) && (selectedRow < [attachments count])) {
		[removeButton setEnabled:YES];
	} else {
		[removeButton setEnabled:NO];
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == attachmentsTable) {
		return [attachments count];
	} else if (aTableView == headerTable) {
		return [additionalHeaders count];
	} else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if ((aTableView == attachmentsTable) && (rowIndex >=0) && (rowIndex < [attachments count]))  {
		if ([(NSString *)[aTableColumn identifier] compare:@"ATT_NAME"] == NSOrderedSame) {
			return [[attachments objectAtIndex:rowIndex] lastPathComponent];
		} else {
			NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[attachments objectAtIndex:rowIndex] traverseLink:YES];
			if (fileAttributes) {
				int	fileSize = [[fileAttributes objectForKey:NSFileSize] intValue];
				if (fileSize < 1024) {
					return [NSString stringWithFormat:@"%d %@", fileSize,
							NSLocalizedString(@"Bytes", @"")];
				} else if (fileSize < (1024 * 1024)) {
					return [NSString stringWithFormat:@"%6.2f %@", fileSize/1024.0,
							NSLocalizedString(@"KB", @"Abbreviation for Kilobytes")];
				} else {
					return [NSString stringWithFormat:@"%6.2f %@", fileSize/(1024.0*1024.0),
							NSLocalizedString(@"MB", @"Abbreviation for Megabytes")];
				}
			} else {
				return @"?";
			}
		}
	} else if ((aTableView == headerTable) && (rowIndex >= 0) && (rowIndex < [additionalHeaders count])) {
		if ([(NSString *)[aTableColumn identifier] compare:@"HEADER"] == NSOrderedSame) {
			return [[additionalHeaders objectAtIndex:rowIndex] objectAtIndex:0];
		} else {
			return [[additionalHeaders objectAtIndex:rowIndex] objectAtIndex:1];
		}
	} else {
		return @"";
	}
}

- (void)recolorizeTextview:sender
{
	[textView colorizeRange:NSMakeRange(0, [[textView string] length])];
}

- (void)encodingChanged:sender
{
}


/* *************************** */
- (void)setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: MAC_ISOHalimeSentDocToolbarIdentifier] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
	[window setToolbar: toolbar];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:MAC_SENDPOSTING, MAC_FORGETIT, MAC_LOADDRAFT, MAC_SAVEDRAFT,
									MAC_ADDATTACHMENT, MAC_RECOLORIZE, MAC_ENCODING, MAC_ADDITIONALHEADERS,
						NSToolbarCustomizeToolbarItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, 
						NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, 
						nil];
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    return [NSArray arrayWithObjects:MAC_SENDPOSTING, MAC_LOADDRAFT, MAC_ADDATTACHMENT,
						NSToolbarSeparatorItemIdentifier, 
						MAC_ENCODING, MAC_SAVEDRAFT, MAC_RECOLORIZE,  MAC_ADDITIONALHEADERS, nil];
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
	
    if ([itemIdent isEqual: MAC_SENDPOSTING]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Send Posting", @"")
				paletteLabel:NSLocalizedString(@"Send Posting", @"")
				toolTip: NSLocalizedString(@"Send the posting and close window", @"")
				image:@"SendPosting"
				target:self
				action:@selector(sendClicked:)];
    } else if ([itemIdent isEqual: MAC_ADDITIONALHEADERS]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Additional Headers", @"")
				paletteLabel:NSLocalizedString(@"Additional Headers", @"")
				toolTip: NSLocalizedString(@"Edit/specify additional headers for this posting", @"")
				image:@"AdditionalHeaders"
				target:self
				action:@selector(additionalHeaders:)];
    } else if ([itemIdent isEqual: MAC_FORGETIT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Forget It", @"")
				paletteLabel:NSLocalizedString(@"Forget it", @"")
				toolTip: NSLocalizedString(@"Close the window and discard all changes", @"")
				image:@"ForgetIt"
				target:self
				action:@selector(cancelClicked:)];
    } else if ([itemIdent isEqual: MAC_LOADDRAFT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Load Draft", @"")
				paletteLabel:NSLocalizedString(@"Load Draft", @"")
				toolTip: NSLocalizedString(@"Load a previously saved message draft", @"")
				image:@"LoadDraft"
				target:self
				action:@selector(loadClicked:)];
    } else if ([itemIdent isEqual: MAC_SAVEDRAFT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Save as Draft", @"")
				paletteLabel:NSLocalizedString(@"Save as Draft", @"")
				toolTip: NSLocalizedString(@"Save current posting as a draft for later use", @"")
				image:@"SaveAsDraft"
				target:self
				action:@selector(saveClicked:)];
    } else if ([itemIdent isEqual: MAC_ADDATTACHMENT]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Add Attachment", @"")
				paletteLabel:NSLocalizedString(@"Add Attachment", @"")
				toolTip: NSLocalizedString(@"Add attachments to the posting", @"")
				image:@"AddAttachment"
				target:self
				action:@selector(addAttachmentButtonClicked:)];
    } else if ([itemIdent isEqual: MAC_RECOLORIZE]) {
		[self _setToolbarItem:toolbarItem 
				label:NSLocalizedString(@"Re-Colorize", @"")
				paletteLabel:NSLocalizedString(@"Re-Colorize", @"")
				toolTip: NSLocalizedString(@"Quote-colorize the posting text for better reading", @"")
				image:@"ReColorize"
				target:self
				action:@selector(recolorizeTextview:)];
	} else if ([itemIdent isEqual: MAC_ENCODING]) {
		aPopupButton = encodingPopup;
		[aPopupButton removeAllItems];
		MakeEncodingPopup (aPopupButton, self, @selector(controlTextDidChange:), NO);
		[aPopupButton selectItemWithTag:[[ISOPreferences sharedInstance] prefsDefaultSendPostingEncoding]];

		[toolbarItem setView:aPopupButton];
		[toolbarItem setMinSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];
		[toolbarItem setMaxSize:NSMakeSize(NSWidth([aPopupButton frame]), NSHeight([aPopupButton frame]))];

		[toolbarItem setLabel:NSLocalizedString(@"Encoding", @"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Encoding", @"")];
		[toolbarItem setToolTip:NSLocalizedString(@"Set the character encoding of the posting", @"")];
	} else {
		toolbarItem = nil;
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
    BOOL 		enable = YES;
//	NSString	*itemIdent = [toolbarItem itemIdentifier];

    return enable;
}

/* *************** Additional Headers ******************* */
- (void)headerEntryFieldsChanged:(NSNotification *)aNotification
{
	NSRange	aRange;
	int	selectedRow = [headerTable selectedRow];

	aRange = [[headerField stringValue] rangeOfString:@":"];
	[addHeaderButton setEnabled:(aRange.length == 1) && [[valueField stringValue] length]];
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

- (void)newsgroupsPopupClicked:sender
{
	if ([[newsgroupsPopup selectedItem] tag] == 1) {
		if (originalPosting) {
			if ([originalPosting replyToHeader]) {
				[newsgroupsField setStringValue:[originalPosting replyToHeader]];
			} else {
				[newsgroupsField setStringValue:[originalPosting fromHeader]];
			}
		} else if (deferredPosting) {
			if ([deferredPosting replyToHeader]) {
				[newsgroupsField setStringValue:[deferredPosting replyToHeader]];
			} else {
				[newsgroupsField setStringValue:[deferredPosting fromHeader]];
			}
		} else {
			NSBeep();
			[newsgroupsPopup setEnabled:NO];
			[newsgroupsPopup selectItemWithTag:0];
		}
		[newsgroupsField setEnabled:YES];
		[newsgroupsField setTitle:NSLocalizedString(@"To Sender:", @"")];
		isReplyTo = YES;
		[window setTitle:[NSString stringWithFormat:@"%@ %@", [subjectField stringValue],
				NSLocalizedString(@"(Reply via Email)", @"")]];
	} else {
		isReplyTo = ([[newsgroupsPopup selectedItem] tag] == 2);
		if (originalPosting) {
			if ([originalPosting followUpHeader] && ([[originalPosting followUpHeader] caseInsensitiveCompare:@"poster"] != NSOrderedSame)) {
				[newsgroupsField setStringValue:[originalPosting followUpHeader]];
			} else {
				[newsgroupsField setStringValue:[originalPosting newsgroupsHeader]];
			}
		} else if (deferredPosting) {
			if ([deferredPosting followUpHeader] && ([[originalPosting followUpHeader] caseInsensitiveCompare:@"poster"] != NSOrderedSame)) {
				[newsgroupsField setStringValue:[deferredPosting followUpHeader]];
			} else {
				[newsgroupsField setStringValue:[deferredPosting newsgroupsHeader]];
			}
		} else if (theGroup) {
			[newsgroupsField setStringValue:[theGroup groupName]]; 
		}
		if ([[newsgroupsPopup selectedItem] tag] == 0) {
			[newsgroupsField setTitle:NSLocalizedString(@"To Newsgroup:", @"")];
		} else {
			[newsgroupsField setTitle:NSLocalizedString(@"To NG/Sender:", @"")];
		}
		[newsgroupsField setEnabled:YES];
		if (isFollowUp) {
			[window setTitle:[NSString stringWithFormat:@"%@ %@", [subjectField stringValue],
				NSLocalizedString(@"(FollowUp)", @"")]];
		} else {
			[window setTitle:[subjectField stringValue]];
		}
	}
	[window setDocumentEdited:YES];	
}

- (void)followUpToPopupClicked:sender
{
	if ([[followUpToPopup selectedItem] tag] == 1) {
		[followUpField setStringValue:@"poster"];
		[followUpField setEnabled:NO];
	} else {
		[followUpField setStringValue:@""];
		[followUpField setEnabled:YES];
	}
}

- (NSString *)_makeSMTPEmailAddress:(NSString *)aString
{
	NSRange leftBRange;
	NSRange	rightBRange;
	NSString	*rEmail = aString;
	
	if (rEmail) {
		leftBRange = [rEmail rangeOfString:@"<"];
		if (leftBRange.location != NSNotFound) {
			rEmail = [rEmail substringFromIndex:leftBRange.location + 1];
		}
	
		rightBRange = [rEmail rangeOfString:@">"];
		if (rightBRange.location != NSNotFound) {
			rEmail = [rEmail substringToIndex:rightBRange.location];
		}
		return rEmail;
	} else {
		return nil;
	}
}

- (NSString *)recipientEmail
{
	NSString	*recipientEmail = nil;
	NSString	*rEmail = nil;
	
	if (originalPosting) {
		if ([originalPosting replyToHeader]) {
			rEmail = [originalPosting replyToHeader];
		} else {
			rEmail = [originalPosting fromHeader];
		}
	} else if (deferredPosting) {
		if ([deferredPosting replyToHeader]) {
			rEmail = [deferredPosting replyToHeader];
		} else {
			rEmail = [deferredPosting fromHeader];
		}
	}
	if (rEmail) {
		recipientEmail = [self _makeSMTPEmailAddress:rEmail];
	}
	return recipientEmail;
}

@end
