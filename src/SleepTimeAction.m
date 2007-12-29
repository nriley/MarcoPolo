//
//  SleepTimeAction.m
//  MarcoPolo
//
//  Created by James Newton on 23/11/07.
//

#import "SleepTimeAction.h"


@implementation SleepTimeAction

- (NSString *)descriptionOf:(NSDictionary *)actionDict
{
	NSString *setting = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	int t = [[[actionDict valueForKey:@"parameter"] objectAtIndex:1] intValue];

	NSString *settingText = @"?";
	if ([setting isEqualToString:@"comp"])
		settingText = NSLocalizedString(@"Computer", @"Sleep setting");
	else if ([setting isEqualToString:@"disp"])
		settingText = NSLocalizedString(@"Display", @"Sleep setting");
	else if ([setting isEqualToString:@"disk"])
		settingText = NSLocalizedString(@"Disk", @"Sleep setting");

	if (t == 0)
		return [NSString stringWithFormat:NSLocalizedString(@"Disabling %@ sleep.", @""), settingText];
	else if (t == 1)
		return [NSString stringWithFormat:NSLocalizedString(@"Setting %@ sleep time to 1 minute.", @""), settingText];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Setting %@ sleep sleep time to %d minutes.", @""), settingText, t];
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *setting = [[actionDict valueForKey:@"parameter"] objectAtIndex:0];
	NSString *t = [[[actionDict valueForKey:@"parameter"] objectAtIndex:1] stringValue];
	NSString *cmd;

	if ([setting isEqualToString:@"comp"])
		cmd = @"sleep";
	else if ([setting isEqualToString:@"disp"])
		cmd = @"displaysleep";
	else if ([setting isEqualToString:@"disk"])
		cmd = @"disksleep";
	else {
		*errorString = [NSString stringWithFormat:NSLocalizedString(@"Invalid option: %@", @""),
			setting];
		return NO;
	}

	NSString *tool = @"/usr/bin/pmset";
	NSArray *args = [NSArray arrayWithObjects:cmd, t, nil];
	NSString *prompt = NSLocalizedString(@"MarcoPolo needs to change your power management settings.\n\n", @"");

	if (![self authExec:tool args:args authPrompt:prompt]) {
		*errorString = NSLocalizedString(@"Couldn't change sleep time!", @"");
		return NO;
	}

	return YES;
}

- (NSString *)leadText
{
	return NSLocalizedString(@"Set the following sleep setting:", @"");
}

- (NSArray *)firstSuggestions
{
	return [NSArray arrayWithObjects:
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"comp", @"parameter",
			NSLocalizedString(@"Computer", @"Sleep setting"), @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"disp", @"parameter",
			NSLocalizedString(@"Display", @"Sleep setting"), @"description", nil],
		[NSDictionary dictionaryWithObjectsAndKeys:
			@"disk", @"parameter",
			NSLocalizedString(@"Disk", @"Sleep setting"), @"description", nil],
		nil];
}

- (NSArray *)secondSuggestions
{
	int times[] = {3, 5, 15, 30, 60, 120, 0};
	int num_times = sizeof(times) / sizeof(times[0]);
	NSMutableArray *arr = [NSMutableArray arrayWithCapacity:num_times];

	int i;
	for (i = 0; i < num_times; ++i) {
		NSNumber *param = [NSNumber numberWithInt:times[i]];
		NSString *desc;
		if (times[i] == 0)
			desc = NSLocalizedString(@"never", @"A time or timeout");
		else if (times[i] == 1)
			desc = NSLocalizedString(@"1 minute", @"A time or timeout");
		else
			desc = [NSString stringWithFormat:
				NSLocalizedString(@"%d minutes", @"A time or timeout"), times[i]];
		[arr addObject:
			[NSDictionary dictionaryWithObjectsAndKeys:
				param, @"parameter", desc, @"description", nil]];
	}

	return arr;
}

@end
