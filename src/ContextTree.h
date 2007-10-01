//
//  ContextTree.h
//  MarcoPolo
//
//  Created by David Symonds on 3/07/07.
//

#import <Cocoa/Cocoa.h>


@interface Context : NSObject {
	NSString *uuid;
	NSString *parent;	// UUID
	NSString *name;

	// Transient
	NSNumber *depth;
	NSString *confidence;
	NSIndexPath *indexPath;
}

- (id)init;
- (id)initWithDictionary:(NSDictionary *)dict;

- (BOOL)isRoot;
- (NSDictionary *)dictionary;
- (NSComparisonResult)compare:(Context *)ctxt;

- (NSString *)uuid;
- (NSString *)parentUUID;
- (void)setParentUUID:(NSString *)parentUUID;
- (NSString *)name;
- (void)setName:(NSString *)newName;
- (NSString *)confidence;
- (void)setConfidence:(NSString *)newConfidence;

- (NSIndexPath *)indexPath;

@end


@interface ContextTree : NSObject {
	NSMutableDictionary *contexts;
}

+ (ContextTree *)sharedInstance;

- (void)registerForDragAndDrop:(NSOutlineView *)olv;

- (void)loadContexts;
- (void)saveContexts:(id)arg;
- (Context *)newContextWithName:(NSString *)name parentUUID:(NSString *)parentUUID;
- (void)removeContextRecursively:(NSString *)uuid;

- (Context *)contextByUUID:(NSString *)uuid;
- (Context *)contextByIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)arrayOfUUIDs;
- (NSArray *)orderedTraversal;
- (NSArray *)orderedTraversalRootedAt:(NSString *)uuid;
- (NSArray *)walkFrom:(NSString *)src_uuid to:(NSString *)dst_uuid;
- (NSString *)pathFromRootTo:(NSString *)uuid;
- (NSMenu *)hierarchicalMenu;

@end
