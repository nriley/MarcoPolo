//
//  PowerManagerAction.m
//  MarcoPolo
//
//  Created by James Newton on 11/23/07.
//

#import "PowerManagerAction.h"


@interface PowerManagerAction (Private)

- (BOOL)isEnableSetting;
- (NSString *)strippedSetting;

@end

@implementation PowerManagerAction

static NSMutableArray *pma_opts = nil;

+ (void)initialize
{
    pma_opts = [NSMutableArray arrayWithCapacity:20];
    [pma_opts retain];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"cpuauto", @"option", NSLocalizedString(@"Processor speed: Automatic",
     @""), @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"cpuhighest", @"option", NSLocalizedString(@"Processor speed: Highest",
     @""), @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"cpureduced", @"option", NSLocalizedString(@"Processor speed: Reduced",
     @""), @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+womp", @"option", NSLocalizedString(@"Enable wake up on ethernet", @""),
     @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-womp", @"option", NSLocalizedString(@"Disable wake up on ethernet", @""),
     @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+ring", @"option", NSLocalizedString(@"Enable wake up on modem ring", @""),
     @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-ring", @"option", NSLocalizedString(@"Disable wake up on modem ring",
                                            @""), @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+lidwake", @"option",
     NSLocalizedString(@"Enable wake up on lid open", @""),
     @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-lidwake", @"option",
     NSLocalizedString(@"Disable wake up on lid open", @""), 
    @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+acwake", @"option",
     NSLocalizedString(@"Enable wake up when AC is plugged in", @""),
     @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-acwake", @"option",
     NSLocalizedString(@"Disable wake up when AC is plugged in", @""),
     @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+autorestart", @"option",
     NSLocalizedString(@"Enable restart on power loss", @""),
     @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-autorestart", @"option",
     NSLocalizedString(@"Disable restart on power loss", @""),
     @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+powerbutton", @"option",
     NSLocalizedString(@"Enable put machine to sleep on power button press",
                       @""), @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-powerbutton", @"option",
     NSLocalizedString(@"Disable put machine to sleep on power button press",
                       @""), @"description", nil]];

    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"+halfdim", @"option",
     NSLocalizedString(@"Enable intermediate half-brightness on display sleep",
                       @""), @"description", nil]];
    [pma_opts addObject:[NSDictionary dictionaryWithObjectsAndKeys:
     @"-halfdim", @"option",
     NSLocalizedString(@"Disable intermediate half-brightness on display sleep",
                       @""), @"description", nil]];
}

- (BOOL)isEnableSetting
{
    return ([setting characterAtIndex:0] == '+');
}

- (NSString *)strippedSetting
{
    if (([setting characterAtIndex:0] == '+') ||
        ([setting characterAtIndex:0] == '-'))
        return [setting substringFromIndex:1];
    else
        return setting;
}

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
    NSString *name = [self strippedSetting];

    if ([name compare:@"cpuauto"] == NSOrderedSame)
        return [[pma_opts objectAtIndex:0] objectForKey:@"description"];
    else if ([name compare:@"cpuhighest"] == NSOrderedSame)
        return [[pma_opts objectAtIndex:1] objectForKey:@"description"];
    else if ([name compare:@"cpureduced"] == NSOrderedSame)
        return [[pma_opts objectAtIndex:2] objectForKey:@"description"];
    else if ([self isEnableSetting])
        return [NSString stringWithFormat:
                             NSLocalizedString(@"Enabling: %@.", @""), name];
    else
        return [NSString stringWithFormat:
                             NSLocalizedString(@"Disabling: %@.", @""), name];
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
    // Strip off the first character which indicates either enabled or disabled
    NSString *name = [self strippedSetting];
    NSString *cmd = nil;

    if ([name compare:@"cpuauto"] == NSOrderedSame)
        cmd = @"reduce 0 dps 1";
    else if ([name compare:@"cpuhighest"] == NSOrderedSame)
        cmd = @"reduce 0 dps 0";
    else if ([name compare:@"cpureduced"] == NSOrderedSame)
        cmd = @"reduce 1 dps 0";
    else
    {
        long val = 0;
        if ([self isEnableSetting])
            val = 1;
        cmd = [NSString stringWithFormat:@"%@ %d", name, val];
    }

    [self checkPerms];

	NSString *script = [NSString stringWithFormat:
        @"do shell script \"/usr/bin/pmset %@\"", cmd];
    if (! [self executeAppleScript:script])
    {
        *errorString = [NSString stringWithFormat:
                        NSLocalizedString(@"Couldn't set '%@'!", @""),
                                 name];
        return NO;
    }

    return YES;
}

+ (NSString *)helpText
{
    return NSLocalizedString(@"The parameter for PowerManager actions is the "
           "name of the setting, prefixed with '+' or '-' to enable or disable "
           "it, respectively.", @"");
}

+ (NSString *)creationHelpText
{
    return NSLocalizedString(@"Set the following power setting to:", @"");
}

+ (NSArray *)limitedOptions
{
    return pma_opts;
}

- (id)initWithOption:(NSString *)option
{
    [self init];
    [setting autorelease];
    setting = [option copy];
    return self;
}

@end
