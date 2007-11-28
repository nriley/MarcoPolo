//
//  VPNAction.h
//  MarcoPolo
//
//  Created by Mark Wallis on 18/07/07.
//

#import <Cocoa/Cocoa.h>
#import "GenericAction.h"


@interface VPNAction : GenericAction {
}

- (NSString *)descriptionOf:(NSDictionary *)actionDict;
- (BOOL)execute:(NSDictionary *)actionDict error:(NSString **)errorString;

- (NSString *)suggestionLeadText;
- (NSArray *)suggestions;

@end
