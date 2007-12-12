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
	NSString *setting = [actionDict valueForKey:@"parameter"];
	NSArray *split = [setting componentsSeparatedByString:@" "];
	int t = [[split objectAtIndex:1] intValue];

	NSString *action = @"unknown";
	if ([[split objectAtIndex:0] isEqualToString:@"comp"])
		action = @"computer";
	else if ([[split objectAtIndex:0] isEqualToString:@"disp"])
		action = @"display";
	else if ([[split objectAtIndex:0] isEqualToString:@"disk"])
		action = @"disk";

	if (t == 0)
		return [NSString stringWithFormat:
			NSLocalizedString(@"Disabling %@ sleep.", @""), action];
	else if (t == 1)
		return [NSString stringWithFormat:
			NSLocalizedString(@"Setting %@ sleep time to 1 minute.", @""), action];
	else
		return [NSString stringWithFormat:NSLocalizedString(@"Setting %@ sleep time to %d minutes.", @""), action, t];
}

- (void)checkPerms
{
	if (![self executeAppleScript:@"do shell script \"/bin/ls -l /usr/bin/pmset | awk '{if (substr($1, 4, 1) == \\\"s\\\") exit 0; else exit 1;}'\""]) {
		[self executeAppleScript:@"do shell script \"chmod +s /usr/bin/pmset\" with administrator privileges"];
	}
}

- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString
{
	NSString *setting = [actionDict valueForKey:@"parameter"];
	NSString *cmd = nil;
	NSArray *split = [setting componentsSeparatedByString:@" "];

	if ([[split objectAtIndex:0] isEqualToString:@"comp"])
		cmd = [NSString stringWithFormat:@"sleep %@", [split objectAtIndex:1]];
	else if ([[split objectAtIndex:0] isEqualToString:@"disp"])
		cmd = [NSString stringWithFormat:@"displaysleep %@", [split objectAtIndex:1]];
	else if ([[split objectAtIndex:0] isEqualToString:@"disk"])
		cmd = [NSString stringWithFormat:@"disksleep %@", [split objectAtIndex:1]];
	else {
		*errorString = [NSString stringWithFormat:NSLocalizedString(@"Invalid option: %@", @""),
			setting];
		return NO;
	}

	[self checkPerms];

	NSString *script = [NSString stringWithFormat:@"do shell script \"/usr/bin/pmset %@\"", cmd];
	if (![self executeAppleScript:script]) {
		*errorString = [NSString stringWithFormat:NSLocalizedString(@"Couldn't set '%@'!", @""),
			setting];
		return NO;
	}

	return YES;
}

- (NSString *)suggestionLeadText
{
	return NSLocalizedString(@"Set the following sleep setting to:", @"");
}

- (NSArray *)suggestions
{
	NSArray* opts = [NSArray arrayWithObjects:@"3", @"5", @"15", @"30", @"60", @"120", @"0", nil];
	NSArray* short_names = [NSArray arrayWithObjects:@"comp", @"disp", @"disk", nil];
	NSArray* names = [NSArray arrayWithObjects:@"Computer sleep", @"Display sleep", @"Disk sleep", nil];
	NSMutableArray *arr = [NSMutableArray 
                              arrayWithCapacity:[opts count] * [names count]];

	int i, j;
	for (i = 0; i < [names count]; ++i) {
		for (j = 0; j < [opts count]; ++j) {
			NSString *option = [NSString stringWithFormat:@"%@ %@",
				[short_names objectAtIndex:i],
				[opts objectAtIndex:j]];
			NSString *description;

			if ([[opts objectAtIndex:j] isEqualToString:@"0"])
				description = [NSString stringWithFormat:NSLocalizedString(@"%@ never", @""), [names objectAtIndex:i]];
			else if ([[opts objectAtIndex:j] isEqualToString:@"1"])
				description = [NSString stringWithFormat:NSLocalizedString(@"%@ 1 minute", @""), [names objectAtIndex:i]];
			else
				description = [NSString stringWithFormat:NSLocalizedString(@"%@ %@ minutes", @""), [names objectAtIndex:i], [opts objectAtIndex:j]];

			[arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				option, @"parameter",
				description, @"description", nil]];
		}
	}

	return arr;
}

@end
