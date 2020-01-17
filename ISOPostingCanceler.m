//
//  ISOPostingCanceler.m
//  Halime
//
//  Created by Imdat Solak on Thu Mar 28 2002.
//  Copyright (c) 2001 Imdat Solak. All rights reserved.
//

#import "ISOPostingCanceler.h"
#import "ISOIdentityMgr.h"
#import "ISOBeep.h"
#import "ISONewsServerMgr.h"
#import "ISOLogger.h"
#import "NSString_Extensions.h"
#import "ISOOutPostingMgr.h"
#import "ISOPreferences.h"
#import "version.h"

@implementation ISOPostingCanceler

- init
{
	[super init];
	postingToCancel = nil;
	activeGroup = nil;
	return self;
}

- (BOOL)_getIdentityEmail:(NSMutableString *)idEmail andName:(NSMutableString *)idName forPosting:(ISONewsPosting *)aPosting
{
	BOOL			identityFound = NO;
	int				i, count;
	NSString		*email = nil;
	NSString		*name = nil;
	NSRange			aRange;
	NSString		*from = [aPosting fromHeader];
	NSString		*sender = [aPosting headerForKey:@"Sender:"];
	NSString		*replyTo = [aPosting replyToHeader];
	ISOIdentityMgr	*theIDMgr = [ISOIdentityMgr sharedIdentityMgr];
	
	count = [theIDMgr identityCount];
	i = 0;
	while (i<count && !identityFound) {
		email = [[ISOIdentityMgr sharedIdentityMgr] emailOfIdentityAtIndex:i];
		name = [[ISOIdentityMgr sharedIdentityMgr] nameOfIdentityAtIndex:i];
		
		if (!identityFound && from) {
			aRange = [from rangeOfString:email];
			identityFound = (aRange.length == [email length]);
		}
		if (!identityFound && sender) {
			aRange = [sender rangeOfString:email];
			identityFound = (aRange.length == [email length]);
		}
		if (!identityFound && replyTo) {
			aRange = [replyTo rangeOfString:email];
			identityFound = (aRange.length == [email length]);
		}
		i++;
	}
	if (identityFound) {
		if (idEmail) {
			[idEmail setString:email];
		}
		if (idName) {
			[idName setString:name];
		}
	} else {
		if (idEmail) {
			[idEmail setString:@""];
		}
		if (idName) {
			[idName setString:@""];
		}
	}
	return identityFound;
}


- (BOOL)canCancelPosting:(ISONewsPosting *)aPosting
{
	BOOL retvalue = NO;
	
	if (aPosting) {
		retvalue = [self _getIdentityEmail:nil andName:nil forPosting:aPosting];
	}
	return retvalue;
}

- (void)runSheetForWindow:(id)aWindow withPosting:(ISONewsPosting *)aPosting inGroup:(ISONewsGroup *)aGroup
{
	postingToCancel = aPosting;
	activeGroup = aGroup;
	if ([self canCancelPosting:aPosting]) {
		[[NSApplication sharedApplication] beginSheet:cancelPanel 
				modalForWindow:aWindow
				modalDelegate:nil
				didEndSelector:nil
				contextInfo:nil];
		[messageIDField setStringValue:[aPosting messageIDHeader]];
		[originalSubjectField setStringValue:[aPosting decodedSubject]];
		[originalNewsgroupsField setStringValue:[aPosting newsgroupsHeader]];
		[originalSenderField setStringValue:[aPosting decodedSender]];
		[dateSentField setStringValue:[aPosting dateHeader]];
	} else {
		[ISOBeep beep:@"You can cancel only postings you have sent by yourself!"];
	}
}

- (NSString *)_cleanedMID:(NSString *)anMID
{
	NSRange	aRange;
	NSRange	bRange;
	
	aRange = [anMID rangeOfString:@"<"];
	bRange = [anMID rangeOfString:@">"];
	if (aRange.length != 1 || bRange.length != 1) {
		return anMID;
	} else {
		return [anMID substringWithRange:NSMakeRange(aRange.location+1, bRange.location-1)];
	}
}

