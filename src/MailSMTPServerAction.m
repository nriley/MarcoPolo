//
//  MailSMTPServerAction.m
//  MarcoPolo
//
//  Created by David Symonds on 3/04/07.
//

#import "MailSMTPServerAction.h"


@implementation MailSMTPServerAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *account = [[actionDict valueForKey:@"parameter"] valueForKey:@"account"];
	NSString *server = [[actionDict valueForKey:@"parameter"] valueForKey:@"server"];

	if ([account isEqualToString:kAllMailAccounts])
		return [NSString stringWithFormat:NSLocalizedString(@"Setting SMTP server for all Mail accounts to '%@'.", @""),
			server];
	return [NSString stringWithFormat:NSLocalizedString(@"Setting SMTP server for Mail account '%@' to '%@'.", @""),
		account, server];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;
{
	// TODO: support specific account specification
	NSString *account = [[actionDict valueForKey:@"parameter"] valueForKey:@"account"];
	NSString *server = [[actionDict valueForKey:@"parameter"] valueForKey:@"server"];

	NSString *script;
	// TODO: escape parameters?
	if (![account isEqualToString:kAllMailAccounts]) {
		script = [NSString stringWithFormat:
			@"tell application \"Mail\"\n"
			"  set acc to the first account whose name is \"%@\"\n"
			"  set srv to the first smtp server whose server name is \"%@\"\n"
			"  set the smtp server of acc to srv\n"
			"end tell", account, server];
	} else {
		script = [NSString stringWithFormat:
			@"tell application \"Mail\"\n"
			"  set srv to the first smtp server whose server name is \"%@\"\n"
			"  set the smtp server of every account to srv\n"
			"end tell", server];
	}

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set SMTP server!", @"In MailSMTPServerAction");
		return NO;
	}

	return YES;
}

- (NSString *)leadText
{
	return NSLocalizedString(@"Set Mail's SMTP server:", @"");
}

- (NSArray *)serverOptions
{
	NSString *script =
		@"tell application \"Mail\"\n"
		"  get server name of every smtp server\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];
	return list;
}

@end
