//
//  MailIMAPServerAction.m
//  MarcoPolo
//
//  Created by David Symonds on 10/08/07.
//

#import "MailIMAPServerAction.h"


@implementation MailIMAPServerAction

- (NSString *)leadText
{
	return NSLocalizedString(@"Set Mail's IMAP server hostname:", @"");
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	return [NSString stringWithFormat:NSLocalizedString(@"Setting Mail's IMAP server to '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *script = [NSString stringWithFormat:
		@"tell application \"Mail\"\n"
		"  repeat with acc in every imap account\n"
		"    set the server name of acc to \"%@\"\n"
		"  end repeat\n"
		"end tell\n", [actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set IMAP server!", @"In MailIMAPServerAction");
		return NO;
	}

	return YES;
}

@end
