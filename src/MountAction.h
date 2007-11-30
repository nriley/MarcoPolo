//
//  MountAction.h
//  MarcoPolo
//
//  Created by David Symonds on 9/06/07.
//

#import <Cocoa/Cocoa.h>
#import "StringAction.h"


@interface MountAction : StringAction {
}

- (NSString *)leadText;
- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

@end
