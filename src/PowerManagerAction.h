//
//  PowerManagerAction.h
//  MarcoPolo
//
//  Created by James Newton on 11/23/07.
//

#import <Cocoa/Cocoa.h>
#import "Action.h"


@interface PowerManagerAction : Action <ActionWithLimitedOptions> {
    NSString* setting;
}

- (id)initWithDictionary:(NSDictionary *)dict;
- (void)dealloc;
- (NSMutableDictionary *)dictionary;

- (NSString *)description;
- (BOOL)execute:(NSString **)errorString;
+ (NSString *)helpText;
+ (NSString *)creationHelpText;

+ (NSArray *)limitedOptions;
- (id)initWithOption:(NSString *)option;
- (void)checkPerms;

@end
