//
//  SleepAction.m
//  MarcoPolo
//
//  Created by James Newton on 11/23/07.
//

#import "SleepAction.h"


@implementation SleepAction

- (id)init
{
    if (!(self = [super init]))
        return nil;

    setting = [[NSString alloc] init];

    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict
{
    if (!(self = [super initWithDictionary:dict]))
        return nil;

    setting = [[dict valueForKey:@"parameter"] copy];

    return self;
}

- (void)dealloc
{
    [setting release];

    [super dealloc];
}

- (NSMutableDictionary *)dictionary
{
    NSMutableDictionary *dict = [super dictionary];

    [dict setObject:[[setting copy] autorelease] forKey:@"parameter"];

    return dict;
}

- (NSString *)description
{
    NSArray *split = [setting componentsSeparatedByString:@" "];
	int t = [[split objectAtIndex:1] intValue];
    NSString *action = @"unknown";

    if ([[split objectAtIndex:0] compare:@"comp"] == NSOrderedSame)
        action = @"computer";
    else if ([[split objectAtIndex:0] compare:@"disp"] == NSOrderedSame)
        action = @"display";
    else if ([[split objectAtIndex:0] compare:@"disk"] == NSOrderedSame)
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

+ (NSString *)helpText
{
    return NSLocalizedString(@"The parameter for Sleep actions is the "
           "name of the setting followed by the number of minutes to wait before sleeping", @"");
}

+ (NSString *)creationHelpText
{
    return NSLocalizedString(@"Set the following sleep setting to:", @"");
}

- (void)checkPerms
{
    if (! [self executeAppleScript:@"do shell script \"/bin/ls -l /usr/bin/pmset | awk '{if (substr($1, 4, 1) == \\\"s\\\") exit 0; else exit 1;}'\""])
    {
        [self executeAppleScript:@"do shell script \"chmod +s /usr/bin/pmset\" with administrator privileges"];
    }
}

- (BOOL)execute:(NSString **)errorString
{
    NSString *cmd = nil;
    NSArray *split = [setting componentsSeparatedByString:@" "];

    if ([[split objectAtIndex:0] compare:@"comp"] == NSOrderedSame)
        cmd = [NSString stringWithFormat:@"sleep %@", [split objectAtIndex:1]];
    else if ([[split objectAtIndex:0] compare:@"disp"] == NSOrderedSame)
        cmd = [NSString stringWithFormat:@"displaysleep %@",
                        [split objectAtIndex:1]];
    else if ([[split objectAtIndex:0] compare:@"disk"] == NSOrderedSame)
        cmd = [NSString stringWithFormat:@"disksleep %@",
                        [split objectAtIndex:1]];
    else
    {
        *errorString = [[NSString stringWithFormat:
                                      NSLocalizedString(@"Invalid option: %@",
                                                        @""), setting]
                           retain];
        return NO;
    }

    [self checkPerms];

	NSString *script = [NSString stringWithFormat:
        @"do shell script \"/usr/bin/pmset %@\"", cmd];
    if (! [self executeAppleScript:script])
    {
        *errorString = [NSString stringWithFormat:
                           NSLocalizedString(@"Couldn't set '%@'!", @""),
                                  setting];
        return NO;
    }

    return YES;
}

+ (NSArray *)limitedOptions
{
	NSArray* opts = [NSArray arrayWithObjects:@"3", @"5", @"15", @"30", @"60", @"120", @"0", nil];
    NSArray* short_names = [NSArray arrayWithObjects:@"comp", @"disp", @"disk", nil];
    NSArray* names = [NSArray arrayWithObjects:@"Computer sleep", @"Display sleep", @"Disk sleep", nil];
	NSMutableArray *arr = [NSMutableArray 
                              arrayWithCapacity:[opts count] * [names count]];

    int i, j;
	for (i = 0; i < [names count]; ++i)
    {
        for (j = 0; j < [opts count]; ++j)
        {
            NSString *option = [NSString stringWithFormat:@"%@ %@",
                                         [short_names objectAtIndex:i], 
                                         [opts objectAtIndex:j]];
            NSString *description;

            if ([[opts objectAtIndex:j] compare:@"0"] == NSOrderedSame)
                description = [NSString stringWithFormat:NSLocalizedString(@"%@ never", @""), [names objectAtIndex:i]];
            else if ([[opts objectAtIndex:j] compare:@"1"] == NSOrderedSame)
                description = [NSString stringWithFormat:NSLocalizedString(@"%@ 1 minute", @""), [names objectAtIndex:i]];
            else
                description = [NSString stringWithFormat:NSLocalizedString(@"%@ %@ minutes", @""), [names objectAtIndex:i], [opts objectAtIndex:j]];

            [arr addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                             option, @"option",
                                         description, @"description", nil]];
        }
	}

    return arr;
}

- (id)initWithOption:(NSString *)option
{
    [self init];
    [setting autorelease];
    setting = [option copy];
    return self;
}

@end
