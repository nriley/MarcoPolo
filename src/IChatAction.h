//
//  IChatAction.h
//  MarcoPolo
//
//  Created by David Symonds on 8/06/07.
//

#import <Cocoa/Cocoa.h>
#import "StringAction.h"


@interface IChatAction : StringAction {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
