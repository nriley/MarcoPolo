//
//  MountAction.h
//  MarcoPolo
//
//  Created by David Symonds on 9/06/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithString.h"


@interface MountAction : ActionWithString {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
