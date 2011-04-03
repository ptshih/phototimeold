//
//  KupoViewController.h
//  Moogle
//
//  Created by Peter Shih on 3/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCoreDataTableViewController.h"

@class KupoDataCenter;
@class Place;

@interface KupoViewController : CardCoreDataTableViewController {
  KupoDataCenter *_kupoDataCenter;
  Place *_place;
}

@property (nonatomic, retain) Place *place;

// Private
- (void)composeKupo;

@end