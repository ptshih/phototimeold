//
//  ComposeDataCenter.h
//  Scrapboard
//
//  Created by Peter Shih on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PSDataCenter.h"

@interface ComposeDataCenter : PSDataCenter {

}

// Create a new snap
- (void)sendSnapWithAlbumId:(NSString *)albumId andMessage:(NSString *)message andPhoto:(UIImage *)photo shouldShare:(BOOL)shouldShare;

@end