- (void)_sendPosting:(ISONewsPosting *)postingToSend withServerMgr:(ISONewsServerMgr *)theMgr
{
	if (postingToSend) {
		if ([[ISOPreferences sharedInstance] isOffline]) {
			[postingToSend setServerName:[[theMgr newsServer] serverName]];
			[[ISOOutPostingMgr sharedOutPostingMgr] addOutPosting:postingToSend requester:self];
			NSRunAlertPanel(NSLocalizedString(@"Cancel request added to outgoing", @""),
				NSLocalizedString(@"As you are OFFLINE the cancel request was added to the list of outgoing postings. If you want to send it, please choose 'Show Offline Manager' and send it from there.", @""),
				NSLocalizedString(@"OK", @""),
				nil,
				nil);
		} else {
			if (theMgr) {
				if ([theMgr connect:self]) {
					int result;
					NSMutableString *errorMsg = [NSMutableString stringWithCapacity:2048];
					result = [theMgr sendPosting:postingToSend writeErrorsInto:errorMsg usingStringEncoding:kCFStringEncodingISOLatin1 cte:@"7-bit"];
					[theMgr disconnect:self];
					if (result == K_NNTPPOSTOKAYRESULT_INT) {
						NSRunAlertPanel(NSLocalizedString(@"Cancel request sent", @""),
							NSLocalizedString(@"Your cancel request was sent to the server successfully.", @""),
							NSLocalizedString(@"OK", @""),
							nil,
							nil);
					} else if (result == K_NNTPPOSTFORBIDDENRESPONSE_INT) {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Cancel request not allowed", @""),
							NSLocalizedString(@"Couldn't send the cancel request due to an 440 error: You are not allowed to post to this server.", @""),
							NSLocalizedString(@"OK, forget it then.", @""),
							nil,
							nil);
					} else if (result == K_NNTPPOSTFAILURERESPONSE_INT) {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Cancel request failed", @""),
							NSLocalizedString(@"Couldn't send the cancel request due to an 441 error: %@", @""),
							NSLocalizedString(@"OK, I'll try again later", @""),
							nil,
							nil, errorMsg);
					} else {
						if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
							[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
						}
						NSRunAlertPanel(NSLocalizedString(@"Cancel request failed", @""),
							NSLocalizedString(@"Couldn't send the cancel request due to an unknown error. It is neither 440 nor 441. I am sorry...", @""),
							NSLocalizedString(@"OK, I'll try again later", @""),
							nil,
							nil);
					}
				} else {
					if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
						[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
					}
					NSRunAlertPanel(NSLocalizedString(@"Cancel request failed", @""),
						NSLocalizedString(@"Sending of your cancel request failed because I could not connect to the server. Maybe you would like to try again later (the server may be down, the connection broken, no power supply...;-)", @""),
						NSLocalizedString(@"Merde!", @""),
						nil,
						nil);
				}
			} else {
				[ISOBeep beep:@"No NNTP Server found... There is something really fishy here!"];
			}
		}
	} else {
		if ([[ISOPreferences sharedInstance] prefsShouldSendingErrorAlert]) {
			[[ISOPreferences sharedInstance] prefsAlertWithSoundKey:MAC_ISOSendingErrorAlertSound];
		}
		NSRunAlertPanel(NSLocalizedString(@"Could not create a valid cancel request", @""),
			NSLocalizedString(@"Couldn't create a valid cancel request. Please log into the logfile and report it to halime@imdat.de", @""),
			NSLocalizedString(@"Damn", @""),
			nil,
			nil);
	}
}

- (void)_doCancelPosting
{
	ISONewsServerMgr	*theMgr = nil;
	
	if (activeGroup) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[[activeGroup newsServer] serverName]];
	} else if (postingToCancel) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServer:[postingToCancel serverName]];
	}
	if (!theMgr) {
		theMgr = [[ISOPreferences sharedInstance] newsServerMgrForServerAtIndex:0];
	}
	if (theMgr) {
		NSMutableString *theMessage = [NSMutableString stringWithCapacity:512];
		NSMutableString *thisEmail = [NSMutableString string];
		NSMutableString *thisName = [NSMutableString string];
		NSString		*fromString;
		ISONewsPosting	*postingToSend;
		
		[self _getIdentityEmail:thisEmail andName:thisName forPosting:postingToCancel];
		fromString = [NSString stringWithFormat:@"%@ <%@>", thisName, thisEmail];
		fromString = [fromString getTransferableStringWithIANAName:@"ISO-8859-1" andCFStringEncoding:kCFStringEncodingISOLatin1 flexible:YES];

		[theMessage appendFormat:@"X-Newsreader: %@/%@\r\n", K_HALIME_APPNAME, K_CURRENTVERSIONSTRING];
		[theMessage appendFormat:@"From: %@\r\n", fromString];
		[theMessage appendFormat:@"Subject: cmsg cancel %@\r\n", [postingToCancel messageIDHeader]];
		[theMessage appendFormat:@"Control: cancel %@\r\n", [postingToCancel messageIDHeader]];
		[theMessage appendFormat:@"Message-ID: <cancel.%@>\r\n", [self _cleanedMID:[postingToCancel messageIDHeader]]];
		[theMessage appendFormat:@"Summary: %@\r\n", [cancelReasonPopup titleOfSelectedItem]];
		[theMessage appendFormat:@"Newsgroups: %@\r\n", [originalNewsgroupsField stringValue]];
		[theMessage appendFormat:@"X-Original-Subject: %@\r\n", [postingToCancel subjectHeader]];
		[theMessage appendFormat:@"X-Canceled-By: %@\r\n", fromString];
		[theMessage appendString:@"\r\n"];
		[theMessage appendString:@"Please cancel this post for the reasons indicated in the Summary header.\r\n"];
		[theMessage appendString:@"\r\n.\r\n"];
		postingToSend = [[ISONewsPosting alloc] initFromString:theMessage];
		[self _sendPosting:postingToSend withServerMgr:theMgr];
		[postingToSend release];
	} else {
		[ISOBeep beep:@"The posting to cancel has no newsserver assignment..."];
	}

}

- (void)cancelPosting:sender
{
	[self _doCancelPosting];
	[cancelPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:cancelPanel];
	postingToCancel = nil;
	activeGroup = nil;
}

- (void)abort:sender
{
	[cancelPanel orderOut:self];
	[[NSApplication sharedApplication] endSheet:cancelPanel];
	postingToCancel = nil;
	activeGroup = nil;
}

@end
