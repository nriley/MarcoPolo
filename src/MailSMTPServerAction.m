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
	NSString *account = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	NSString *server = [[actionDict valueForKey:@"parameter"] objectAtIndex:1];

	if ([account isEqualToString:kAllMailAccounts])
		return [NSString stringWithFormat:NSLocalizedString(@"Setting SMTP server for all Mail accounts to '%@'.", @""),
			server];
	return [NSString stringWithFormat:NSLocalizedString(@"Setting SMTP server for Mail account '%@' to '%@'.", @""),
		account, server];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;
{
	NSString *account = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	NSString *server = [[actionDict valueForKey:@"parameter"] objectAtIndex:1];

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

- (NSArray *)secondSuggestions
{
	NSString *script =
		@"tell application \"Mail\"\n"
		"  get server name of every smtp server\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count]];
	NSEnumerator *en = [list objectEnumerator];
	NSString *accName;
	while ((accName = [en nextObject])) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			accName, @"description", accName, @"parameter", nil];
		[arr addObject:dict];
	}

	return arr;
}

@end
