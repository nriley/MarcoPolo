//
//  AdiumAction.m
//  MarcoPolo
//
//  Created by David Symonds on 28/12/07.
//

#import "AdiumAction.h"


@implementation AdiumAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
//	return [NSString stringWithFormat:NSLocalizedString(@"Setting default printer to '%@'.", @""),
//		[actionDict valueForKey:@"parameter"]];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
//	NSArray *args = [NSArray arrayWithObjects:@"-d", [actionDict valueForKey:@"parameter"], nil];
//	NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/lpoptions" arguments:args];
//	[task waitUntilExit];
//
//	if ([task terminationStatus] != 0) {
//		*errorString = NSLocalizedString(@"Couldn't set default printer!", @"");
//		return NO;
//	}
//
//	return YES;
}

- (NSString *)leadText
{
	return NSLocalizedString(@"Set Adium status:", @"");
}

- (NSArray *)firstSuggestions
{
	// Get all accounts, along with their respective service names
	NSString *script =
		@"tell application \"Adium\"\n"
		"  set accList to {}\n"
		"  repeat with serv in every service\n"
		"    repeat with acc in every account of serv\n"
		"      copy {title of serv, title of acc} to end of accList\n"
		"    end repeat\n"
		"  end repeat\n"
		"  get accList\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count] + 1];
	[arr addObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			kAllAdiumAccounts, @"parameter",
			NSLocalizedString(@"All accounts", @"In account list for actions"), @"description", nil]];

	NSEnumerator *en = [list objectEnumerator];
	NSArray *acc;
	while ((acc = [en nextObject])) {
		// acc is something like ["GTalk", "dsymonds@gmail.com"]
		NSString *service = [acc objectAtIndex:0], *account = [acc objectAtIndex:1];
		NSString *desc = [NSString stringWithFormat:@"%@ (%@)", account, service];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			desc, @"description", account, @"parameter", nil];
		[arr addObject:dict];
	}

	return arr;	
}

- (NSArray *)secondSuggestions
{
	// Get all statuses, including type (available, away, etc.) and title
	NSString *script =
		@"tell application \"Adium\"\n"
		"  set statusList to {}\n"
		"  repeat with stat in every status\n"
		"    copy {type of stat as text, title of stat} to end of statusList\n"
		"  end repeat\n"
		"  get statusList\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count]];
	NSEnumerator *en = [list objectEnumerator];
	NSArray *status;
	while ((status = [en nextObject])) {
		// status is something like ["away", "Lunch"]
		// TODO: do a nicer description? Use colours?
		NSString *type = [status objectAtIndex:0], *title = [status objectAtIndex:1];
		NSString *desc = [NSString stringWithFormat:@"%@ (%@)", title, type];
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			desc, @"description", title, @"parameter", nil];
		[arr addObject:dict];
	}

	// TODO: perhaps sort these to group them like Adium does:
	//	- available
	//	- away/invisible
	//	- offline

	return arr;	
}

@end
