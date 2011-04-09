//
//  CardViewController.h
//  Kupo
//
//  Created by Peter Shih on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PSViewController.h"
#import "CardStateMachine.h"
#import "UINavigationBar+Custom.h"
#import "PSDataCenterDelegate.h"

@interface CardViewController : PSViewController <CardStateMachine, PSDataCenterDelegate, UINavigationControllerDelegate> {
  UIScrollView *_activeScrollView; // subclasses should set this if they have a scrollView
  UILabel *_navTitleLabel;
  
  UIImageView *_emptyView;
}

- (void)clearCachedData;
- (void)unloadCardController;
- (void)reloadCardController;
- (void)resetCardController;
- (void)dataSourceDidLoad;
- (void)setupLoadingAndEmptyViews;
- (void)addBackButton;

@end