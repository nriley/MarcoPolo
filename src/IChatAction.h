//
//  IChatAction.h
//  MarcoPolo
//
//  Created by David Symonds on 8/06/07.
//

#import <Cocoa/Cocoa.h>
#import "ActionWithString.h"


@interface IChatAction : ActionWithString {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
