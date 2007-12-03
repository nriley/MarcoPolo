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
	return [NSString stringWithFormat:NSLocalizedString(@"Setting Mail's SMTP server to '%@'.", @""),
		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;
{
	NSString *script = [NSString stringWithFormat:
		@"tell application \"Mail\"\n"
		"  repeat with server in every smtp server\n"
		"    if (server name of server is equal to \"%@\") then\n"
		"      repeat with acc in every account\n"
		"        if acc is enabled then\n"
		"          set smtp server of acc to server\n"
		"        end if\n"
		"      end repeat\n"
		"      exit repeat\n"
		"    end if\n"
		"  end repeat\n"
		"end tell\n", [actionDict valueForKey:@"parameter"]];

	if (![self executeAppleScript:script]) {
		*errorString = NSLocalizedString(@"Couldn't set SMTP server!", @"In MailSMTPServerAction");
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set Mail's SMTP server hostname to", @"");
}

- (NSArray *)suggestions
{
	NSString *script =
		@"tell application \"Mail\"\n"
		"  get server name of every smtp server\n"
		"end tell\n";

	NSArray *list = [self executeAppleScriptReturningListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *opts = [NSMutableArray arrayWithCapacity:[list count]];
	NSEnumerator *en = [list objectEnumerator];
	NSString *hostname;
	while ((hostname = [en nextObject])) {
		[opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			hostname, @"parameter", hostname, @"description", nil]];
	}

	return opts;
}

@end
