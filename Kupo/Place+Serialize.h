//
//  Place+Serialize.h
//  Kupo
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Place.h"

@interface Place (Serialize)

+ (Place *)addPlaceWithDictionary:(NSDictionary *)dictionary inContext:(NSManagedObjectContext *)context;

- (Place *)updatePlaceWithDictionary:(NSDictionary *)dictionary;

@end