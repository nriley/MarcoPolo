//
//  ActionSettingMailServer.m
//  MarcoPolo
//
//  Created by David Symonds on 11/12/07.
//

#import "ActionSettingMailServer.h"


@implementation ActionSettingMailServer

- (NSString *)leadText
{
	return [super leadText];
}

- (NSArray *)firstSuggestions
{
	NSString *script =
		@"tell application \"Mail\"\n"
		"  get name of every account\n"
		"end tell";

	NSArray *list = [self executeAppleScriptReturningListOfStrings:script];
	if (!list)		// failure
		return [NSArray array];

	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[list count] + 1];
	[arr addObject:
		[NSDictionary dictionaryWithObjectsAndKeys:
			kAllMailAccounts, @"parameter",
			NSLocalizedString(@"All accounts", @"In account list for Mail server actions"), @"description", nil]];

	NSEnumerator *en = [list objectEnumerator];
	NSString *accName;
	while ((accName = [en nextObject])) {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			accName, @"description", accName, @"parameter", nil];
		[arr addObject:dict];
	}

	return arr;
}

- (NSArray *)secondSuggestions
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

@end
